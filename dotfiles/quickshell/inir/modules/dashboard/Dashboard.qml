import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    property bool _presentedOpen: false
    property var targetScreen: null
    readonly property real screenWidth: panelRoot.screen?.width ?? 1920
    readonly property real screenHeight: panelRoot.screen?.height ?? 1080
    readonly property real safePadding: Math.max(
        Appearance.sizes.hyprlandGapsOut * 2,
        Math.round(Math.min(screenWidth, screenHeight) * 0.02)
    )
    readonly property real barReservedSpace: Appearance.sizes.baseBarHeight + Appearance.sizes.hyprlandGapsOut * 2
    readonly property real topReservedSpace: safePadding
        + (!(Config.options?.bar?.bottom ?? false) ? barReservedSpace : 0)
    readonly property real bottomReservedSpace: safePadding
        + ((Config.options?.bar?.bottom ?? false) ? barReservedSpace : 0)
    readonly property real availablePanelHeight: Math.max(360, screenHeight - topReservedSpace - bottomReservedSpace)
    readonly property real availablePanelWidth: Math.max(480, screenWidth - safePadding * 2)
    readonly property real widthRatio: Math.min(0.9, Math.max(0.4, Config.options?.dashboard?.widthRatio ?? 0.62))
    readonly property real panelWidth: Math.round(Math.min(availablePanelWidth, screenWidth * widthRatio))
    readonly property real panelHeight: Math.round(Math.min(availablePanelHeight, 860))

    PanelWindow {
        id: panelRoot

        // Bound (never manual assignment): the window maps/unmaps exactly with
        // the presented state, so a fast open/close can't leave a transparent
        // "ghost window" mapped and eating input. All open/close animations are
        // played by niri's layer-open/layer-close rules on this surface.
        visible: root._presentedOpen

        // Pin to the output the user was on when opening (resolved in the open
        // handler), so the panel doesn't flip between monitors across opens.
        screen: root.targetScreen

        Component.onCompleted: {
            if (GlobalStates.dashboardOpen) {
                const outputName = NiriService.currentOutput ?? ""
                root.targetScreen = Quickshell.screens.find(s => s.name === outputName)
                    ?? GlobalStates.primaryScreen ?? null
                Qt.callLater(() => { root._presentedOpen = GlobalStates.dashboardOpen })
            }
        }

        Connections {
            target: GlobalStates
            function onDashboardOpenChanged() {
                if (GlobalStates.dashboardOpen) {
                    // Resolve a stable target screen (the output the user is on)
                    // before showing, so the panel maps on the display it was
                    // closed on and doesn't flip outputs between opens/restarts.
                    const outputName = NiriService.currentOutput ?? ""
                    root.targetScreen = Quickshell.screens.find(s => s.name === outputName)
                        ?? GlobalStates.primaryScreen ?? null
                    // Defer presentation one frame so the surface maps in a
                    // built state; niri's layer-open rule plays the reveal.
                    Qt.callLater(() => {
                        root._presentedOpen = GlobalStates.dashboardOpen
                    })
                } else {
                    // Unmap immediately: niri's layer-close rule plays the iris
                    // over the final frame, so no QML close animation is needed.
                    root._presentedOpen = false
                }
            }
        }

        function hide() {
            GlobalStates.dashboardOpen = false
        }

        exclusiveZone: 0
        implicitWidth: screen?.width ?? 1920
        implicitHeight: screen?.height ?? 1080
        WlrLayershell.namespace: "quickshell:dashboard"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.dashboardOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"

        anchors {
            top: true
            right: true
            bottom: true
            left: true
        }

        CompositorFocusGrab {
            id: grab
            windows: [ panelRoot ]
            active: CompositorService.isHyprland && panelRoot.visible
            onCleared: () => {
                if (!active) panelRoot.hide()
            }
        }

        // Backdrop click to close
        MouseArea {
            anchors.fill: parent
            onClicked: mouse => {
                const localPos = mapToItem(contentLoader, mouse.x, mouse.y)
                if (localPos.x < 0 || localPos.x > contentLoader.width
                        || localPos.y < 0 || localPos.y > contentLoader.height) {
                    panelRoot.hide()
                }
            }
        }

        Loader {
            id: contentLoader
            active: GlobalStates.dashboardOpen
                || (Config.options?.dashboard?.keepLoaded ?? false)

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: Math.round((root.topReservedSpace - root.bottomReservedSpace) / 2)

            width: root.panelWidth
            height: root.panelHeight

            focus: GlobalStates.dashboardOpen
            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    if (contentLoader.item?.detailOpen)
                        contentLoader.item.closeDetail()
                    else
                        panelRoot.hide()
                    event.accepted = true
                }
            }

            sourceComponent: DashboardContent {
                screenWidth: panelRoot.screen?.width ?? 1920
                screenHeight: panelRoot.screen?.height ?? 1080
            }
        }
    }

}
