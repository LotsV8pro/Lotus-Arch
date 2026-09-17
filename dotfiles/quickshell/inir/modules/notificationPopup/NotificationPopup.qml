pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Scope {
    id: notificationPopup

    property var excludedScreenNames: []
    property bool _surfaceRetained: false
    property bool _visualOpen: false
    property bool _hasPopups: false
    property var _frozenAppNames: []
    property var _frozenGroups: ({})

    readonly property int edgeMargin: Config.options?.notifications?.edgeMargin ?? 4
    readonly property bool barBottom: Config.options?.bar?.bottom ?? false

    readonly property var targetScreens: {
        const screens = Quickshell.screens
        const list = Config.options?.notifications?.screenList ?? []
        let selected = screens
        if (list && list.length > 0) {
            const matched = screens.filter(screen => {
                const screenName = screen?.name ?? ""
                return screenName.length > 0 && list.includes(screenName)
            })
            selected = matched.length > 0 ? matched : screens
        }
        return selected.filter(screen => !notificationPopup.excludedScreenNames.includes(screen?.name ?? ""))
    }

    function _reconcile(): void {
        if (notificationPopup._hasPopups) {
            releaseTimer.stop()
            notificationPopup._surfaceRetained = true
            notificationPopup._frozenAppNames = Notifications.popupAppNameList
            notificationPopup._frozenGroups = Notifications.popupGroupsByAppName
            Qt.callLater(() => {
                if (notificationPopup._hasPopups)
                    notificationPopup._visualOpen = true
            })
        } else if (notificationPopup._surfaceRetained) {
            notificationPopup._visualOpen = false
            releaseTimer.restart()
        }
    }

    on_HasPopupsChanged: notificationPopup._reconcile()
    on_SurfaceRetainedChanged: notificationPopup._reconcile()

    Timer {
        id: releaseTimer
        interval: Appearance.animation.elementMoveExit.duration + 60
        repeat: false
        onTriggered: {
            if (!notificationPopup._hasPopups)
                notificationPopup._surfaceRetained = false
        }
    }

    Connections {
        target: Notifications
        function onPopupListChanged() {
            Qt.callLater(() => {
                notificationPopup._hasPopups = Notifications.popupList.length > 0
                if (notificationPopup._hasPopups) {
                    notificationPopup._frozenAppNames = Notifications.popupAppNameList
                    notificationPopup._frozenGroups = Notifications.popupGroupsByAppName
                }
            })
        }
    }

    Component.onCompleted: {
        notificationPopup._hasPopups = Notifications.popupList.length > 0
        Notifications.ensureInitialized()
    }

    Loader {
        id: popupLoader
        active: notificationPopup._surfaceRetained

        sourceComponent: Variants {
            model: notificationPopup.targetScreens

            PanelWindow {
                id: popupWindow
                required property var modelData
                screen: modelData
                color: "transparent"

                WlrLayershell.namespace: "quickshell:notificationPopup"
                WlrLayershell.layer: WlrLayer.Overlay
                anchors {
                    top: !notificationPopup.barBottom
                    bottom: notificationPopup.barBottom
                }
                mask: Region {
                    item: cardArea
                }

                exclusionMode: ExclusionMode.Ignore
                exclusiveZone: 0
                margins {
                    top: Appearance.sizes.barHeight
                    bottom: Appearance.sizes.barHeight
                }

                width: Math.round(Math.min(
                    screen?.width ?? 1920,
                    360 + Appearance.sizes.spacingLarge * 2))
                height: cardArea.implicitHeight

                Item {
                    id: cardArea
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    implicitHeight: listview.contentHeight

                    property bool entersFromTop: !notificationPopup.barBottom
                    property real openProgress: notificationPopup._visualOpen ? 1 : 0
                    transformOrigin: entersFromTop ? Item.Top : Item.Bottom
                    scale: 0.94 + 0.06 * openProgress
                    opacity: openProgress
                    y: (1 - openProgress) * (entersFromTop ? -12 : 12)
                    visible: openProgress > 0.001

                    Behavior on openProgress {
                        enabled: Appearance.animationsEnabled
                        NumberAnimation {
                            duration: notificationPopup._visualOpen
                                ? Appearance.animation.elementMoveEnter.duration
                                : Appearance.animation.elementMoveExit.duration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: notificationPopup._visualOpen
                                ? Appearance.animation.elementMoveEnter.bezierCurve
                                : Appearance.animationCurves.standardAccel
                        }
                    }

                    NotificationListView {
                        id: listview
                        anchors.left: parent.left
                        anchors.right: parent.right
                        implicitHeight: contentHeight
                        clip: true
                        popup: true
                        popupAppNames: notificationPopup._frozenAppNames
                        popupGroups: notificationPopup._frozenGroups
                    }
                }
            }
        }
    }
}
