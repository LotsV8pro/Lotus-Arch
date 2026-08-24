import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Data as Dat

WlrLayershell {
    id: root

    required property ShellScreen modelData
    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    layer: WlrLayer.Top
    namespace: "lotus.clock"
    screen: modelData

    Rectangle {
        id: pill
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 18
        anchors.leftMargin: 22
        implicitWidth: clockColumn.implicitWidth + 46
        implicitHeight: clockColumn.implicitHeight + 26
        radius: 16
        color: Qt.rgba(
            Dat.Colors.surface.r,
            Dat.Colors.surface.g,
            Dat.Colors.surface.b,
            0.82)
        border.width: 1
        border.color: Qt.rgba(Dat.Colors.primary.r, Dat.Colors.primary.g, Dat.Colors.primary.b, 0.35)

        Rectangle {
            id: accentBar
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 10
            implicitWidth: 4
            radius: 2
            color: Dat.Colors.primary
        }

        Column {
            id: clockColumn
            anchors.centerIn: parent
            spacing: 1

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(Dat.Time.now, "HH:mm")
                font.family: "Montserrat"
                font.weight: Font.Bold
                font.pixelSize: 34
                color: Dat.Colors.foreground
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(Dat.Time.now, "ddd d MMM")
                font.family: "Montserrat"
                font.pixelSize: 13
                font.letterSpacing: 1.5
                color: Dat.Colors.primary
            }
        }
    }
}
