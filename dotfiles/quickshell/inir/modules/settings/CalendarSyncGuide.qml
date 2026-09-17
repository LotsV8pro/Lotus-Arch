import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ContentPage {
    id: root
    settingsPageIndex: 28
    settingsPageName: Translation.tr("Calendar Sync")

    // ─── Google Calendar OAuth ───────────────────────────────────────
    SettingsCardSection {
        id: googleSection
        expanded: true
        icon: "event"
        title: Translation.tr("Google Calendar sync")

        SettingsGroup {
            // Google G logo + title
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                CustomIcon {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    Layout.alignment: Qt.AlignVCenter
                    source: "google-symbolic"
                    colorize: false
                }

                StyledText {
                    text: Translation.tr("Google Calendar sync")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }
            }

            // Step-by-step tutorial
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                StyledText {
                    text: Translation.tr("To sync your Google Calendar, create your own OAuth credentials (the token stays on your machine only).")
                    wrapMode: Text.WordWrap
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.small
                    Layout.fillWidth: true
                }

                StyledText {
                    text: Translation.tr("Step 1: Create a Google Cloud project")
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: Translation.tr("Go to console.cloud.google.com → Create a project → name it anything (e.g. \"my-shell-calendar\").")
                    wrapMode: Text.WordWrap
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    Layout.fillWidth: true
                }

                StyledText {
                    text: Translation.tr("Step 2: Enable Calendar API")
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: Translation.tr("In the project, go to APIs & Services → Library → search \"Google Calendar API\" → Enable.")
                    wrapMode: Text.WordWrap
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    Layout.fillWidth: true
                }

                StyledText {
                    text: Translation.tr("Step 3: Create OAuth credentials")
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: Translation.tr("Go to APIs & Services → Credentials → Create Credentials → OAuth client ID → Application type: TV and Limited input devices → Create. Copy the Client ID and Client Secret below.")
                    wrapMode: Text.WordWrap
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    Layout.fillWidth: true
                }

                StyledText {
                    text: Translation.tr("Step 4: Paste credentials and connect")
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: Translation.tr("Enter the Client ID (and Client Secret if you created one) below, then click Connect. A code will appear — enter it at the URL shown to authorize access.")
                    wrapMode: Text.WordWrap
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    Layout.fillWidth: true
                }
            }

            RippleButtonWithIcon {
                materialIcon: "open_in_new"
                mainText: Translation.tr("Open Google Cloud credentials")
                onClicked: CalendarSync.openGoogleAuthLink()
            }

            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                Layout.topMargin: 4

                StyledText {
                    text: Translation.tr("Client ID")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }

                MaterialTextField {
                    id: googleClientIdInput
                    Layout.fillWidth: true
                    text: Config.options?.calendar?.googleOAuth?.clientId ?? ""
                    placeholderText: "xxxxxxxx.apps.googleusercontent.com"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnSurface
                    placeholderTextColor: Appearance.colors.colSubtext
                    onTextEdited: Config.setNestedValue("calendar.googleOAuth.clientId", text.trim())
                    background: Rectangle {
                        color: Appearance.colors.colLayer1
                        radius: Appearance.rounding.small
                        border.width: googleClientIdInput.activeFocus ? 2 : 1
                        border.color: googleClientIdInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                    }
                }
            }

            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true

                StyledText {
                    text: Translation.tr("Client Secret (optional)")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }

                MaterialTextField {
                    id: googleClientSecretInput
                    Layout.fillWidth: true
                    text: Config.options?.calendar?.googleOAuth?.clientSecret ?? ""
                    placeholderText: Translation.tr("Leave empty for installed/public apps")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnSurface
                    placeholderTextColor: Appearance.colors.colSubtext
                    echoMode: TextInput.Password
                    onTextEdited: Config.setNestedValue("calendar.googleOAuth.clientSecret", text.trim())
                    background: Rectangle {
                        color: Appearance.colors.colLayer1
                        radius: Appearance.rounding.small
                        border.width: googleClientSecretInput.activeFocus ? 2 : 1
                        border.color: googleClientSecretInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item { Layout.fillWidth: true }

                RippleButton {
                    implicitWidth: googleCancelLabel.implicitWidth + 24
                    implicitHeight: 32
                    buttonRadius: Appearance.rounding.small
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    visible: CalendarSync.googleVerificationUrl !== ""
                    onClicked: CalendarSync.cancelGoogleAuth()

                    contentItem: StyledText {
                        id: googleCancelLabel
                        anchors.centerIn: parent
                        text: Translation.tr("Cancel")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1
                    }
                }

                RippleButton {
                    implicitWidth: googleConnectLabel.implicitWidth + 24
                    implicitHeight: 32
                    buttonRadius: Appearance.rounding.small
                    colBackground: CalendarSync.googleConnected ? ColorUtils.transparentize(Appearance.colors.colTertiary, 0.85) : Appearance.colors.colPrimary
                    colBackgroundHover: CalendarSync.googleConnected ? ColorUtils.transparentize(Appearance.colors.colTertiary, 0.75) : Appearance.colors.colPrimaryHover
                    enabled: Config.options?.calendar?.googleOAuth?.clientId?.trim?.()?.length ?? 0 > 0
                    opacity: enabled ? 1 : 0.5
                    onClicked: CalendarSync.googleConnected ? importGoogleCalendars() : CalendarSync.startGoogleAuth()

                    contentItem: RowLayout {
                        id: googleConnectRow
                        anchors.centerIn: parent
                        spacing: 6

                        MaterialSymbol {
                            text: CalendarSync.googleConnected ? "sync" : "login"
                            iconSize: 16
                            color: CalendarSync.googleConnected ? Appearance.colors.colTertiary : Appearance.colors.colOnPrimary
                        }
                        StyledText {
                            id: googleConnectLabel
                            text: CalendarSync.googleConnected
                                ? Translation.tr("Sync calendars")
                                : Translation.tr("Connect account")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: CalendarSync.googleConnected ? Appearance.colors.colTertiary : Appearance.colors.colOnPrimary
                        }
                    }
                }
            }

            // Device flow prompt (verification URL + user code)
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 8
                visible: CalendarSync.googleVerificationUrl !== ""

                radius: Appearance.rounding.small
                color: Appearance.colors.colSurfaceContainerLow
                border.width: 1
                border.color: Appearance.colors.colLayer0Border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    StyledText {
                        text: Translation.tr("Authorize the device")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer1
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("Open the link below, sign in and enter this code:")
                        wrapMode: Text.WordWrap
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }

                    RippleButtonWithIcon {
                        materialIcon: "link"
                        mainText: CalendarSync.googleVerificationUrl
                        onClicked: CalendarSync.openGoogleDeviceUrl()
                    }

                    Rectangle {
                        Layout.preferredWidth: googleUserCodeText.implicitWidth + 28
                        Layout.preferredHeight: googleUserCodeText.implicitHeight + 16
                        radius: Appearance.rounding.small
                        color: Appearance.colors.colLayer1

                        StyledText {
                            id: googleUserCodeText
                            anchors.centerIn: parent
                            text: CalendarSync.googleUserCode
                            font.pixelSize: Appearance.font.pixelSize.huge
                            font.family: "monospace"
                            font.weight: Font.Bold
                            color: Appearance.colors.colPrimary
                        }
                    }

                    StyledText {
                        text: Translation.tr("Waiting for authorization…")
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.italic: true
                        color: Appearance.colors.colSubtext
                    }
                }
            }

            // Connected status
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 8
                visible: CalendarSync.googleConnected

                radius: Appearance.rounding.small
                color: ColorUtils.transparentize(Appearance.colors.colTertiary, 0.88)
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.colors.colTertiary, 0.7)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    MaterialSymbol {
                        text: "check_circle"
                        iconSize: 20
                        color: Appearance.colors.colTertiary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        StyledText {
                            text: CalendarSync.googleAccount?.email ?? Translation.tr("Connected")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                            elide: Text.ElideRight
                        }

                        StyledText {
                            text: Translation.tr("%1 events synced from Google").arg(CalendarSync.googleEventCount ?? 0)
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.colors.colSubtext
                        }
                    }

                    MaterialSymbol {
                        visible: CalendarSync.googleFetching
                        text: "progress_activity"
                        iconSize: 16
                        color: Appearance.colors.colTertiary
                        rotation: CalendarSync.googleFetching ? 360 : 0
                        Behavior on rotation { RotationAnimation { duration: 600 } }
                    }
                }
            }

            SettingsDivider {}

            // Sync & push options (only meaningful when connected)
            SettingsSwitch {
                buttonIcon: "cake"
                text: Translation.tr("Sync birthdays & contacts")
                description: Translation.tr("Pulls the Google Contacts birthday calendar automatically after connecting. Runs again whenever you press Sync calendars.")
                checked: CalendarSync.googleConnected
                enabled: CalendarSync.googleConnected
                autoToggle: false
                onClicked: CalendarSync.importGoogleCalendar("addressbook#contacts@group.v.calendar.google.com")
                visible: CalendarSync.googleConnected
            }

            SettingsSwitch {
                buttonIcon: "upload"
                text: Translation.tr("Push new events to Google")
                description: Translation.tr("Events you create in the sidebar calendar are added to your Google primary calendar.")
                checked: Config.options?.calendar?.googleOAuth?.pushEnabled ?? false
                enabled: CalendarSync.googleConnected
                onCheckedChanged: Config.setNestedValue("calendar.googleOAuth.pushEnabled", checked)
                visible: CalendarSync.googleConnected
            }

            ConfigSpinBox {
                icon: "calendar_view_day"
                text: Translation.tr("Days to import from Google")
                value: Config.options?.calendar?.googleOAuth?.importDays ?? 365
                from: 7
                to: 3650
                stepSize: 1
                onValueChanged: Config.setNestedValue("calendar.googleOAuth.importDays", value)
                enabled: CalendarSync.googleConnected
                visible: CalendarSync.googleConnected
            }

            StyledText {
                visible: CalendarSync.googleError !== ""
                Layout.fillWidth: true
                Layout.topMargin: 6
                text: CalendarSync.googleError
                wrapMode: Text.WordWrap
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colError
            }

            function importGoogleCalendars(): void {
                CalendarSync.importGoogleCalendar("addressbook#contacts@group.v.calendar.google.com")
                CalendarSync.importGoogleCalendar("primary")
            }
        }
    }

    // ─── How It Works ───────────────────────────────────────────────
    SettingsCardSection {
        expanded: true
        icon: "calendar_month"
        title: Translation.tr("How it works")

        SettingsGroup {
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Calendar sync downloads events from external ICS/iCal links, converts them to the internal format, and caches them locally. No account or backend needed: just curl and the built-in parser.")
                wrapMode: Text.WordWrap
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.small
            }
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Synced events appear in the right sidebar calendar and can trigger automatic reminders. They are fetched periodically and stored in ~/.local/state/quickshell/user/calendar-sync-cache.json.")
                wrapMode: Text.WordWrap
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smallest
            }
        }
    }

    // ─── How to Get Your ICS URL ─────────────────────────────────────
    SettingsCardSection {
        expanded: false
        icon: "help"
        title: Translation.tr("How to get your ICS link")

        SettingsGroup {
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                // Step 1: Google Calendar
                RowLayout {
                    spacing: 10
                    Layout.fillWidth: true

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 14
                        color: Appearance.colors.colPrimary
                        StyledText {
                            anchors.centerIn: parent
                            text: "1"
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnPrimary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        StyledText {
                            text: "Google Calendar"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: Translation.tr("Calendar settings → Settings → Integrate calendar → Public URL to this calendar → copy the iCal link (starts with https://calendar.google.com/calendar/ical/...)")
                            wrapMode: Text.WordWrap
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.colors.colSubtext
                            Layout.fillWidth: true
                        }
                    }
                }

                // Step 2: Outlook / Office 365
                RowLayout {
                    spacing: 10
                    Layout.fillWidth: true

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 14
                        color: Appearance.colors.colPrimary
                        StyledText {
                            anchors.centerIn: parent
                            text: "2"
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnPrimary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        StyledText {
                            text: "Outlook / Office 365"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: Translation.tr("Calendars → right-click the calendar → Properties → Web tab. Copy the resulting .ics link.")
                            wrapMode: Text.WordWrap
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.colors.colSubtext
                            Layout.fillWidth: true
                        }
                    }
                }

                // Step 3: Self-hosted / Other
                RowLayout {
                    spacing: 10
                    Layout.fillWidth: true

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 14
                        color: Appearance.colors.colPrimary
                        StyledText {
                            anchors.centerIn: parent
                            text: "3"
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnPrimary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        StyledText {
                            text: Translation.tr("CalDAV / Self-hosted")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: Translation.tr("Nextcloud, Radicale, Baikal or any CalDAV server: look for the export/subscribe option (webcal://) and convert it to https if needed.")
                            wrapMode: Text.WordWrap
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.colors.colSubtext
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }

    // ─── Current Sources ─────────────────────────────────────────────
    SettingsCardSection {
        expanded: true
        icon: "sync"
        title: Translation.tr("Current Status")

        SettingsGroup {
            visible: Config.options?.calendar?.externalSync?.enable ?? false

            // Sources header + Add button
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                Layout.bottomMargin: 4

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Synced sources")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }

                RippleButton {
                    implicitWidth: addBtnRow.implicitWidth + 16
                    implicitHeight: 32
                    buttonRadius: Appearance.rounding.small
                    colBackground: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.88)
                    colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.80)
                    onClicked: addSourceForm.expanded = true

                    contentItem: RowLayout {
                        id: addBtnRow
                        anchors.centerIn: parent
                        spacing: 4

                        MaterialSymbol {
                            text: "add"
                            iconSize: 16
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: Translation.tr("Add")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: Appearance.colors.colPrimary
                        }
                    }
                }
            }

            // Source list
            Repeater {
                model: Config.options?.calendar?.externalSync?.sources ?? []

                delegate: Item {
                    id: sourceItem
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: sourceRow.implicitHeight + 12

                    Rectangle {
                        anchors.fill: parent
                        radius: Appearance.rounding.small
                        color: sourceMA.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"
                        Behavior on color { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration } }

                        RowLayout {
                            id: sourceRow
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 12
                                Layout.preferredHeight: 12
                                radius: 6
                                color: sourceItem.modelData?.color ?? Appearance.colors.colPrimary
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                StyledText {
                                    Layout.fillWidth: true
                                    text: sourceItem.modelData?.name ?? Translation.tr("Unnamed")
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnLayer1
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: {
                                        const st = CalendarSync.sourceStatuses?.[sourceItem.modelData?.id]
                                        if (st?.error) return st.error
                                        if (st?.eventCount !== undefined) return Translation.tr("%1 events · %2").arg(st.eventCount).arg(st.lastFetch ? new Date(st.lastFetch).toLocaleString() : "—")
                                        return Translation.tr("Pending")
                                    }
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    color: {
                                        const st = CalendarSync.sourceStatuses?.[sourceItem.modelData?.id]
                                        return (st?.error) ? Appearance.colors.colError : Appearance.colors.colSubtext
                                    }
                                    elide: Text.ElideRight
                                }
                            }

                            MaterialSymbol {
                                visible: {
                                    const st = CalendarSync.sourceStatuses?.[sourceItem.modelData?.id]
                                    return st?.error && st.error !== ""
                                }
                                text: "error"
                                iconSize: 16
                                color: Appearance.colors.colError

                                StyledToolTip {
                                    text: CalendarSync.sourceStatuses?.[sourceItem.modelData?.id]?.error ?? ""
                                }
                            }

                            Switch {
                                checked: sourceItem.modelData?.enabled ?? true
                                onCheckedChanged: {
                                    if (checked !== (sourceItem.modelData?.enabled ?? true)) {
                                        CalendarSync.toggleSource(sourceItem.modelData.id, checked)
                                    }
                                }
                            }

                            RippleButton {
                                implicitWidth: 28
                                implicitHeight: 28
                                buttonRadius: 14
                                colBackground: "transparent"
                                colBackgroundHover: Appearance.colors.colLayer1Hover
                                onClicked: CalendarSync.removeSource(sourceItem.modelData.id)

                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "close"
                                    iconSize: 14
                                    color: Appearance.colors.colSubtext
                                }

                                StyledToolTip {
                                    text: Translation.tr("Delete")
                                }
                            }
                        }

                        MouseArea {
                            id: sourceMA
                            anchors.fill: parent
                            z: -1
                            hoverEnabled: true
                        }
                    }
                }
            }

            // Empty state
            StyledText {
                visible: (Config.options?.calendar?.externalSync?.sources ?? []).length === 0
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                text: Translation.tr("No sources added yet")
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
                font.italic: true
            }

            // Add-source form
            Rectangle {
                id: addSourceForm
                Layout.fillWidth: true
                Layout.topMargin: 4

                property bool expanded: false

                implicitHeight: expanded ? addFormCol.implicitHeight + 24 : 0
                visible: expanded
                clip: true
                radius: Appearance.rounding.small
                color: Appearance.colors.colSurfaceContainerLow
                border.width: 1
                border.color: Appearance.colors.colLayer0Border

                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                    }
                }

                ColumnLayout {
                    id: addFormCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    StyledText {
                        text: Translation.tr("Add calendar source")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer1
                    }

                    ColumnLayout {
                        spacing: 4
                        Layout.fillWidth: true

                        StyledText {
                            text: Translation.tr("Name")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }

                        MaterialTextField {
                            id: sourceNameInput
                            Layout.fillWidth: true
                            placeholderText: Translation.tr("Work calendar")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnSurface
                            placeholderTextColor: Appearance.colors.colSubtext
                            background: Rectangle {
                                color: Appearance.colors.colLayer1
                                radius: Appearance.rounding.small
                                border.width: sourceNameInput.activeFocus ? 2 : 1
                                border.color: sourceNameInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: 4
                        Layout.fillWidth: true

                        StyledText {
                            text: Translation.tr("ICS URL")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }

                        MaterialTextField {
                            id: sourceUrlInput
                            Layout.fillWidth: true
                            placeholderText: "https://calendar.google.com/calendar/ical/..."
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnSurface
                            placeholderTextColor: Appearance.colors.colSubtext
                            background: Rectangle {
                                color: Appearance.colors.colLayer1
                                radius: Appearance.rounding.small
                                border.width: sourceUrlInput.activeFocus ? 2 : 1
                                border.color: sourceUrlInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                            }
                        }
                    }

                    // Color picker
                    ColumnLayout {
                        spacing: 4

                        StyledText {
                            text: Translation.tr("Color")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }

                        Row {
                            id: colorPickerRow
                            spacing: 6
                            property string selectedColor: CalendarSync.presetColors[0]

                            Repeater {
                                model: CalendarSync.presetColors

                                delegate: Rectangle {
                                    required property string modelData
                                    required property int index
                                    width: 24
                                    height: 24
                                    radius: 12
                                    color: modelData
                                    border.width: colorPickerRow.selectedColor === modelData ? 2 : 0
                                    border.color: Appearance.colors.colOnLayer1
                                    opacity: colorPickMA.containsMouse ? 0.8 : 1

                                    MouseArea {
                                        id: colorPickMA
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: colorPickerRow.selectedColor = modelData
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Item { Layout.fillWidth: true }

                        RippleButton {
                            implicitWidth: cancelAddLabel.implicitWidth + 24
                            implicitHeight: 32
                            buttonRadius: Appearance.rounding.small
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colLayer1Hover
                            onClicked: {
                                addSourceForm.expanded = false
                                sourceNameInput.text = ""
                                sourceUrlInput.text = ""
                            }

                            contentItem: StyledText {
                                id: cancelAddLabel
                                anchors.centerIn: parent
                                text: Translation.tr("Cancel")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer1
                            }
                        }

                        RippleButton {
                            implicitWidth: addConfirmLabel.implicitWidth + 24
                            implicitHeight: 32
                            buttonRadius: Appearance.rounding.small
                            colBackground: Appearance.colors.colPrimary
                            colBackgroundHover: Appearance.colors.colPrimaryHover
                            enabled: sourceNameInput.text.trim() !== "" && sourceUrlInput.text.trim() !== ""
                            opacity: enabled ? 1 : 0.5
                            onClicked: {
                                CalendarSync.addSource(
                                    sourceNameInput.text.trim(),
                                    sourceUrlInput.text.trim(),
                                    colorPickerRow.selectedColor
                                )
                                sourceNameInput.text = ""
                                sourceUrlInput.text = ""
                                addSourceForm.expanded = false
                            }

                            contentItem: StyledText {
                                id: addConfirmLabel
                                anchors.centerIn: parent
                                text: Translation.tr("Add")
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnPrimary
                            }
                        }
                    }
                }
            }

            // Fetch now + status
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 8
                visible: (Config.options?.calendar?.externalSync?.sources ?? []).length > 0

                MaterialSymbol {
                    text: CalendarSync.fetching ? "progress_activity" : "check_circle"
                    iconSize: 16
                    color: CalendarSync.fetching ? Appearance.colors.colPrimary : Appearance.colors.colTertiary
                    Behavior on rotation { RotationAnimation { duration: 600 } }
                    rotation: CalendarSync.fetching ? 360 : 0
                }

                StyledText {
                    text: CalendarSync.fetching
                        ? Translation.tr("Fetching events...")
                        : Translation.tr("%1 external events cached").arg(CalendarSync.events.length)
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colSubtext
                    Layout.fillWidth: true
                }

                RippleButtonWithIcon {
                    materialIcon: "refresh"
                    mainText: Translation.tr("Fetch now")
                    onClicked: CalendarSync.forceRefreshAll()
                    enabled: !CalendarSync.fetching
                }
            }
        }

        // Sync disabled notice
        StyledText {
            visible: !(Config.options?.calendar?.externalSync?.enable ?? false)
            Layout.fillWidth: true
            text: Translation.tr("Enable sync in the section below to add sources.")
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
            font.italic: true
            wrapMode: Text.WordWrap
        }
    }

    // ─── Configuration ───────────────────────────────────────────────
    SettingsCardSection {
        expanded: false
        icon: "tune"
        title: Translation.tr("Configuration")

        SettingsGroup {
            SettingsSwitch {
                buttonIcon: "sync"
                text: Translation.tr("Enable external sync")
                checked: Config.options?.calendar?.externalSync?.enable ?? false
                onCheckedChanged: Config.setNestedValue("calendar.externalSync.enable", checked)
            }

            ConfigSpinBox {
                icon: "update"
                text: Translation.tr("Update interval (minutes)")
                value: Config.options?.calendar?.externalSync?.refreshMinutes ?? 15
                from: 5
                to: 120
                stepSize: 5
                onValueChanged: Config.setNestedValue("calendar.externalSync.refreshMinutes", value)
                enabled: Config.options?.calendar?.externalSync?.enable ?? false
            }

            SettingsSwitch {
                buttonIcon: "event"
                text: Translation.tr("Show upcoming events below the calendar")
                checked: Config.options?.calendar?.showUpcoming ?? true
                onCheckedChanged: Config.setNestedValue("calendar.showUpcoming", checked)
            }

            ConfigSpinBox {
                icon: "date_range"
                text: Translation.tr("Days of events to show")
                value: Config.options?.calendar?.upcomingDays ?? 3
                from: 1
                to: 14
                stepSize: 1
                onValueChanged: Config.setNestedValue("calendar.upcomingDays", value)
            }
        }
    }

    // ─── Advanced ────────────────────────────────────────────────────
    SettingsCardSection {
        expanded: false
        icon: "manage_search"
        title: Translation.tr("Advanced management")

        SettingsGroup {
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("To clear the cache, force a full reload, or inspect parsed events in detail, use the Services page.")
                wrapMode: Text.WordWrap
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
            }

            Flow {
                Layout.fillWidth: true
                spacing: 5

                RippleButtonWithIcon {
                    materialIcon: "open_in_new"
                    mainText: Translation.tr("Open in Services")
                    onClicked: GlobalStates.openSettingsPage(7)
                }
            }
        }
    }
}
