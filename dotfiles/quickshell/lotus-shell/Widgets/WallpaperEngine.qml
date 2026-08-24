import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Data as Dat

WlrLayershell {
    id: root

    required property ShellScreen modelData
    property real mouseOffsetX: 0.0
    property real mouseOffsetY: 0.0

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    layer: WlrLayer.Bottom
    namespace: "lotus.wallpaper"
    screen: modelData

    Behavior on mouseOffsetX {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }
    Behavior on mouseOffsetY {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    ShaderEffect {
        anchors.fill: parent

        property real u_time: 0
        property vector2d u_mouse: Qt.vector2d(root.mouseOffsetX, root.mouseOffsetY)
        property vector2d u_res: Qt.vector2d(width, height)
        property color u_bg: Qt.color(Dat.Colors.background)
        property color u_p1: Qt.color(Dat.Colors.primary)
        property color u_p2: Qt.color(Dat.Colors.accentDim)

        NumberAnimation on u_time {
            from: 0
            to: 100000
            duration: 100000000
            loops: Animation.Infinite
            running: true
        }

        vertexShader: Qt.resolvedUrl("../Assets/shaders/wallpaper.vert.qsb")
        fragmentShader: Qt.resolvedUrl("../Assets/shaders/wallpaper.frag.qsb")
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onPositionChanged: mouse => {
            root.mouseOffsetX = (mouse.x / width - 0.5) * 2.0;
            root.mouseOffsetY = (mouse.y / height - 0.5) * 2.0;
        }
    }
}
