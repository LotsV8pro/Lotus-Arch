pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.services
import "calendar_ics.js" as IcsParser

// External calendar sync via ICS/iCal URLs.
// Fetches calendars periodically, parses ICS to JSON, and caches results.
// Zero external deps — uses curl for fetching and JS for parsing.
Singleton {
    id: root

    readonly property bool enabled: Config.options?.calendar?.externalSync?.enable ?? false
    readonly property var sources: Config.options?.calendar?.externalSync?.sources ?? []
    readonly property int fetchIntervalMs: (Config.options?.calendar?.externalSync?.refreshMinutes ?? 15) * 60 * 1000

    // All external events, merged from every enabled source
    property var events: []
    // Per-source metadata (id, name, color, lastFetch, eventCount, error)
    property var sourceStatuses: ({})
    property bool fetching: false
    property bool ready: false

    signal eventsUpdated()
    signal fetchStarted()
    signal fetchFinished(bool success)
    signal sourceError(string sourceId, string error)

    // Cache file for persisting between sessions
    readonly property string cachePath: Directories.calendarSyncCachePath

    Component.onCompleted: {
        if (!root.enabled) {
            root.ready = true
            return
        }
        loadCache()
        if (root.sources.length > 0) {
            Qt.callLater(() => root.fetchAll())
        }
        if (root.googleClientId.length > 0)
            Qt.callLater(() => root.checkGoogleToken())
    }

    // React to config changes — re-fetch when sources change
    property string _lastSourcesHash: ""
    onSourcesChanged: {
        const hash = JSON.stringify(root.sources)
        if (hash !== root._lastSourcesHash) {
            root._lastSourcesHash = hash
            if (root.enabled) {
                Qt.callLater(() => root.fetchAll())
            }
        }
    }

    onEnabledChanged: {
        if (root.enabled && root.sources.length > 0) {
            Qt.callLater(() => root.fetchAll())
        }
    }

    // Periodic refresh
    Timer {
        id: fetchTimer
        running: root.enabled && Config.ready && root.sources.length > 0
        repeat: true
        interval: root.fetchIntervalMs
        onTriggered: root.fetchAll()
    }

    // Sequential source fetcher — fetches one source at a time to avoid
    // spawning many curl processes simultaneously
    property int _fetchIndex: -1
    property var _pendingSources: []
    property var _fetchedEvents: []

    function fetchAll(): void {
        if (root.fetching) return
        const enabledSources = root.sources.filter(s => s.enabled && s.url && s.url.trim() !== "")
        if (enabledSources.length === 0) {
            root.events = []
            root.ready = true
            root.eventsUpdated()
            return
        }

        root.fetching = true
        root._pendingSources = enabledSources
        root._fetchedEvents = []
        root._fetchIndex = 0
        root.fetchStarted()
        _log("Fetching", enabledSources.length, "calendar sources")
        _fetchNext()
    }

    function _fetchNext(): void {
        if (root._fetchIndex >= root._pendingSources.length) {
            // All done
            root.events = root._fetchedEvents
            root.fetching = false
            root.ready = true
            root.eventsUpdated()
            root.fetchFinished(true)
            root.saveCache()
            _log("Fetch complete:", root.events.length, "events from", root._pendingSources.length, "sources")
            return
        }

        const source = root._pendingSources[root._fetchIndex]
        _log("Fetching source:", source.name, "from", source.url)
        _currentFetchSource = source
        fetchProc.command = ["/usr/bin/curl", "-sL", "--max-time", "30",
            "--compressed", "-H", "Accept: text/calendar", source.url]
        fetchProc.running = true
    }

    property var _currentFetchSource: null

    Process {
        id: fetchProc
        running: false
        stdout: SplitParser {
            splitMarker: ""
            onRead: (data) => {
                // Accumulate raw ICS data
                fetchProc._rawData += data
            }
        }
        property string _rawData: ""

        onRunningChanged: {
            if (running) _rawData = ""
        }

        onExited: (code, status) => {
            const source = root._currentFetchSource
            if (!source) {
                root._fetchIndex++
                root._fetchNext()
                return
            }

            if (code !== 0 || fetchProc._rawData.trim() === "") {
                const errMsg = code !== 0 ? `curl exited with code ${code}` : "Empty response"
                _log("Error fetching", source.name, ":", errMsg)
                root._updateSourceStatus(source.id, { error: errMsg, lastFetch: new Date().toISOString() })
                root.sourceError(source.id, errMsg)
            } else {
                try {
                    const parsed = IcsParser.parseICS(fetchProc._rawData, source.id, source.name, source.color)
                    root._fetchedEvents = root._fetchedEvents.concat(parsed)
                    root._updateSourceStatus(source.id, {
                        error: "",
                        lastFetch: new Date().toISOString(),
                        eventCount: parsed.length
                    })
                    _log("Parsed", parsed.length, "events from", source.name)
                } catch (e) {
                    const errMsg = `Parse error: ${e.message}`
                    _log("Parse error for", source.name, ":", e.message)
                    root._updateSourceStatus(source.id, { error: errMsg, lastFetch: new Date().toISOString() })
                    root.sourceError(source.id, errMsg)
                }
            }

            root._fetchIndex++
            root._fetchNext()
        }
    }

    function _updateSourceStatus(sourceId: string, updates: var): void {
        const statuses = Object.assign({}, root.sourceStatuses)
        statuses[sourceId] = Object.assign(statuses[sourceId] || {}, updates)
        root.sourceStatuses = statuses
    }

    // Query: get external events for a specific date
    function getEventsForDate(date: var): var {
        const target = new Date(date)
        target.setHours(0, 0, 0, 0)
        const targetTime = target.getTime()

        return root.events.filter(event => {
            if (event.allDay) {
                const start = new Date(event.startDate)
                start.setHours(0, 0, 0, 0)
                const end = event.endDate ? new Date(event.endDate) : new Date(start)
                end.setHours(0, 0, 0, 0)
                return targetTime >= start.getTime() && targetTime < end.getTime()
            }
            const evtDate = new Date(event.startDate)
            evtDate.setHours(0, 0, 0, 0)
            return evtDate.getTime() === targetTime
        })
    }

    // Query: get all events in a date range (for upcoming view)
    function getUpcomingEvents(days: int): var {
        const now = new Date()
        const future = new Date()
        future.setDate(future.getDate() + (days || 7))

        return root.events.filter(event => {
            const evtDate = new Date(event.startDate)
            return evtDate >= now && evtDate <= future
        }).sort((a, b) => new Date(a.startDate) - new Date(b.startDate))
    }

    // Query: distinct source colors for events on a given date
    function getSourceColorsForDate(date: var): var {
        const dayEvents = getEventsForDate(date)
        const colors = []
        const seen = new Set()
        for (const evt of dayEvents) {
            if (!seen.has(evt.sourceId)) {
                seen.add(evt.sourceId)
                colors.push(evt.sourceColor)
            }
        }
        return colors
    }

    // ===== Event reminders =====
    // Maintains the sorts of alarms the freedesktop calendar world expects:
    // one 30 minutes before an event, one at its start. Also handles a
    // retroactive "about to start" reminder when the shell boots mid-window.
    readonly property int reminderAdvanceMinutes: Config.options?.calendar?.reminders?.advanceMinutes ?? 30
    readonly property int startupDelayMs: Config.options?.calendar?.reminders?.startupDelayMs ?? 30000
    readonly property int checkIntervalMs: Config.options?.calendar?.reminders?.checkIntervalMs ?? 10000
    readonly property int notifyTimeoutMs: Config.options?.calendar?.reminders?.notifyTimeoutMs ?? 8000
    readonly property bool remindersEnabled: Config.options?.calendar?.reminders?.enable
        ?? (Config.options?.calendar?.externalSync?.enable ?? false)

    // Persisted map of already-fired reminders so reboots don't re-notify.
    // Keys: `<uid>|<startIso>|advance|start`
    property var _firedReminders: ({})
    property var _remindersDirty: false
    property string _lastEventHash: ""

    // Per-session startup "today" notification state (re-notified every boot).
    property var _startupTodayFired: ({})
    property bool _startupTodayDone: false
    property bool _startupReminderRan: false

    readonly property string _remindersFile: Directories.stateUserPath + "/calendar_reminders.json"

    FileView {
        id: remindersFileView
        path: root._remindersFile
        watchChanges: false
        printErrors: false
        onLoaded: {
            try {
                const data = JSON.parse(remindersFileView.text())
                root._firedReminders = (data && data.fired) || {}
                _log("Loaded reminder state:", Object.keys(root._firedReminders).length, "entries")
            } catch (e) {
                _log("Reminder state parse error:", e.message)
            }
            _log("Reminder load complete")
        }
        onLoadFailed: (error) => {
            _log("No reminder state file, starting fresh")
        }
    }

    function _saveReminders(): void {
        remindersFileView.setText(JSON.stringify({ fired: root._firedReminders }))
    }

    function _reminderKey(event, kind): string {
        return event.uid + "|" + event.startDate + "|" + kind
    }

    function _reminderNotified(key): bool {
        return Object.prototype.hasOwnProperty.call(root._firedReminders, key)
    }

    function _markReminderNotified(key): void {
        if (root._reminderNotified(key)) return
        root._firedReminders[key] = "" // djb2 would be overkill; presence is enough
        root._remindersDirty = true
    }

    // Send helper. The notification server registers on the D-Bus tree lazily
    // after the shell boots; a notify-send fired in the first seconds fails
    // silently. Check the bus, and if the name isn't owned yet, defer the send
    // and retry every second until it is (or we give up).
    property var _notifyPending: []
    property bool _notifyCheckingBus: false
    property int _notifyMaxRetries: 30

    function _sendNotifyWithRetry(summary, body: string): void {
        root._notifyPending.push({ "summary": summary, "body": body, "tries": 0 })
        root._drainNotifyQueue()
    }

    function _drainNotifyQueue(): void {
        if (root._notifyCheckingBus) return
        const next = root._notifyPending[0]
        if (!next) return
        if (next.tries >= root._notifyMaxRetries) {
            _log("Give up sending notification after retries:", next.summary)
            root._notifyPending.shift()
            root._drainNotifyQueue()
            return
        }
        root._notifyCheckingBus = true
        busCheckProc.command = ["/usr/bin/busctl", "--user", "--list", "--no-pager"]
        busCheckProc.running = true
    }

    Process {
        id: busCheckProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                busCheckProc._busOutput = text
            }
        }
        property string _busOutput: ""

        onRunningChanged: {
            if (running) _busOutput = ""
        }

        onExited: (code, status) => {
            const ready = busCheckProc._busOutput.includes("org.freedesktop.Notifications")
            root._notifyCheckingBus = false
            if (!ready) {
                retryNotifyTimer.restart()
                return
            }
            const job = root._notifyPending.shift()
            if (!job) return
            Quickshell.execDetached([
                "/usr/bin/notify-send",
                "--app-name=Calendario",
                "-i", "x-office-calendar",
                "-h", "int:transient:1",
                "-t", String(root.notifyTimeoutMs),
                String(job.summary || "Evento").slice(0, 80),
                String(job.body || ""),
            ])
            root._drainNotifyQueue()
        }
    }

    Timer {
        id: retryNotifyTimer
        interval: 1000
        repeat: false
        onTriggered: {
            const job = root._notifyPending[0]
            if (job) job.tries++
            root._drainNotifyQueue()
        }
    }

    // Prune fired markers for events that ended more than 24h ago so the file
    // doesn't grow forever.
    function _pruneFiredReminders(): void {
        const cutoff = Date.now() - 24 * 60 * 60 * 1000
        const keys = Object.keys(root._firedReminders)
        let pruned = 0
        for (const key of keys) {
            const sep = key.lastIndexOf("|")
            if (sep === -1) continue
            const startIso = key.substring(0, sep)
            const startTime = new Date(startIso).getTime()
            // Keep unknown/parseable flags for at least a day window; drop
            // entries whose event started before the cutoff.
            if (!isNaN(startTime) && startTime + 60 * 60 * 1000 < cutoff) {
                delete root._firedReminders[key]
                pruned++
            }
        }
        if (pruned > 0) {
            root._remindersDirty = true
            _log("Pruned", pruned, "old reminder entries")
        }
    }

    function _sendReminderNotification(event, kind: string): void {
        const atTime = event.startDate
        const relTime = new Date(atTime)
        const isAdvance = kind === "advance"
        const summary = String(event.title || "Evento").slice(0, 80)

        const timeStr = relTime.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })
        const dayStr = relTime.toLocaleDateString([], { weekday: "long" })
        const when = isAdvance
            ? "Empieza a las " + timeStr + " (" + dayStr + ")"
            : "Empieza ahora · " + timeStr
        const loc = event.location && event.location.length > 0 ? " · " + event.location : ""
        const body = when + loc

        root._sendNotifyWithRetry(
            String(event.title || "Evento").slice(0, 80),
            body
        )
        _log("Sent", kind, "reminder for:", event.title, "@", atTime)
    }

    // An event is a "routine" if it repeats daily/weekly (Casa, Lectura,
    // Desayunar, Arch time, Estudiar, …). Those clutter the boot summary.
    property var _routineUids: ({})

    function _rebuildRoutineUids(): void {
        const uids = {}
        for (const event of root.events) {
            const rec = String(event.recurrence || "none")
            if (rec === "daily" || rec === "weekly") uids[event.uid] = true
        }
        root._routineUids = uids
    }

    function _isRoutineEvent(event): bool {
        // One-off override instances of a daily/weekly series keep the same
        // UID (e.g. a moved "Casa" today), so check both this occurrence's
        // recurrence and whether its series is a routine.
        const rec = String(event.recurrence || "none")
        if (rec === "daily" || rec === "weekly") return true
        return !!(root._routineUids[event.uid])
    }

    // Whether the event falls on the current local day. All-day entries
    // (festivos, cumpleaños) repeat yearly and their stored year is the
    // source's base year, so compare only month/day. Timed events compare
    // the full date.
    function _isTodayEvent(event): bool {
        const start = new Date(event.startDate)
        if (isNaN(start.getTime())) return false
        const now = new Date()
        if (event.allDay) {
            return start.getMonth() === now.getMonth() && start.getDate() === now.getDate()
        }
        return start.getFullYear() === now.getFullYear()
            && start.getMonth() === now.getMonth()
            && start.getDate() === now.getDate()
    }

    // Boot-summary notification: fires once at startup for every meaningful
    // (non-routine) event happening today. Marked in-memory only so each new
    // shell start re-notifies without spamming inside the same session.
    function _notifyTodayAtStartup(): void {
        if (!root.remindersEnabled || !root.ready) return
        if (root._startupTodayDone) return

        root._rebuildRoutineUids()

        const todayKey = new Date().toDateString()
        let notified = 0
        for (const event of root.events) {
            if (root._isRoutineEvent(event)) continue
            if (!root._isTodayEvent(event)) continue

            const evtDate = new Date(event.startDate)
            const key = event.uid + "|" + todayKey
            if (root._startupTodayFired[key]) continue
            root._startupTodayFired[key] = true

            const timeStr = event.allDay
                ? "Hoy"
                : "Hoy a las " + evtDate.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })
            const loc = event.location && event.location.length > 0 ? " · " + event.location : ""
            const body = timeStr + loc

