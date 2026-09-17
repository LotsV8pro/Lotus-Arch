import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

Item {
    id: root
    signal requestExpand()
    property int currentTab: 0
    property var tabButtonList: [{"icon": "checklist", "name": Translation.tr("Unfinished")}, {"name": Translation.tr("Done"), "icon": "check_circle"}]
    property bool showAddDialog: false
    property int dialogMargins: 20
    property int fabSize: 48
    property int fabMargins: 14
    property int editButtonSize: 40
    // The internal expand button is redundant where a parent already offers
    // "open full" (dashboard compact card + full-detail card), so callers hide
    // it there. The sidebar keeps it (it is the real expand affordance there).
    property bool showExpandButton: true
    // Reserve a bottom strip for the FAB + txt-edit buttons so they never float
    // over the list rows (their complete/delete actions stay visible/clickable).
    property int bottomActionHeight: root.fabMargins + root.fabSize + 4
    // Qt's TabBar/SwipeView can resolve to tab 1 once during first layout
    // (their currentIndex binding briefly breaks and a stale handler writes
    // currentTab=1), so the widget would open on "Done" instead of "Unfinished".
    // Also, once QQC writes currentIndex internally the QML binding is dead, so
    // every change is propagated EXPLICITLY through _syncToTab; never rely on
    // the `currentIndex: currentTab` binding staying alive.
    property bool _startupSteady: false
    function _syncToTab(index): void {
        root.currentTab = index
        if (swipeView) swipeView.currentIndex = index
        if (tabBar) tabBar.currentIndex = index
    }
    Timer {
        id: tabSteadier
        interval: 500
        repeat: false
        onTriggered: {
            // Re-pin to Unfinished after the initial layout settles, then allow
            // user-driven tab/swipe writes (guards use _startupSteady).
            root._syncToTab(0)
            root._startupSteady = true
        }
    }
    Component.onCompleted: tabSteadier.start()

    Keys.onPressed: (event) => {
        if ((event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) && event.modifiers === Qt.NoModifier) {
            if (event.key === Qt.Key_PageDown) {
                root._syncToTab(Math.min(currentTab + 1, root.tabButtonList.length - 1))
            } else if (event.key === Qt.Key_PageUp) {
                root._syncToTab(Math.max(currentTab - 1, 0))
            }
            event.accepted = true;
        }
        // Open add dialog on "N" (any modifiers)
        else if (event.key === Qt.Key_N) {
            root.showAddDialog = true
            event.accepted = true;
        }
        // Close dialog on Esc if open
        else if (event.key === Qt.Key_Escape && root.showAddDialog) {
            root.showAddDialog = false
            event.accepted = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Item {
            id: todoHeader
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(tabBar.implicitHeight, expandViewButton.implicitHeight)

            SecondaryTabBar {
                id: tabBar
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: root.showExpandButton ? expandViewButton.left : parent.right
                anchors.rightMargin: 6
                currentIndex: currentTab
                onCurrentIndexChanged: {
                    if (root._startupSteady && root.currentTab !== currentIndex)
                        root._syncToTab(currentIndex)
                }

                background: Item {
                    WheelHandler {
                        onWheel: (event) => {
                            if (event.angleDelta.y < 0)
                                tabBar.currentIndex = Math.min(tabBar.currentIndex + 1, root.tabButtonList.length - 1)
                            else if (event.angleDelta.y > 0)
                                tabBar.currentIndex = Math.max(tabBar.currentIndex - 1, 0)
                        }
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    }
                }

                Repeater {
                    model: root.tabButtonList
                    delegate: SecondaryTabButton {
                        selected: (index == currentTab)
                        buttonText: modelData.name
                        buttonIcon: modelData.icon
                    }
                }
            }

            RippleButton {
                id: expandViewButton
                anchors.top: parent.top
                anchors.right: parent.right
                z: 5
                visible: root.showExpandButton
                implicitWidth: 32
                implicitHeight: 32
                buttonRadius: Appearance.rounding.full
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer2Hover
                onClicked: root.requestExpand()
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "open_in_full"
                    iconSize: 17
                    color: Appearance.colors.colPrimary
                }
                StyledToolTip { text: Translation.tr("Open full to-do view") }
            }
        }

        Item { // Tab indicator
            id: tabIndicator
            Layout.fillWidth: true
            height: 3
            property bool enableIndicatorAnimation: false
            Connections {
                target: root
                function onCurrentTabChanged() {
                    tabIndicator.enableIndicatorAnimation = true
                }
            }

            Rectangle {
                id: indicator
                property int tabCount: root.tabButtonList.length
                property real fullTabSize: root.width / tabCount;
                property real targetWidth: tabBar?.contentItem?.children[0]?.children[tabBar.currentIndex]?.tabContentWidth ?? 0

                implicitWidth: targetWidth
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }

                x: tabBar.currentIndex * fullTabSize + (fullTabSize - targetWidth) / 2

                color: Appearance.colors.colPrimary
                radius: Math.min(width, height) / 2

                Behavior on x {
                    enabled: tabIndicator.enableIndicatorAnimation && Appearance.animationsEnabled
                    animation: NumberAnimation { duration: Appearance.animation.elementMove.duration; easing.type: Appearance.animation.elementMove.type; easing.bezierCurve: Appearance.animation.elementMove.bezierCurve }
                }

                Behavior on implicitWidth {
                    enabled: tabIndicator.enableIndicatorAnimation && Appearance.animationsEnabled
                    animation: NumberAnimation { duration: Appearance.animation.elementMove.duration; easing.type: Appearance.animation.elementMove.type; easing.bezierCurve: Appearance.animation.elementMove.bezierCurve }
                }
            }
        }

        Rectangle { // Tabbar bottom border — removed: only the colored active
            // indicator should read (matches pomodoro). No full-width grey track.
            id: tabBarBottomBorder
            Layout.fillWidth: true
            height: 1
            color: "transparent"
        }

        SwipeView {
            id: swipeView
            Layout.topMargin: 10
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10
            clip: true
            currentIndex: currentTab
            onCurrentIndexChanged: {
                if (!root._startupSteady) return
                tabIndicator.enableIndicatorAnimation = true
                if (root.currentTab !== currentIndex)
                    root._syncToTab(currentIndex)
            }

            // To Do tab
            TaskList {
                listBottomPadding: 6
                emptyPlaceholderIcon: "check_circle"
                emptyPlaceholderText: Translation.tr("Nothing here!")
                emptyMascotPose: "todo-done"
                taskList: Todo.list
                    .map(function(item, i) { return Object.assign({}, item, {originalIndex: i}); })
                    .filter(function(item) { return !item.done; })
            }
            TaskList {
                listBottomPadding: 6
                emptyPlaceholderIcon: "checklist"
                emptyPlaceholderText: Translation.tr("Finished tasks will go here")
                emptyMascotPose: "success-celebrate"
                taskList: Todo.list
                    .map(function(item, i) { return Object.assign({}, item, {originalIndex: i}); })
                    .filter(function(item) { return item.done; })
            }

        }

        // Bottom strip holding the FAB + txt-edit buttons. Lives in the layout
        // (below the list) so the buttons never overlap the task rows.
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.bottomActionHeight
        }
    }

    // Open txt in editor
    StyledRectangularShadow {
        target: editButton
        radius: editButton.buttonRadius
        blur: 0.6 * Appearance.sizes.elevationMargin
    }
    FloatingActionButton {
        id: editButton
        anchors.right: fabButton.left
        anchors.rightMargin: 8
        anchors.bottom: fabButton.bottom
        baseSize: root.editButtonSize
        onClicked: ShellExec.execDetachedArgs(["xdg-open", Directories.todoTxtPath], "Open todo file")
        iconText: "edit_note"
    }

    // + FAB
    StyledRectangularShadow {
        target: fabButton
        radius: fabButton.buttonRadius
        blur: 0.6 * Appearance.sizes.elevationMargin
    }
    FloatingActionButton {
        id: fabButton
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: root.fabMargins
        anchors.bottomMargin: root.fabMargins

        onClicked: root.showAddDialog = true
        iconText: "add"
    }

    Item {
        anchors.fill: parent
        z: 9999

        visible: opacity > 0
        opacity: root.showAddDialog ? 1 : 0
        Behavior on opacity {
            enabled: Appearance.animationsEnabled
            NumberAnimation { 
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
            }
        }

        onVisibleChanged: {
            if (!visible) {
                todoInput.text = ""
                fabButton.focus = true
            }
        }

        Rectangle { // Scrim
            anchors.fill: parent
            radius: Appearance.rounding.small
            color: Appearance.colors.colScrim
            MouseArea {
                hoverEnabled: true
                anchors.fill: parent
                preventStealing: true
                propagateComposedEvents: false
            }
        }

        Rectangle { // The dialog
            id: dialog
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: root.dialogMargins
            implicitHeight: dialogColumnLayout.implicitHeight

            color: Appearance.auroraEverywhere ? Appearance.aurora.colPopupSurface : Appearance.colors.colSurfaceContainerHigh
            radius: Appearance.rounding.normal

            function addTask() {
                if (todoInput.text.length > 0) {
                    Todo.addTask(todoInput.text)
                    todoInput.text = ""
                    root.showAddDialog = false
                    root._syncToTab(0) // Show unfinished tasks
                }
            }

            ColumnLayout {
                id: dialogColumnLayout
                anchors.fill: parent
                spacing: 16

                StyledText {
                    Layout.topMargin: 16
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    Layout.alignment: Qt.AlignLeft
                    color: Appearance.colors.colOnSurface
                    font.pixelSize: Appearance.font.pixelSize.larger
                    text: Translation.tr("Add task")
                }

                TextField {
                    id: todoInput
                    Layout.fillWidth: true
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    padding: 10
                    color: activeFocus ? Appearance.colors.colOnSurface : Appearance.colors.colOnSurfaceVariant
                    renderType: Text.NativeRendering
                    selectedTextColor: Appearance.colors.colOnSecondaryContainer
                    selectionColor: Appearance.colors.colSecondaryContainer
                    placeholderText: Translation.tr("Task description")
                    placeholderTextColor: Appearance.colors.colOutline
                    focus: root.showAddDialog
                    onAccepted: dialog.addTask()

                    background: Rectangle {
                        anchors.fill: parent
                        radius: Appearance.rounding.verysmall
                        border.width: 2
                        border.color: todoInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colOutline
                        color: "transparent"
                    }

                    cursorDelegate: Rectangle {
                        width: 1
                        color: todoInput.activeFocus ? Appearance.colors.colPrimary : "transparent"
                        radius: 1
                    }
                }

                RowLayout {
                    Layout.bottomMargin: 16
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    Layout.alignment: Qt.AlignRight
                    spacing: 5

                    DialogButton {
                        buttonText: Translation.tr("Cancel")
                        onClicked: root.showAddDialog = false
                    }
                    DialogButton {
                        buttonText: Translation.tr("Add")
                        enabled: todoInput.text.length > 0
                        onClicked: dialog.addTask()
                    }
                }
            }
        }
    }
}
