import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs.Data as Dat

Scope {
    id: root

    ListModel {
        id: popups
    }

    function dismiss(index, notif) {
        if (notif)
            notif.expire();
        popups.remove(index);
    }

    NotificationServer {
        id: server
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        persistenceSupported: false
        keepOnReload: false

        onNotification: notification => {
            popups.append({
                "ref": notification,
                "appName": notification.appName || "",
                "summary": notification.summary || "",
                "body": notification.body || ""
            });
            Qt.callLater(() => {
                // schedule auto-dismiss honoring the sender's timeout
                const idx = popups.count - 1;
                expireTimer.restart(idx, Math.max(notification.expireTimeout, 4000));
            });
        }
    }

    Timer {
        id: expireTimer
        property int targetIndex: -1
        interval: 5000
        onTriggered: {
            if (targetIndex >= 0 && targetIndex < popups.count)
                root.dismiss(targetIndex, popups.get(targetIndex).ref);
            targetIndex = -1;
        }
        function restart(idx, ms) {
            targetIndex = idx;
            interval = ms;
            restart();
        }
    }

    Variants {
        model: Quickshell.screens
        Scope {
            id: scopeRoot
            required property ShellScreen modelData

            WlrLayershell {
                id: layer
                required property ShellScreen modelData
                anchors.top: true
                anchors.left: true
                anchors.right: true
                anchors.bottom: true
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                focusable: false
                keyboardFocus: WlrKeyboardFocus.None
                layer: WlrLayer.Top
                namespace: "lotus.notifications"
                screen: scopeRoot.modelData

                visible: popups.count > 0

                Column {
                    id: stack
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 18
                    anchors.rightMargin: 22
                    spacing: 10
                    width: 380

                    Repeater {
                        model: popups

                        Rectangle {
                            id: card
                            required property var model
                            required property int index
                            readonly property var notifRef: model.ref ?? null

                            width: parent.width
                            height: cardContent.implicitHeight + 28
                            radius: 14
                            color: Qt.rgba(Dat.Colors.surface.r, Dat.Colors.surface.g, Dat.Colors.surface.b, 0.92)
                            border.width: 1
                            border.color: Qt.rgba(Dat.Colors.primary.r, Dat.Colors.primary.g, Dat.Colors.primary.b, 0.4)

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.margins: 9
                                implicitWidth: 4
                                radius: 2
                                color: Dat.Colors.primary
                            }

                            Column {
                                id: cardContent
                                anchors.centerIn: parent
                                width: parent.width - 40
                                spacing: 3

                                Text {
                                    width: parent.width
                                    text: card.model.appName
                                    font.family: "Montserrat"
                                    font.pixelSize: 11
                                    font.letterSpacing: 1.2
                                    elide: Text.ElideRight
                                    color: Dat.Colors.primary
                                    visible: text !== ""
                                }
                                Text {
                                    width: parent.width
                                    text: card.model.summary
                                    font.family: "Montserrat"
                                    font.weight: Font.DemiBold
                                    font.pixelSize: 15
                                    wrapMode: Text.WordWrap
                                    color: Dat.Colors.foreground
                                }
                                Text {
                                    width: parent.width
                                    text: card.model.body
                                    font.family: "Montserrat"
                                    font.pixelSize: 13
                                    wrapMode: Text.WordWrap
                                    color: Dat.Colors.foregroundDim
                                    visible: text !== ""
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.dismiss(card.index, card.notifRef)
                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 160
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
