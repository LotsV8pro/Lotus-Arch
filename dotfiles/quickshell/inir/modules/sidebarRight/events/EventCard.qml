pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root
    
    required property var event
    property bool isExternal: false
    signal removeClicked()
    signal editClicked(var event)
    
    implicitHeight: cardContent.implicitHeight + 16
    
    // Style tokens
    readonly property color colPrimary: Appearance.angelEverywhere ? Appearance.angel.colPrimary
        : Appearance.inirEverywhere ? Appearance.inir.colPrimary : Appearance.colors.colPrimary
    readonly property color colText: Appearance.angelEverywhere ? Appearance.angel.colText
        : Appearance.inirEverywhere ? Appearance.inir.colText : Appearance.colors.colOnLayer1
    readonly property color colSubtext: Appearance.angelEverywhere ? Appearance.angel.colTextSecondary
        : Appearance.inirEverywhere ? Appearance.inir.colTextSecondary : Appearance.colors.colSubtext
    readonly property color colError: Appearance.angelEverywhere ? Appearance.angel.colError
        : Appearance.inirEverywhere ? (Appearance.inir?.colError ?? Appearance.colors.colError)
        : Appearance.colors.colError
    readonly property color colBadge: Appearance.angelEverywhere ? Appearance.angel.colBorderSubtle
        : Appearance.inirEverywhere ? ColorUtils.transparentize(Appearance.inir.colBorder, 0.5)
        : Appearance.auroraEverywhere ? (Appearance.aurora?.colSubSurface ?? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.90))
        : ColorUtils.transparentize(Appearance.colors.colPrimary, 0.90)

    // Source color for external events, priority color for local
    readonly property color indicatorColor: {
        if (root.isExternal) return root.event?.sourceColor ?? root.colPrimary
        switch (root.event?.priority ?? "normal") {
            case "high": return root.colError
            case "low": return root.colSubtext
            default: return root.colPrimary
        }
    }
    readonly property date eventDate: new Date(event.dateTime || event.startDate || "")
    readonly property date eventEndDate: root.event?.endDate ? new Date(root.event.endDate) : null
    // Re-evaluate now-dependent state on a timer so "Now" appears/disappears live
    property bool _nowTick: false
    Timer {
        interval: 30000
        repeat: true
        running: root.visible
        onTriggered: root._nowTick = !root._nowTick
    }
    readonly property bool isToday: {
        const _t = root._nowTick
        const now = new Date()
        return now.toDateString() === root.eventDate.toDateString()
    }
    readonly property bool isAllDay: root.event?.allDay ?? false
    readonly property bool isPast: {
        const _t = root._nowTick
        const now = new Date()
        return root.eventDate < now && !root.isNow
    }
    // In the middle of a running timed event right now
    readonly property bool isNow: {
        const _t = root._nowTick
        const now = new Date()
        if (root.isAllDay) return false
        if (root.eventDate > now) return false
        if (root.eventEndDate) return root.eventEndDate > now
        // Timed events without an explicit end default to ~1h window
        return now - root.eventDate < 60 * 60 * 1000
    }
    
    StyledRectangularShadow {
        target: cardBg
        visible: !Appearance.inirEverywhere && !Appearance.auroraEverywhere
    }
    
    Rectangle {
        id: cardBg
        anchors.fill: parent
        radius: Appearance.angelEverywhere ? Appearance.angel.roundingSmall
            : Appearance.inirEverywhere ? Appearance.inir.roundingSmall
            : Appearance.rounding.small
        color: {
            if (editMA.containsMouse && !root.isExternal) {
                if (Appearance.angelEverywhere) return Appearance.angel.colGlassCardHover
                if (Appearance.inirEverywhere) return Appearance.inir.colLayer2Hover
                if (Appearance.auroraEverywhere) return Appearance.aurora?.colSubSurface ?? Appearance.colors.colLayer2Hover
                return Appearance.colors.colLayer2Hover
            }
            if (Appearance.angelEverywhere) return Appearance.angel.colGlassCard
            if (Appearance.inirEverywhere) return Appearance.inir.colLayer2
            if (Appearance.auroraEverywhere) return Appearance.aurora?.colSubSurface ?? Appearance.colors.colLayer2
            return Appearance.m3colors?.m3surfaceContainerHigh ?? Appearance.colors.colLayer2
        }
        border.width: 1
        border.color: Appearance.angelEverywhere ? Appearance.angel.colBorder
            : Appearance.inirEverywhere ? Appearance.inir.colBorder
            : Appearance.auroraEverywhere ? ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.78)
            : ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.72)
        Behavior on color {
            enabled: Appearance.animationsEnabled
            animation: ColorAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
        }
        
        // Indicator bar (source color for external, priority for local)
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 4
            radius: parent.radius
            color: root.indicatorColor
        }
        
        RowLayout {
            id: cardContent
            anchors.fill: parent
            anchors.margins: 12
            anchors.leftMargin: 16
            spacing: 12
            
            // Category / source icon
            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 20
                color: ColorUtils.transparentize(root.indicatorColor, 0.85)
                
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: root.isExternal ? "cloud_sync" : Events.getCategoryIcon(root.event.category)
                    iconSize: 20
                    color: root.indicatorColor
                }
            }
            
            // Event info
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                StyledText {
                    Layout.fillWidth: true
                    text: root.event?.title ?? ""
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: root.colText
                    elide: Text.ElideRight
                }
                
                // Description or location
                StyledText {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: {
                        if (root.isExternal) return root.event?.location ?? root.event?.description ?? ""
                        return root.event?.description ?? ""
                    }
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: root.colSubtext
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.WordWrap
                }
                
                RowLayout {
                    spacing: 8
                    
                    // Date/time badge
                    Rectangle {
                        implicitHeight: dateTimeRow.implicitHeight + 6
                        implicitWidth: dateTimeRow.implicitWidth + 10
                        radius: height / 2
                        color: root.isNow || root.isToday
                            ? ColorUtils.transparentize(root.colPrimary, 0.85)
                            : root.colBadge
                        
                        RowLayout {
                            id: dateTimeRow
                            anchors.centerIn: parent
                            spacing: 4
                            
                            MaterialSymbol {
                                text: "schedule"
                                iconSize: 12
                                color: root.isNow || root.isToday ? root.colPrimary : root.colSubtext
                            }
                            
                            StyledText {
                                text: {
                                    if (root.isNow) return Translation.tr("Now") + " · " + Qt.formatTime(root.eventDate, "HH:mm")
                                    if (root.isAllDay) return Translation.tr("All day")
                                    if (root.isToday) return Translation.tr("Today") + " " + Qt.formatTime(root.eventDate, "HH:mm")
                                    const now = new Date()
                                    const tomorrow = new Date(now)
                                    tomorrow.setDate(tomorrow.getDate() + 1)
                                    if (root.eventDate.toDateString() === tomorrow.toDateString()) {
                                        return Translation.tr("Tomorrow") + " " + Qt.formatTime(root.eventDate, "HH:mm")
                                    }
                                    return Qt.formatDate(root.eventDate, "dd/MM") + " " + Qt.formatTime(root.eventDate, "HH:mm")
                                }
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                font.weight: root.isNow ? Font.Bold : Font.Medium
                                color: root.isNow || root.isToday ? root.colPrimary : root.colSubtext
                            }
                        }
                    }
                    
                    // Source / category badge
                    Rectangle {
                        implicitHeight: categoryText.implicitHeight + 6
                        implicitWidth: categoryText.implicitWidth + 12
                        radius: height / 2
                        color: root.isExternal
                            ? ColorUtils.transparentize(root.indicatorColor, 0.85)
                            : root.colBadge
                        
                        StyledText {
                            id: categoryText
                            anchors.centerIn: parent
                            text: {
                                if (root.isExternal) return root.event?.sourceName ?? Translation.tr("External")
                                switch (root.event?.category ?? "general") {
                                    case "birthday": return Translation.tr("Birthday")
                                    case "meeting": return Translation.tr("Meeting")
                                    case "deadline": return Translation.tr("Deadline")
                                    case "reminder": return Translation.tr("Reminder")
                                    default: return Translation.tr("General")
                                }
                            }
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: root.isExternal ? root.indicatorColor : root.colSubtext
                        }
                    }
                }
            }
            
            // Remove button (local events only)
            RippleButton {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                buttonRadius: 16
                visible: !root.isExternal
                colBackground: "transparent"
                colBackgroundHover: Appearance.angelEverywhere ? Appearance.angel.colGlassCardHover
                    : Appearance.inirEverywhere ? Appearance.inir.colLayer2Hover
                    : Appearance.colors.colLayer1Hover
                onClicked: root.removeClicked()
                
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "close"
                    iconSize: 16
                    color: root.colSubtext
                }
                
                StyledToolTip {
                    text: Translation.tr("Remove")
                }
            }
        }
        
        AngelPartialBorder {
            targetRadius: cardBg.radius
            visible: Appearance.angelEverywhere
        }
        
        // Click to edit (local only)
        MouseArea {
            id: editMA
            anchors.fill: parent
            z: -1
            hoverEnabled: !root.isExternal
            cursorShape: root.isExternal ? Qt.ArrowCursor : Qt.PointingHandCursor
            onClicked: {
                if (!root.isExternal) root.editClicked(root.event)
            }
        }
    }
}