root._sendNotifyWithRetry(
            String(event.title || "Evento").slice(0, 80),
            body
        )
        notified++
        _log("Today startup notification:", event.title, "@", event.startDate)
        }
        root._startupTodayDone = true
        if (notified > 0) _log("Sent", notified, "today startup notifications")
    }

    // One reminder pass: find events in the two windows and notify once.
    function _checkReminders(): void {
        if (!root.remindersEnabled || !root.ready) return
        root._pruneFiredReminders()

        const now = Date.now()
        const advanceMs = root.reminderAdvanceMinutes * 60 * 1000
        const nowKey = root.events.map((e) => {
            // Cheap identity that changes only when the parsed set changes.
            return e.uid + "|" + e.startDate + "|" + e.endDate
        }).sort().join("\n")

        // If the events set changed since last pass, retry any pending marks
        // immediately after the next fetch rather than waiting for the timer.
        const eventsChanged = root._lastEventHash.length > 0 && nowKey !== root._lastEventHash

        for (const event of root.events) {
            if (event.allDay) continue
            const startTime = new Date(event.startDate).getTime()
            if (isNaN(startTime)) continue

            // Advance window: [start - advance, start)
            const advanceKey = root._reminderKey(event, "advance")
            if (now >= startTime - advanceMs && now < startTime
                    && !root._reminderNotified(advanceKey)) {
                root._sendReminderNotification(event, "advance")
                root._markReminderNotified(advanceKey)
            }

            // Start window: [start, start + 2min) so boot-late events fire too
            const startKey = root._reminderKey(event, "start")
            if (now >= startTime && now < startTime + 2 * 60 * 1000
                    && !root._reminderNotified(startKey)) {
                root._sendReminderNotification(event, "start")
                root._markReminderNotified(startKey)
            }
        }

        if (root._remindersDirty) {
            root._remindersDirty = false
            root._saveReminders()
        }
        root._lastEventHash = nowKey
    }

    // Periodic check while the shell is up.
    Timer {
        id: reminderTimer
        running: root.remindersEnabled && Config.ready
        repeat: true
        interval: root.checkIntervalMs
        onTriggered: root._checkReminders()
    }

    // Boot-delayed pass: if the shell starts inside an event window, the
    // reminder shows a moment after everything is up (default 30s).
    Timer {
        id: startupReminderTimer
        running: root.remindersEnabled
        repeat: false
        interval: root.startupDelayMs
        onTriggered: {
            root._startupReminderRan = true
            root._checkReminders()
            root._notifyTodayAtStartup()
        }
    }

    // Re-check the "today" summary on the periodic refresh (after the 30s
    // boot delay has run, so it doesn't collide with the startup pass).
    onEventsUpdated: {
        if (root.ready && root.remindersEnabled && root._startupReminderRan) {
            root._notifyTodayAtStartup()
        }
    }

    // Source management (called from Settings UI)
    function addSource(name: string, url: string, color: string): void {
        const newSource = {
            id: _generateId(),
            name: name,
            url: url,
            color: color || _nextColor(),
            enabled: true
        }
        const updated = [...(Config.options?.calendar?.externalSync?.sources ?? []), newSource]
        Config.setNestedValue("calendar.externalSync.sources", updated)
    }

    function removeSource(sourceId: string): void {
        const updated = (Config.options?.calendar?.externalSync?.sources ?? []).filter(s => s.id !== sourceId)
        Config.setNestedValue("calendar.externalSync.sources", updated)
        // Clean cached events from this source
        root.events = root.events.filter(e => e.sourceId !== sourceId)
        root.eventsUpdated()
    }

    function updateSource(sourceId: string, updates: var): void {
        const sources = [...(Config.options?.calendar?.externalSync?.sources ?? [])]
        const idx = sources.findIndex(s => s.id === sourceId)
        if (idx !== -1) {
            sources[idx] = Object.assign({}, sources[idx], updates)
            Config.setNestedValue("calendar.externalSync.sources", sources)
        }
    }

    function toggleSource(sourceId: string, enabled: bool): void {
        updateSource(sourceId, { enabled: enabled })
        if (!enabled) {
            root.events = root.events.filter(e => e.sourceId !== sourceId)
            root.eventsUpdated()
        } else {
            Qt.callLater(() => root.fetchAll())
        }
    }

    // Force refresh a single source or all
    function refreshSource(sourceId: string): void {
        Qt.callLater(() => root.fetchAll())
    }

    function forceRefreshAll(): void {
        Qt.callLater(() => root.fetchAll())
    }

    // Cache persistence
    function saveCache(): void {
        const data = {
            events: root.events,
            sourceStatuses: root.sourceStatuses,
            savedAt: new Date().toISOString()
        }
        cacheFileView.setText(JSON.stringify(data))
    }

    function loadCache(): void {
        cacheFileView.reload()
    }

    FileView {
        id: cacheFileView
        path: root.cachePath
        watchChanges: false
        printErrors: false
        onLoaded: {
            const content = cacheFileView.text()
            if (!content || content.trim() === "") {
                root.ready = true
                return
            }
            try {
                const data = JSON.parse(content)
                root.events = data.events || []
                root.sourceStatuses = data.sourceStatuses || {}
                root.ready = true
                _log("Loaded cache:", root.events.length, "events")
            } catch (e) {
                _log("Cache parse error:", e.message)
                root.ready = true
            }
        }
        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound) {
                _log("No cache file, starting fresh")
            }
            root.ready = true
        }
    }

    // Preset colors for calendar sources
    readonly property var presetColors: [
        "#4285F4", // Google Blue
        "#EA4335", // Google Red
        "#34A853", // Google Green
        "#FBBC05", // Google Yellow
        "#FF6D01", // Orange
        "#46BDC6", // Teal
        "#7986CB", // Indigo
        "#E67C73", // Flamingo
        "#F6BF26", // Banana
        "#33B679", // Sage
        "#8E24AA", // Grape
        "#D81B60", // Lavender
    ]

    property int _colorIndex: 0

    function _nextColor(): string {
        const color = root.presetColors[root._colorIndex % root.presetColors.length]
        root._colorIndex++
        return color
    }

    function _generateId(): string {
        return "cal_" + Date.now().toString(36) + "_" + Math.random().toString(36).substring(2, 6)
    }

    function _log(...args): void {
        if (Quickshell.env("QS_DEBUG") === "1")
            console.log("[CalendarSync]", ...args)
    }

    // ═══════════════════════════════════════════════════════════════════
    //  Google Calendar (OAuth device flow) — pull birthdays/contacts and
    //  push locally created events to the user's Google Calendar.
    // ═══════════════════════════════════════════════════════════════════

    readonly property string googleTokenPath: `${Directories.stateUserPath}/google_calendar_token.json`
    readonly property string googleScript: `${Directories.scriptsPath}/google_calendar.py`

    // OAuth configuration (from Settings, optional client secret)
    readonly property string googleClientId: Config.options?.calendar?.googleOAuth?.clientId ?? ""
    readonly property string googleClientSecret: Config.options?.calendar?.googleOAuth?.clientSecret ?? ""
    readonly property bool googlePushEnabled: Config.options?.calendar?.googleOAuth?.pushEnabled ?? false
    readonly property int googleImportDays: Config.options?.calendar?.googleOAuth?.importDays ?? 365

    // Runtime state
    property bool googleConnected: false
    property bool googleChecking: false
    property bool googleFetching: false
    property var googleAccount: ({})
    property int googleEventCount: 0
    property string googleError: ""

    // Device flow state
    property string googleVerificationUrl: ""
    property string googleUserCode: ""
    property var _googleDevice: null
    property bool _googlePolling: false
    property int _googlePollAttempts: 0

    onGoogleClientIdChanged: { if (Config.ready) Qt.callLater(() => root.checkGoogleToken()) }

    // ── Token status ──────────────────────────────────────────────────
    function checkGoogleToken(): void {
        if (root.googleClientId.length === 0) { root.googleConnected = false; return }
        if (root.googleChecking) return
        root.googleChecking = true
        googleTokenInfoProcess.running = true
    }

    // ── Device flow: start authentication ─────────────────────────────
    function startGoogleAuth(): void {
        if (root.googleClientId.length === 0) return
        root.googleError = ""
        root.googleVerificationUrl = ""
        root.googleUserCode = ""
        root._googleDevice = null
        root._googlePolling = false
        googleOAuthRequestProcess.command = [
            "/usr/bin/python3", root.googleScript, "oauth-request", root.googleClientId
        ]
        googleOAuthRequestProcess.running = true
    }

    function cancelGoogleAuth(): void {
        root._googlePolling = false
        root._googleDevice = null
        googlePollTimer.stop()
        root.googleVerificationUrl = ""
        root.googleUserCode = ""
    }

    // ── Pull Google calendars (birthdays/contacts + any) ─────────────
    function importGoogleCalendar(calendarId: string): void {
        if (!root.googleConnected) return
        root.googleFetching = true
        root.googleError = ""
        googleImportProcess.calendarId = calendarId
        googleImportProcess.command = [
            "/usr/bin/python3", root.googleScript, "import",
            root.googleTokenPath, calendarId, String(root.googleImportDays)
        ]
        googleImportProcess.running = true
    }

    // ── Push one event to Google primary calendar ─────────────────────
    function pushGoogleEvent(payload: var): void {
        if (!root.googlePushEnabled || !root.googleConnected) return
        const eventKey = payload.startDate + "|" + payload.title
        if (root._pushedEvents[eventKey]) return

        let startIso = payload.startDate
        let endIso = payload.endDate || startIso
        if (payload.allDay) {
            startIso = startIso.slice(0, 10)
            endIso = (endIso || startIso).slice(0, 10)
        }
        googlePushProcess.rawArgs = [
            "/usr/bin/python3", root.googleScript, "create-event", root.googleTokenPath,
            JSON.stringify({
                title: payload.title,
                description: payload.description || "",
                location: payload.location || "",
                start: startIso,
                end: endIso,
                allDay: payload.allDay || false
            })
        ]
        googlePushProcess.running = true
        root._pushedEvents[eventKey] = true
    }

    property var _pushedEvents: ({})
    property int _pushIndex: -1
    property var _pushQueue: []
    property bool _pushPending: false

    // Push locally created events to the user's Google Calendar.
    Connections {
        target: Events
        function onEventAdded(event): void {
            if (!root.googlePushEnabled || !root.googleConnected) return
            root.pushGoogleEvent({
                title: event.title ?? "",
                description: event.description ?? "",
                location: "",
                startDate: event.dateTime ?? new Date().toISOString(),
                endDate: event.dateTime ?? new Date().toISOString(),
                allDay: false
            })
        }
    }

    // ── Processes ─────────────────────────────────────────────────────
    Process {
        id: googleTokenInfoProcess
        command: ["/usr/bin/python3", root.googleScript, "token-info", root.googleTokenPath]
        onExited: (exitCode) => {
            root.googleChecking = false
            if (exitCode !== 0) { root.googleConnected = false; return }
            root.googleConnected = true
        }
        stdout: SplitParser {
            onRead: data => {
                try {
                    const info = JSON.parse(data)
                    root.googleAccount = info
                    root.googleConnected = !info.error
                } catch(e) { /* partial line */ }
            }
        }
    }

    Process {
        id: googleOAuthRequestProcess
        onExited: (exitCode) => {
            if (exitCode !== 0) {
                root.googleError = "Request failed"
                return
            }
        }
        stdout: SplitParser {
            onRead: data => {
                try {
                    const res = JSON.parse(data)
                    root.googleVerificationUrl = res.verification_url
                    root.googleUserCode = res.user_code
                    root._googleDevice = res
                    root._googlePolling = true
                    root._googlePollAttempts = 0
                    googlePollTimer.interval = Math.max(1000, (res.interval || 5) * 1000)
                    googlePollTimer.start()
                } catch(e) { /* partial line */ }
            }
        }
    }

    Process {
        id: googleOAuthPollProcess
        onExited: (exitCode) => {
            if (!root._googlePolling) return
            if (exitCode !== 0) { googlePollTimer.stop(); root._googlePolling = false; return }
        }
        stdout: SplitParser {
            onRead: data => {
                try {
                    const res = JSON.parse(data)
                    if (res.status === "ok") {
                        googlePollTimer.stop()
                        root._googlePolling = false
                        root._googleDevice = null
                        root.googleVerificationUrl = ""
                        root.googleUserCode = ""
                        root.checkGoogleToken()
                        root.importGoogleCalendar("addressbook#contacts@group.v.calendar.google.com")
                    } else if (res.status === "error") {
                        googlePollTimer.stop()
                        root._googlePolling = false
                        root.googleError = res.error || "Auth failed"
                    }
                } catch(e) { /* partial line */ }
            }
        }
    }

    Timer {
        id: googlePollTimer
        repeat: true
        onTriggered: {
            if (!root._googlePolling || !root._googleDevice) { stop(); return }
            root._googlePollAttempts++
            if (root._googlePollAttempts > 300) { stop(); root._googlePolling = false; return }
            googleOAuthPollProcess.command = [
                "/usr/bin/python3", root.googleScript, "oauth-poll",
                root.googleClientId, root.googleClientSecret || "n/a",
                root._googleDevice.device_code, root.googleTokenPath
            ]
            googleOAuthPollProcess.running = true
        }
    }

    Process {
        id: googleImportProcess
        property string calendarId: "primary"
        property string _accum: ""
        onRunningChanged: { if (running) _accum = "" }
        onExited: (exitCode) => {
            if (exitCode === 0) {
                try {
                    const res = JSON.parse(googleImportProcess._accum)
                    const events = res.events ?? []
                    _mergeGoogleEvents(events, googleImportProcess.calendarId)
                    root.googleEventCount = (root._googleEvents ?? []).length
                    root.eventsUpdated()
                } catch(e) {
                    _log("Google import parse error:", e.message)
                }
            }
            root.googleFetching = false
        }
        stdout: SplitParser {
            splitMarker: ""
            onRead: (data) => {
                googleImportProcess._accum += data
            }
        }
    }

    property var _googleEvents: []

    function _mergeGoogleEvents(events: var, calendarId: string): void {
        const mapped = events.map(ev => {
            const allDay = !!ev.allDay
            const startDate = allDay ? new Date(ev.start + "T00:00:00") : new Date(ev.start)
            const endDate = allDay ? new Date((ev.end || ev.start) + "T00:00:00") : new Date(ev.end || ev.start)
            return {
                title: ev.title,
                description: ev.description || "",
                location: ev.location || "",
                startDate: isNaN(startDate.getTime()) ? new Date().toISOString() : startDate.toISOString(),
                endDate: isNaN(endDate.getTime()) ? new Date().toISOString() : endDate.toISOString(),
                allDay: allDay,
                recurrence: ev.recurrence || "none",
                uid: ev.uid || ev.eventId || "",
                sourceId: "google_" + calendarId,
                sourceName: root.googleAccount?.email || "Google",
                sourceColor: "#4285F4"
            }
        })
        // Keep both the Google-specific list (birthdays) and the merged view.
        if (calendarId.indexOf("addressbook") !== -1) {
            root._googleEvents = mapped
        }
        const other = (root.events ?? []).filter(e => e.sourceId !== "google_" + calendarId)
        root.events = other.concat(mapped)
        root.saveCache()
    }

    // Navigate the user to Google's devices / OAuth setup in the default browser.
    function openGoogleAuthLink(): void {
        ShellExec.execDetachedArgs(["xdg-open", "https://console.cloud.google.com/apis/credentials"])
    }

    function openGoogleDeviceUrl(): void {
        if (root.googleVerificationUrl.length > 0)
            ShellExec.execDetachedArgs(["xdg-open", root.googleVerificationUrl])
    }

    Process {
        id: googlePushProcess
        onExited: (exitCode) => {
            if (exitCode !== 0)
                _log("Google push failed", exitCode)
        }
    }
}
