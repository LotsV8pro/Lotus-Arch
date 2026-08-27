import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

MouseArea {
    id: root

    visible: implicitWidth > 0
    implicitWidth: Updates.available && Updates.count > 0 ? pill.width : 0
    implicitHeight: Appearance.sizes.barHeight

    Behavior on implicitWidth {
        enabled: Appearance.animationsEnabled
        animation: NumberAnimation { duration: Appearance.animation.elementResize.duration; easing.type: Appearance.animation.elementResize.type; easing.bezierCurve: Appearance.animation.elementResize.bezierCurve }
    }

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    readonly property color accentColor: Appearance.angelEverywhere ? Appearance.angel.colPrimary
        : Appearance.inirEverywhere ? (Appearance.inir?.colAccent ?? Appearance.colors.colPrimary)
        : Appearance.auroraEverywhere ? (Appearance.aurora?.colAccent ?? Appearance.colors.colPrimary)
        : Appearance.colors.colPrimary

    onClicked: (mouse) => {
        if (mouse.button === Qt.RightButton) {
            Updates.refresh()
        } else {
            const cmd = Config.options?.apps?.update ?? "kitty -e sudo pacman -Syu"
            Quickshell.execDetached(["bash", "-c", cmd])
        }
    }

    Rectangle {
        id: pill
        anchors.centerIn: parent
        width: contentRow.implicitWidth + 16
        height: contentRow.implicitHeight + 8
        radius: Appearance.angelEverywhere ? Appearance.angel.roundingSmall : height / 2
        scale: root.pressed ? 0.93 : (root.containsMouse ? 1.03 : 1.0)
        color: {
            if (Updates.updateStronglyAdvised) {
                if (Appearance.angelEverywhere) return ColorUtils.transparentize(Appearance.angel.colWarning ?? Appearance.angel.colPrimary, 0.85)
                if (Appearance.inirEverywhere) return ColorUtils.transparentize(Appearance.inir?.colWarning ?? Appearance.colors.colPrimary, 0.85)
                if (Appearance.auroraEverywhere) return ColorUtils.transparentize(Appearance.aurora?.colWarning ?? Appearance.colors.colPrimary, 0.85)
                return ColorUtils.transparentize(Appearance.m3colors?.m3error ?? Appearance.colors.colPrimary, 0.85)
            }
            if (root.pressed) {
                if (Appearance.angelEverywhere) return Appearance.angel.colGlassCardActive
                if (Appearance.inirEverywhere) return Appearance.inir.colLayer2Active
                if (Appearance.auroraEverywhere) return Appearance.aurora.colSubSurfaceActive
                return Appearance.colors.colLayer1Active
            }
            if (root.containsMouse) {
                if (Appearance.angelEverywhere) return Appearance.angel.colGlassCardHover
                if (Appearance.inirEverywhere) return Appearance.inir.colLayer1Hover
                if (Appearance.auroraEverywhere) return Appearance.aurora.colSubSurface
                return Appearance.colors.colLayer1Hover
            }
            if (Appearance.angelEverywhere) return ColorUtils.transparentize(Appearance.angel.colPrimary, 0.85)
            if (Appearance.inirEverywhere) return ColorUtils.transparentize(Appearance.inir?.colAccent ?? Appearance.colors.colPrimary, 0.85)
            if (Appearance.auroraEverywhere) return ColorUtils.transparentize(Appearance.aurora?.colAccent ?? Appearance.colors.colPrimary, 0.85)
            return ColorUtils.transparentize(Appearance.colors.colPrimary, 0.88)
        }

        border.width: (Appearance.angelEverywhere || Appearance.inirEverywhere) ? 1 : 0
        border.color: Appearance.angelEverywhere ? Appearance.angel.colBorder
            : Appearance.inirEverywhere ? Appearance.inir.colBorder : "transparent"

        Behavior on color {
            enabled: Appearance.animationsEnabled
            animation: ColorAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
        }
        Behavior on scale {
            enabled: Appearance.animationsEnabled
            NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
        }
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: pill
        spacing: 5

        MaterialSymbol {
            text: "system_update"
            iconSize: Appearance.font.pixelSize.normal
            color: root.accentColor
            Layout.alignment: Qt.AlignVCenter

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: root.containsMouse
                NumberAnimation { to: 0.5; duration: 800; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
            }
        }

        StyledText {
            text: Updates.count.toString()
            visible: text !== "0"
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.DemiBold
            color: root.accentColor
            Layout.alignment: Qt.AlignVCenter
        }
    }

    StyledPopup {
        id: updatePopup
        hoverTarget: root

        Item {
            readonly property real minW: 200
            readonly property real maxW: 260
            anchors.centerIn: parent
            width: Math.min(Math.max(popupColumn.implicitWidth, minW), maxW)
            height: popupColumn.implicitHeight
            implicitWidth: width
            implicitHeight: height
            clip: true

            ColumnLayout {
                id: popupColumn
                width: parent.width
                spacing: 6

                Row {
                    spacing: 5

                    MaterialSymbol {
                        anchors.verticalCenter: parent.verticalCenter
                        fill: 0
                        font.weight: Font.Medium
                        text: "system_update"
                        iconSize: Appearance.font.pixelSize.large
                        color: Appearance.colors.colOnSurfaceVariant
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Translation.tr("System Updates")
                        font {
                            weight: Font.Medium
                            pixelSize: Appearance.font.pixelSize.normal
                        }
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }

                RowLayout {
                    spacing: 5
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0

                    MaterialSymbol {
                        text: "package_2"
                        iconSize: Appearance.font.pixelSize.large
                        color: Updates.updateStronglyAdvised
                            ? (Appearance.m3colors?.m3error ?? Appearance.colors.colOnSurfaceVariant)
                            : Appearance.colors.colOnSurfaceVariant
                    }
                    StyledText {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        horizontalAlignment: Text.AlignRight
                        text: Updates.count + " " + Translation.tr("package(s)")
                        color: Updates.updateStronglyAdvised
                            ? (Appearance.m3colors?.m3error ?? Appearance.colors.colOnSurfaceVariant)
                            : Appearance.colors.colOnSurfaceVariant
                        font.weight: Font.Medium
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    Layout.topMargin: 2
                    Layout.bottomMargin: 2
                    color: Appearance.angelEverywhere ? Appearance.angel.colBorderSubtle
                        : Appearance.inirEverywhere ? (Appearance.inir?.colBorder ?? Appearance.colors.colLayer0Border)
                        : Appearance.colors.colLayer0Border
                    opacity: 0.5
                }

                StyledText {
                    text: Translation.tr("Click to update · Right-click to refresh")
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colOnSurfaceVariant
                    opacity: 0.6
                }
            }
        }
    }
}
