pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

WindowDialog {
    id: root
    backgroundHeight: 600

    property var editingEvent: null
    property bool isEditing: editingEvent !== null

    // Form state
    property string eventTitle: ""
    property string eventDescription: ""
    property date eventDate: new Date()
    property string eventTime: "12:00"
    property bool eventAllDay: false
    property string eventCategory: "general"
    property string eventPriority: "normal"
    property int reminderMinutes: 15
    property string recurrence: "none"
    property bool syncToGoogle: true
    property string selectedContactId: ""
    property string contactSearchText: ""

    // Theme colors (same proven pattern as EventsWidget)
    readonly property color colPrimary: Appearance.angelEverywhere ? Appearance.angel.colPrimary
        : Appearance.inirEverywhere ? Appearance.inir.colPrimary : Appearance.colors.colPrimary
    readonly property color colText: Appearance.angelEverywhere ? Appearance.angel.colText
        : Appearance.inirEverywhere ? Appearance.inir.colText : Appearance.colors.colOnLayer1
    readonly property color colSubtext: Appearance.angelEverywhere ? Appearance.angel.colTextSecondary
        : Appearance.inirEverywhere ? Appearance.inir.colTextSecondary : Appearance.colors.colSubtext
    // Opaque, high-contrast surface for the dropdown/overlay. colSurfaceContainerHigh
    // is translucent (contentTransparency=0.57) so it showed the dialog base as white;
    // colLayer1Base is the opaque m3 surface (#0B0E16) — guaranteed readable + dark.
    readonly property color colDropdownBg: Appearance.colors.colLayer1Base
    readonly property color colDropdownText: Appearance.colors.colOnLayer1
    readonly property color colDropdownSubtext: Appearance.colors.colSubtext

    Component.onCompleted: {
        console.log("[EventsDialog] DEBUG2 bg:", root.colDropdownBg)
        console.log("[EventsDialog] DEBUG2 text:", root.colDropdownText)
        console.log("[EventsDialog] DEBUG2 subtext:", root.colDropdownSubtext)
    }

    function resetForm(): void {
        root.editingEvent = null
        root.eventTitle = ""
        root.eventDescription = ""
        root.eventDate = new Date()
        root.eventTime = "12:00"
        root.eventAllDay = false
        root.eventCategory = "general"
        root.eventPriority = "normal"
        root.reminderMinutes = 15
        root.recurrence = "none"
        root.syncToGoogle = true
        root.selectedContactId = ""
        root.contactSearchText = ""
        Events.contactSearchResults = []
    }

    function loadEvent(event: var): void {
        root.editingEvent = event
        root.eventTitle = event.title || ""
        root.eventDescription = event.description || ""
        const dt = new Date(event.dateTime)
        root.eventDate = dt
        root.eventAllDay = !!event.allDay
        root.eventTime = dt.getHours().toString().padStart(2, '0') + ":" + dt.getMinutes().toString().padStart(2, '0')
        root.eventCategory = event.category || "general"
        root.eventPriority = event.priority || "normal"
        root.reminderMinutes = event.reminderMinutes ?? 15
        root.recurrence = event.recurrence || "none"
        // If this is an existing birthday linked to a Google contact, pre-fill the picker.
        const gid = event.googleEventId || ""
        if (event.category === "birthday" && gid.startsWith("people/")) {
            root.selectedContactId = gid
            root.contactSearchText = event.contactName || event.title || ""
            root.eventTitle = root.contactSearchText
        } else {
            root.selectedContactId = ""
            root.contactSearchText = ""
        }
    }

    // For birthdays, "the person" is the local contact name: the linked Google
    // contact's name if one is chosen, otherwise the typed name. A birthday does
    // not require linking a Google contact — typing a name is enough to save.
    function birthdayName(): string {
        if (root.eventCategory !== "birthday") return ""
        if (root.selectedContactId !== "") return root.contactSearchText.trim()
        return root.eventTitle.trim()
    }

    // Save/display title. Birthdays read "<Name> Birthday"; other categories use
    // the title exactly as typed.
    function buildTitle(): string {
        if (root.eventCategory !== "birthday") return root.eventTitle.trim()
        const name = root.birthdayName()
        return name === "" ? Translation.tr("Birthday") : name + " " + Translation.tr("Birthday")
    }

    // Whether the form has enough to save (a birthday just needs a name).
    // Bound property reading only reactive fields directly (no function call),
    // so the Save button re-enables as you type.
    readonly property bool canSave:
        root.eventCategory === "birthday"
            ? (root.selectedContactId !== ""
                ? root.contactSearchText.trim() !== ""
                : root.eventTitle.trim() !== "")
            : root.eventTitle.trim() !== ""

    function saveEvent(): bool {
        if (!root.canSave) return false

        let dateTime = new Date(root.eventDate)
        if (root.eventAllDay) {
            dateTime.setHours(0, 0, 0, 0)
        } else {
            const timeParts = root.eventTime.split(":")
            const hour = parseInt(timeParts[0]) || 0
            const minute = parseInt(timeParts[1]) || 0
            dateTime.setHours(hour, minute, 0, 0)
        }
        const dateTimeIso = dateTime.toISOString()

        const effectiveTitle = root.buildTitle()
        const personName = root.birthdayName()

        if (root.isEditing) {
            Events.updateEvent(root.editingEvent.id, {
                title: effectiveTitle,
                description: root.eventDescription.trim(),
                dateTime: dateTimeIso,
                allDay: root.eventAllDay,
                category: root.eventCategory,
                priority: root.eventPriority,
                reminderMinutes: root.reminderMinutes,
                recurrence: root.recurrence,
                contactName: root.eventCategory === "birthday"
                    ? personName
                    : (root.editingEvent.contactName || effectiveTitle),
                notified: false
            })
            const edited = {
                id: root.editingEvent.id,
                googleEventId: root.editingEvent.googleEventId,
                title: effectiveTitle,
                description: root.eventDescription.trim(),
                dateTime: dateTimeIso,
                allDay: root.eventAllDay,
                category: root.eventCategory,
                priority: root.eventPriority,
                reminderMinutes: root.reminderMinutes,
                recurrence: root.recurrence,
                contactName: root.eventCategory === "birthday" ? personName : ""
            }
            if (root.editingEvent.googleEventId) {
                if (root.syncToGoogle) Events.pushToGoogle(edited)
            } else if (root.syncToGoogle && !root.editingEvent.recurrenceOf) {
                Events.createInGoogle(edited, null, root.selectedContactId)
            }
        } else {
            const event = Events.addEvent(
                effectiveTitle,
                root.eventDescription.trim(),
                dateTimeIso,
                root.eventCategory,
                root.eventPriority,
                root.reminderMinutes,
                root.recurrence,
                root.eventAllDay,
                root.eventCategory === "birthday" ? personName : (effectiveTitle || "")
            )
            if (root.syncToGoogle) Events.pushToGoogle(event, null, root.selectedContactId)
        }
        return true
    }

    WindowDialogTitle {
        text: root.isEditing ? Translation.tr("Edit Event") : Translation.tr("New Event")
    }

    WindowDialogSeparator {}

    // Scrollable content
    Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true

        contentHeight: formColumn.implicitHeight + 16
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        Column {
            id: formColumn
            width: parent.width
            spacing: 4

            // ─── Basic Info Section ───────────────────────────────────
            WindowDialogSectionHeader {
                text: Translation.tr("Basic Info")
            }

            WindowDialogSeparator {
                Layout.topMargin: -22
            }

            Column {
                width: parent.width
                spacing: 8
                topPadding: 8

                MaterialTextField {
                    width: parent.width - 16
                    anchors.horizontalCenter: parent.horizontalCenter
                    placeholderText: Translation.tr("Event title") + " *"
                    text: root.eventTitle
                    onTextChanged: root.eventTitle = text
                    visible: root.eventCategory !== "birthday"
                }

                MaterialTextField {
                    width: parent.width - 16
                    anchors.horizontalCenter: parent.horizontalCenter
                    placeholderText: root.eventCategory === "birthday"
                        ? Translation.tr("Birthday of (e.g. Arnau)")
                        : Translation.tr("Description (optional)")
                    text: root.eventCategory === "birthday" ? root.eventTitle : root.eventDescription
                    onTextChanged: {
                        const v = String(text || "")
                        if (root.eventCategory === "birthday") root.eventTitle = v
                        else root.eventDescription = v
                    }
                }
            }

            // ─── Date & Time Section ──────────────────────────────────
            WindowDialogSectionHeader {
                text: Translation.tr("Date & Time")
                topPadding: 16
            }

            WindowDialogSeparator {
                Layout.topMargin: -22
            }

            Column {
                width: parent.width
                spacing: 0

                // Date picker
                DatePicker {
                    width: parent.width
                    selectedDate: root.eventDate
                    onDateSelected: (date) => { root.eventDate = date }
                }

                // All-day toggle: whole-day event, no time
                ConfigSwitch {
                    anchors {
                        left: parent.left
                        right: parent.right
                        leftMargin: 8
                        rightMargin: 8
                    }
                    enableSettingsSearch: false
                    iconSize: Appearance.font.pixelSize.larger
                    buttonIcon: "event_available"
                    text: Translation.tr("All day")
                    description: Translation.tr("Whole-day event without a specific time")
                    checked: root.eventAllDay
                    onCheckedChanged: root.eventAllDay = checked
                }

                // Time input using ConfigTimeInput pattern (hidden for all-day)
                ConfigTimeInput {
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    visible: !root.eventAllDay
                    icon: "schedule"
                    text: Translation.tr("Time")
                    value: root.eventTime
                    onTimeChanged: (newTime) => { root.eventTime = newTime }
                }
            }

            // ─── Category Section ─────────────────────────────────────
            WindowDialogSectionHeader {
                text: Translation.tr("Category")
                topPadding: 16
            }

            WindowDialogSeparator {
                Layout.topMargin: -22
            }

            ConfigSelectionArray {
                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: 8
                    rightMargin: 8
                }
                enableSettingsSearch: false
                options: [
                    { displayName: Translation.tr("General"), icon: "event", value: "general" },
                    { displayName: Translation.tr("Birthday"), icon: "cake", value: "birthday" },
                    { displayName: Translation.tr("Meeting"), icon: "groups", value: "meeting" },
                    { displayName: Translation.tr("Deadline"), icon: "flag", value: "deadline" },
                    { displayName: Translation.tr("Reminder"), icon: "notifications", value: "reminder" }
                ]
                currentValue: root.eventCategory
                onSelected: (newValue) => { root.eventCategory = newValue }
            }

            // ─── Contact picker (only for birthdays) ──────────────────
            WindowDialogSectionHeader {
                text: Translation.tr("Linked Contact")
                topPadding: 16
                visible: root.eventCategory === "birthday"
            }

            WindowDialogSeparator {
                Layout.topMargin: -22
                visible: root.eventCategory === "birthday"
            }

            Column {
                width: parent.width - 16
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                visible: root.eventCategory === "birthday"

                MaterialTextField {
                    id: contactSearchField
                    width: parent.width
                    placeholderText: Translation.tr("Search Google Contacts...")
                    text: root.contactSearchText
                    onTextChanged: {
                        root.contactSearchText = text
                        if (text !== "" && root.selectedContactId === "") {
                            // Re-run search from the typed name.
                            Events.searchContacts(text)
                        }
                    }
                }

                // Dropdown of results while typing
                Rectangle {
                    id: contactDropdown
                    width: parent.width
                    visible: Events.contactSearchResults.length > 0
                    height: Math.min(Events.contactSearchResults.length * 52, 208)
                    radius: 10
                    color: root.colDropdownBg
                    border.color: root.colPrimary
                    border.width: 1
                    clip: true
                    z: 10
                    Column {
                        width: parent.width
                        spacing: 2
                        Repeater {
                            model: Events.contactSearchResults
                            delegate: Rectangle {
                                required property var modelData
                                width: parent.width
                                height: 52
                                color: modelData.id === root.selectedContactId
                                    ? ColorUtils.applyAlpha(root.colPrimary, 0.25) : "transparent"
                                MouseArea {
                                    id: rowArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: {
                                        root.selectedContactId = modelData.id
                                        root.contactSearchText = modelData.name
                                        Events.contactSearchResults = []
                                        if (root.eventCategory === "birthday" && root.eventTitle.trim() === "") {
                                            root.eventTitle = modelData.name
                                        }
                                    }
                                }
                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.right: parent.right
                                    anchors.rightMargin: 12
                                    spacing: 10
                                    Column {
                                        width: parent.width - 26
                                        spacing: 2
                                        Text {
                                            text: modelData.name || ""
                                            color: root.colDropdownText
                                            elide: Text.ElideRight
                                            font.pixelSize: 15
                                        }
                                        Row {
                                            width: parent.width
                                            spacing: 8
                                            Text {
                                                text: modelData.phone || ""
                                                color: ColorUtils.applyAlpha(root.colDropdownSubtext, 0.65)
                                                elide: Text.ElideRight
                                                font.pixelSize: 11
                                                font.family: Appearance.font.family.numbers
                                            }
                                            Text {
                                                visible: modelData.birthday !== ""
                                                text: "• " + modelData.birthday
                                                color: ColorUtils.applyAlpha(root.colDropdownSubtext, 0.45)
                                                elide: Text.ElideRight
                                                font.pixelSize: 11
                                            }
                                        }
                                    }
                                    Text {
                                        text: "+"
                                        color: root.colPrimary
                                        font.pixelSize: 22
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }
                    }
                }

                // Confirmation + deselection row when a contact is chosen
                Row {
                    width: parent.width
                    spacing: 8
                    visible: root.selectedContactId !== ""
                    Text {
                        text: "✓ " + root.contactSearchText
                        color: root.colPrimary
                        elide: Text.ElideRight
                        font.pixelSize: 14
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Item { Layout.fillWidth: true; width: 1; height: 1 }
                    Text {
                        text: Translation.tr("Change")
                        color: root.colPrimary
                        font.pixelSize: 14
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.selectedContactId = ""
                                root.contactSearchText = ""
                                Events.contactSearchResults = []
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: root.selectedContactId === ""
                        ? Translation.tr("Leave empty to auto-detect contact by name, or search above to link a specific one.")
                        : Translation.tr("This contact's birthday will be set in Google.")
                    color: root.colSubtext
                    wrapMode: Text.WordWrap
                    font.pixelSize: 12
                }
            }

            // ─── Priority Section ─────────────────────────────────────
            WindowDialogSectionHeader {
                text: Translation.tr("Priority")
                topPadding: 16
            }

            WindowDialogSeparator {
                Layout.topMargin: -22
            }

            ConfigSelectionArray {
                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: 8
                    rightMargin: 8
                }
                enableSettingsSearch: false
                options: [
                    { displayName: Translation.tr("Low"), icon: "arrow_downward", value: "low" },
                    { displayName: Translation.tr("Normal"), icon: "remove", value: "normal" },
                    { displayName: Translation.tr("High"), icon: "priority_high", value: "high" }
                ]
                currentValue: root.eventPriority
                onSelected: (newValue) => { root.eventPriority = newValue }
            }

            // ─── Reminder Section ─────────────────────────────────────
            WindowDialogSectionHeader {
                text: Translation.tr("Reminder")
                topPadding: 16
            }

            WindowDialogSeparator {
                Layout.topMargin: -22
            }

            ConfigSelectionArray {
                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: 8
                    rightMargin: 8
                }
                enableSettingsSearch: false
                options: [
                    { displayName: Translation.tr("None"), icon: "notifications_off", value: 0 },
                    { displayName: Translation.tr("5 min"), icon: "alarm", value: 5 },
                    { displayName: Translation.tr("15 min"), icon: "alarm", value: 15 },
                    { displayName: Translation.tr("1 hour"), icon: "alarm", value: 60 },
                    { displayName: Translation.tr("1 day"), icon: "alarm", value: 1440 }
                ]
                currentValue: root.reminderMinutes
                onSelected: (newValue) => { root.reminderMinutes = newValue }
            }

            // ─── Repeat Section ───────────────────────────────────────
            WindowDialogSectionHeader {
                text: Translation.tr("Repeat")
                topPadding: 16
            }

            WindowDialogSeparator {
                Layout.topMargin: -22
            }

            ConfigSelectionArray {
                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: 8
                    rightMargin: 8
                }
                enableSettingsSearch: false
                options: [
                    { displayName: Translation.tr("Never"), icon: "block", value: "none" },
                    { displayName: Translation.tr("Daily"), icon: "today", value: "daily" },
                    { displayName: Translation.tr("Weekly"), icon: "date_range", value: "weekly" },
                    { displayName: Translation.tr("Monthly"), icon: "calendar_month", value: "monthly" },
                    { displayName: Translation.tr("Yearly"), icon: "event_repeat", value: "yearly" }
                ]
                currentValue: root.recurrence
                onSelected: (newValue) => { root.recurrence = newValue }
            }

            // ─── Google Sync Section ─────────────────────────────────
            WindowDialogSectionHeader {
                text: Translation.tr("Google Calendar")
                topPadding: 16
            }

            WindowDialogSeparator {
                Layout.topMargin: -22
            }

            ConfigSwitch {
                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: 8
                    rightMargin: 8
                }
                enableSettingsSearch: false
                iconSize: Appearance.font.pixelSize.larger
                buttonIcon: "cloud_sync"
                text: Translation.tr("Sync to Google Calendar")
                description: Translation.tr("Keep a copy in your Google Calendar")
                checked: root.syncToGoogle
                onCheckedChanged: root.syncToGoogle = checked
            }

            // Bottom padding
            Item { width: 1; height: 16 }
        }
    }

    WindowDialogSeparator {}

    WindowDialogButtonRow {
        DialogButton {
            visible: root.isEditing
            buttonText: Translation.tr("Delete")
            onClicked: {
                if (root.editingEvent?.googleEventId && root.syncToGoogle) {
                    Events.deleteFromGoogle(root.editingEvent.googleEventId)
                }
                Events.removeEvent(root.editingEvent.id)
                root.resetForm()
                root.dismiss()
            }
        }

        Item { Layout.fillWidth: true }

        DialogButton {
            buttonText: Translation.tr("Cancel")
            onClicked: {
                root.resetForm()
                root.dismiss()
            }
        }

        DialogButton {
            buttonText: root.isEditing ? Translation.tr("Save") : Translation.tr("Add Event")
            enabled: root.canSave
            onClicked: {
                if (root.saveEvent()) {
                    root.resetForm()
                    root.dismiss()
                }
            }
        }
    }
}
