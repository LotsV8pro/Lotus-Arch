pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    function _log(...args): void {
        if (Quickshell.env("QS_DEBUG") === "1") console.log(...args);
    }

    property string filePath: Directories.eventsPath
    property var list: []
    property int nextId: 1
    
    signal eventAdded(var event)
    signal eventRemoved(int id)
    signal eventUpdated(var event)
    signal eventTriggered(var event)

    Component.onCompleted: {
        loadFromFile()
        checkTimer.start()
    }

    FileView {
        id: eventsFileView
        path: Qt.resolvedUrl(root.filePath)
        watchChanges: true
        onLoaded: {
            const fileContents = eventsFileView.text()
            if (!fileContents || fileContents.trim() === "") {
                root.list = []
                root.nextId = 1
                return
            }
            try {
                const data = JSON.parse(fileContents)
                root.list = data.events || []
                root.nextId = data.nextId || 1
                _log("[Events] Loaded", root.list.length, "events")
            } catch (e) {
                console.warn("[Events] Failed to parse file:", e)
                root.list = []
                root.nextId = 1
            }
        }
        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound) {
                console.log("[Events] File not found, creating new file.")
                const parentDir = root.filePath.substring(0, root.filePath.lastIndexOf('/'))
                Quickshell.execDetached(["/usr/bin/mkdir", "-p", parentDir])
                root.list = []
                root.nextId = 1
                root.saveToFile()
            } else {
                console.log("[Events] Error loading file:", error)
                root.list = []
                root.nextId = 1
            }
        }
    }

    // ═══ Google Calendar mirror (create/update/delete via gcal-op.py) ═══
    readonly property string googleOpScript: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/inir-birthdays/gcal-op.py"
    property var _googlePendingEvent: null
    property var _googlePendingCallback: null
    property var _googlePendingDeleteId: ""
    property var _googlePendingDeleteCallback: null

    Process {
        id: googleOpProc
        running: false
        stdout: SplitParser {
            splitMarker: ""
            onRead: (data) => {
                googleOpProc._rawOut += data
            }
        }
        property string _rawOut: ""
        onRunningChanged: { if (running) _rawOut = "" }
        onExited: (code, status) => {
            const raw = googleOpProc._rawOut.trim()
            let result = null
            const lines = raw.split("\n")
            for (let i = lines.length - 1; i >= 0; i--) {
                try { result = JSON.parse(lines[i]); break } catch (e) { /* skip */ }
            }
            if (code === 0 && result && result.ok) {
                const event = root._googlePendingEvent
                if (event && !root._googlePendingDeleteId) {
                    if (event.googleEventId) {
                        root.updateEvent(event.id, { googleSynced: true })
                    } else if (result.id) {
                        root.updateEvent(event.id, { googleEventId: result.id, googleSynced: true })
                    }
                }
                if (root._googlePendingDeleteCallback) {
                    root._googlePendingDeleteCallback(true)
                }
                if (root._googlePendingCallback) {
                    root._googlePendingCallback(true, result.id, result.htmlLink)
                }
            } else {
                const err = result?.error || raw || `exit ${code}`
                console.warn("[Events] Google sync failed:", err)
                Quickshell.execDetached([
                    "/usr/bin/notify-send",
                    "-h", "int:transient:1",
                    "-a", "Quickshell ii",
                    "-i", "event_busy",
                    "Google Calendar sync failed",
                    `${root._googlePendingEvent?.title ?? "Event"} not synced: ${err}`
                ])
                const event = root._googlePendingEvent
                if (event) root.updateEvent(event.id, { googleSynced: false })
                if (root._googlePendingDeleteCallback) {
                    root._googlePendingDeleteCallback(false)
                }
                if (root._googlePendingCallback) {
                    root._googlePendingCallback(false, "", "", err)
                }
            }
            root._googlePendingEvent = null
            root._googlePendingCallback = null
            root._googlePendingDeleteId = ""
            root._googlePendingDeleteCallback = null
        }
    }

    function _localDateTimeString(iso) {
        const d = iso ? new Date(iso) : new Date()
        const p = (n) => String(n).padStart(2, "0")
        return d.getFullYear() + "-" + p(d.getMonth() + 1) + "-" + p(d.getDate()) +
            "T" + p(d.getHours()) + ":" + p(d.getMinutes()) + ":" + p(d.getSeconds())
    }

    // ═══ Contact search for birthday picker ═══
    property var contactSearchResults: []
    property bool contactSearchRunning: false
    property string _contactSearchQuery: ""

    Process {
        id: contactSearchProc
        running: false
        stdout: SplitParser {
            splitMarker: ""
            onRead: (data) => { contactSearchProc._rawOut += data }
        }
        property string _rawOut: ""
        onRunningChanged: { if (running) _rawOut = "" }
        onExited: (code, status) => {
            root.contactSearchRunning = false
            const raw = contactSearchProc._rawOut.trim()
            let result = null
            const lines = raw.split("\n")
            for (let i = lines.length - 1; i >= 0; i--) {
                try { result = JSON.parse(lines[i]); break } catch (e) { /* skip */ }
            }
            if (code === 0 && result && result.ok) {
                root.contactSearchResults = result.results || []
            } else {
                root.contactSearchResults = []
            }
        }
    }

    function searchContacts(query) {
        root._contactSearchQuery = query
        if (!query || query.length < 2) {
            root.contactSearchResults = []
            return
        }
        root.contactSearchRunning = true
        contactSearchProc.command = ["/usr/bin/python3", root.googleOpScript,
            "search", query]
        contactSearchProc.running = true
    }

    // Push a local event to Google. New events (no googleEventId) are created;
    // already-synced ones are updated. Offline/error leaves the local copy intact.
    function pushToGoogle(event, callback, contactId) {
        if (!event) return
        if (event.googleEventId) {
            root._googlePendingDeleteId = ""
            root._googlePendingEvent = event
            root._googlePendingCallback = callback || null
            const payload = JSON.stringify({
                summary: event.title || "",
                description: event.description || "",
                dateTime: root._localDateTimeString(event.dateTime),
                allDay: !!event.allDay,
                priority: event.priority || "normal",
                reminderMinutes: event.reminderMinutes ?? 15,
                recurrence: event.recurrence || "none",
                category: event.category || "general"
            })
            googleOpProc.command = ["/usr/bin/python3", root.googleOpScript,
                "update", event.googleEventId, payload]
            googleOpProc.running = true
        } else {
            root.createInGoogle(event, callback, contactId)
        }
    }

    // Create the Google mirror for a local event without one yet.
    function createInGoogle(event, callback, contactId) {
        root._googlePendingDeleteId = ""
        root._googlePendingEvent = event
        root._googlePendingCallback = callback || null
        const payload = JSON.stringify({
            summary: event.title || "",
            description: event.description || "",
            dateTime: root._localDateTimeString(event.dateTime),
            allDay: !!event.allDay,
            priority: event.priority || "normal",
            reminderMinutes: event.reminderMinutes ?? 15,
            recurrence: event.recurrence || "none",
            category: event.category || "general",
            contactId: contactId || ""
        })
        googleOpProc.command = ["/usr/bin/python3", root.googleOpScript,
            "create", payload]
        googleOpProc.running = true
    }

    // Remove the Google mirror for a local event that had one.
    function deleteFromGoogle(googleEventId, callback) {
        root._googlePendingEvent = null
        root._googlePendingDeleteId = googleEventId
        root._googlePendingDeleteCallback = callback || null
        googleOpProc.command = ["/usr/bin/python3", root.googleOpScript,
            "delete", googleEventId]
        googleOpProc.running = true
    }

    // Check for due events every minute
    Timer {
        id: checkTimer
        interval: 60000 // 1 minute
        running: false
        repeat: true
        onTriggered: root.checkDueEvents()
    }

    signal reminderTriggered(var event, int minutesBefore)

    function checkDueEvents() {
        const now = new Date()
        const currentTime = now.getTime()
        let needsSave = false
        
        for (let i = 0; i < root.list.length; i++) {
            const event = root.list[i]
            if (!event.dateTime) continue
            
            const eventTime = new Date(event.dateTime).getTime()
            const reminderMinutes = event.reminderMinutes ?? 0
            const reminderTime = eventTime - (reminderMinutes * 60 * 1000)
            
            // Check for reminder notification (before event)
            if (reminderMinutes > 0 && !event.reminderNotified && currentTime >= reminderTime && currentTime < eventTime) {
                root.list[i].reminderNotified = true
                root.reminderTriggered(event, reminderMinutes)
                needsSave = true
            }
            
            // Check for event time notification
            if (!event.notified && currentTime >= eventTime) {
                root.list[i].notified = true
                root.eventTriggered(event)
                needsSave = true
                
                // Handle recurrence - create next occurrence
                if (event.recurrence && event.recurrence !== "none") {
                    root.createNextRecurrence(event)
                }
            }
        }
        
        if (needsSave) root.saveToFile()
    }

    function createNextRecurrence(event) {
        const eventDate = new Date(event.dateTime)
        let nextDate = new Date(eventDate)
        
        switch (event.recurrence) {
            case "daily":
                nextDate.setDate(nextDate.getDate() + 1)
                break
            case "weekly":
                nextDate.setDate(nextDate.getDate() + 7)
                break
            case "monthly":
                nextDate.setMonth(nextDate.getMonth() + 1)
                break
            case "yearly":
                nextDate.setFullYear(nextDate.getFullYear() + 1)
                break
            default:
                return
        }
        
        // Create recurring event. The copy is local-only: the whole Google series is
        // one RRULE event owned by the base entry, so it must not be pushed to
        // Google individually (would duplicate the recurring series).
        const baseId = event.recurrenceOf || event.id
        const nextEvent = root.addEvent(
            event.title,
            event.description,
            nextDate.toISOString(),
            event.category,
            event.priority,
            event.reminderMinutes,
            event.recurrence
        )
        root.updateEvent(nextEvent.id, { recurrenceOf: baseId })
        return nextEvent
    }

    function addEvent(title, description, dateTime, category, priority, reminderMinutes, recurrence, allDay, contactName) {
        const event = {
            id: root.nextId++,
            title: title || "",
            description: description || "",
            dateTime: dateTime || new Date().toISOString(),
            allDay: !!allDay,
            category: category || "general", // general, birthday, meeting, deadline, reminder
            priority: priority || "normal", // low, normal, high
            reminderMinutes: reminderMinutes ?? 15, // 0, 5, 15, 30, 60, 1440
            recurrence: recurrence || "none", // none, daily, weekly, monthly, yearly
            contactName: contactName || "",
            notified: false,
            reminderNotified: false,
            createdAt: new Date().toISOString()
        }
        
        root.list.push(event)
        root.list = root.list // Trigger binding update
        root.eventAdded(event)
        root.saveToFile()
        return event
    }

    function removeEvent(id) {
        const index = root.list.findIndex(e => e.id === id)
        if (index !== -1) {
            root.list.splice(index, 1)
            root.list = root.list
            root.eventRemoved(id)
            root.saveToFile()
            return true
        }
        return false
    }

    function updateEvent(id, updates) {
        const index = root.list.findIndex(e => e.id === id)
        if (index !== -1) {
            root.list[index] = Object.assign({}, root.list[index], updates)
            root.list = root.list
            root.eventUpdated(root.list[index])
            root.saveToFile()
            return true
        }
        return false
    }

    function getEventsForDate(date) {
        const targetDate = new Date(date)
        targetDate.setHours(0, 0, 0, 0)
        
        return root.list.filter(event => {
            const eventDate = new Date(event.dateTime)
            eventDate.setHours(0, 0, 0, 0)
            // Only show non-notified events (upcoming or future)
            return eventDate.getTime() === targetDate.getTime() && !event.notified
        })
    }
    
    // Get ALL events for a date (including notified/past) - for history view
    function getAllEventsForDate(date) {
        const targetDate = new Date(date)
        targetDate.setHours(0, 0, 0, 0)
        
        return root.list.filter(event => {
            const eventDate = new Date(event.dateTime)
            eventDate.setHours(0, 0, 0, 0)
            return eventDate.getTime() === targetDate.getTime()
        })
    }

    function getUpcomingEvents(days) {
        const now = new Date()
        const future = new Date()
        future.setDate(future.getDate() + (days || 7))
        
        return root.list.filter(event => {
            const eventDate = new Date(event.dateTime)
            return eventDate >= now && eventDate <= future && !event.notified
        }).sort((a, b) => new Date(a.dateTime) - new Date(b.dateTime))
    }

    // Remove external (Google CalendarSync) events that are already represented
    // by a locally-synced event (one with a googleEventId). Useful because a
    // born/linked contact birthday shows up both as a local event and as an
    // external ICS event ("<Name> - Cumpleaños"). Names are matched by the real
    // contact name (contactName) or, as a fallback, by the local title, and only
    // when day+month also match, so an arbitrary local title can't break it.
    function filterExternalDuplicates(localEvents, externalEvents): var {
        const norm = s => (s || "").replace(/[^0-9a-z]+/gi, " ").trim().toLowerCase()
        const FOLD = { "á": "a", "é": "e", "í": "i", "ó": "o", "ú": "u", "ü": "u", "ñ": "n" }
        const fold = s => (s || "").toLowerCase().split("").map(c => FOLD[c] || c).join("")
        const STOPW = ["cumpleanos", "birthday", "cumple", "de", "del", "la", "las", "los", "el"]
        const ptokens = s => fold(s || "").replace(/[^a-z ]+/g, " ").trim().split(/\s+/).filter(w => w && !STOPW.includes(w)).sort().join(" ")
        const dayKey = d => {
            const dt = new Date(d)
            return `${dt.getFullYear()}-${dt.getMonth()}-${dt.getDate()}`
        }
        const mdKey = d => {
            const dt = new Date(d)
            return `${dt.getMonth()}-${dt.getDate()}`
        }
        const isBirthdayTitle = s => /cumple|birthday|birth/i.test(s || "")

        const syncedLocalKeys = new Set()
        const syncedBirthdayKeys = new Set()
        for (const l of localEvents) {
            if (!l.googleEventId) continue
            syncedLocalKeys.add(`${dayKey(l.dateTime)}::${norm(l.title)}`)
            if (l.category === "birthday" || isBirthdayTitle(l.title)) {
                const who = l.contactName || l.title
                syncedBirthdayKeys.add(`${mdKey(l.dateTime)}::${ptokens(who)}`)
            }
        }
        return (externalEvents || []).filter(e => {
            const extStart = e.startDate || e.dateTime
            if (syncedLocalKeys.has(`${dayKey(extStart)}::${norm(e.summary || e.title)}`)) return false
            if (isBirthdayTitle(e.summary || e.title)
                    && syncedBirthdayKeys.has(`${mdKey(extStart)}::${ptokens(e.summary || e.title)}`)) {
                return false
            }
            return true
        })
    }

    function markAsNotified(id) {
        return root.updateEvent(id, { notified: true })
    }

    function saveToFile() {
        const data = {
            nextId: root.nextId,
            events: root.list
        }
        eventsFileView.setText(JSON.stringify(data, null, 2))
    }

    function loadFromFile() {
        eventsFileView.reload()
    }

    function getCategoryIcon(category) {
        switch (category) {
            case "birthday": return "cake"
            case "meeting": return "groups"
            case "deadline": return "flag"
            case "reminder": return "notifications"
            default: return "event"
        }
    }

    // getPriorityColor removed — was dead code with hardcoded colors.
    // EventCard already resolves priority colors via Appearance tokens.
}
