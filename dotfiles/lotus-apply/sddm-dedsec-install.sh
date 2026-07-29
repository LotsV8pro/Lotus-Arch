#!/usr/bin/env bash
# LOTUS SDDM Theme Installer
# Run with: sudo ./sddm-lotus-install.sh

set -euo pipefail

THEME_DIR="/usr/share/sddm/themes/lotus"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[*] Installing Lotus SDDM theme..."

# Create theme directory
mkdir -p "$THEME_DIR"

# Create theme metadata
cat > "$THEME_DIR/metadata.desktop" << 'EOF'
[Sddm Greeter Theme]
Name=Lotus
Description=Watch Dogs / ctOS Infiltration Style
Author=glimp
Copyright=GPL-3.0
Type=sddm-theme
Version=1.0
Website=https://github.com/LotsV8pro
WebsiteName=https://github.com/LotsV8pro
Qt5Theme=true
Screenshots=preview.png
EOF

# Create theme config
cat > "$THEME_DIR/theme.conf" << 'EOF'
[General]
background=/usr/share/sddm/themes/lotus/background.png
color=#00FF41
font=JetBrainsMono Nerd Font
fontSize=14
EOF

# Create QML theme
cat > "$THEME_DIR/Main.qml" << 'QMLEOF'
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    color: "#0a0a0a"
    width: 1920
    height: 1080

    // Scanline overlay
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        z: 100

        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.strokeStyle = Qt.rgba(0, 1, 0.25, 0.03)
                ctx.lineWidth = 1
                for (var y = 0; y < height; y += 4) {
                    ctx.beginPath()
                    ctx.moveTo(0, y)
                    ctx.lineTo(width, y)
                    ctx.stroke()
                }
            }
        }
    }

    // Lotus logo
    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -120
        text: "LOTUS"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 48
        font.bold: true
        color: "#00FF41"
        z: 10

        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { to: 0.7; duration: 2000 }
            NumberAnimation { to: 1.0; duration: 2000 }
        }
    }

    // Subtitle
    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -70
        text: "// ACCESS POINT"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        color: "#00aa2a"
        z: 10
    }

    // Login container
    Column {
        anchors.centerIn: parent
        spacing: 12
        z: 10

        // Username
        Rectangle {
            width: 320
            height: 44
            color: "#0d0d0d"
            border.color: usernameInput.activeFocus ? "#00FF41" : "#00FF4133"
            border.width: 1

            TextInput {
                id: usernameInput
                anchors.fill: parent
                anchors.margins: 12
                color: "#00FF41"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                clip: true
                focus: true

                Text {
                    anchors.fill: parent
                    anchors.verticalCenter: parent.verticalCenter
                    text: "> USERNAME"
                    color: "#00FF4144"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    visible: !usernameInput.text && !usernameInput.activeFocus
                }
            }
        }

        // Password
        Rectangle {
            width: 320
            height: 44
            color: "#0d0d0d"
            border.color: passwordInput.activeFocus ? "#00FF41" : "#00FF4133"
            border.width: 1

            TextInput {
                id: passwordInput
                anchors.fill: parent
                anchors.margins: 12
                color: "#00FF41"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                echoMode: TextInput.Password
                clip: true

                Text {
                    anchors.fill: parent
                    anchors.verticalCenter: parent.verticalCenter
                    text: "> ACCESS CODE"
                    color: "#00FF4144"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    visible: !passwordInput.text && !passwordInput.activeFocus
                }
            }
        }

        // Login button
        Rectangle {
            width: 320
            height: 40
            color: loginMouseArea.containsMouse ? "#00FF41" : "#00FF4122"
            border.color: "#00FF41"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "> AUTHENTICATE"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                font.bold: true
                color: loginMouseArea.containsMouse ? "#0a0a0a" : "#00FF41"
            }

            MouseArea {
                id: loginMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: sddm.login(usernameInput.text, passwordInput.text, sessionIndicator.text)
            }
        }

        // Session selector
        Row {
            spacing: 8
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                text: "SESSION:"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                color: "#00aa2a"
            }

            Text {
                id: sessionIndicator
                text: "Hyprland"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                color: "#00FF41"
            }
        }
    }

    // Bottom status bar
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 30
        color: "#0d0d0d"
        border.color: "#00FF4122"
        border.width: 1

        Row {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 16

            Text {
                text: "ctOS v2.0"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                color: "#00aa2a"
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "// LOTUS INFILTRATION"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                color: "#00FF4166"
                anchors.verticalCenter: parent.verticalCenter
            }

            Item { Layout.fillWidth: true }

            Text {
                text: Qt.formatDateTime(new Date(), "yyyy.MM.dd // HH:mm:ss")
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                color: "#00aa2a"
                anchors.verticalCenter: parent.verticalCenter

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: parent.text = Qt.formatDateTime(new Date(), "yyyy.MM.dd // HH:mm:ss")
                }
            }
        }
    }
}
QMLEOF

echo "[+] Lotus SDDM theme installed to $THEME_DIR"
echo "[*] Set theme in /etc/sddm.conf:"
echo "    [Theme]"
echo "    Current=lotus"
