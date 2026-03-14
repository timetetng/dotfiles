import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Services // 假设 Niri 在这里
import qs.config

Rectangle {
    id: root

    // --- 环境检测逻辑 ---
    readonly property string desktop: Quickshell.env("XDG_CURRENT_DESKTOP").toLowerCase()
    readonly property bool isHyprland: desktop.includes("hyprland")
    readonly property bool isNiri: desktop.includes("niri")

    // 动态选择数据源
    readonly property var workspaceModel: isHyprland ? Hyprland.workspaces : (isNiri ? Niri.workspaces : [])

    color: Colorsheme.background 
    radius: Sizes.cornerRadius
    implicitHeight: Sizes.barHeight
    implicitWidth: layout.width + 20
    property Item activeItem: null

    // 滑动高亮块 (保持不变)
    Rectangle {
        id: indicator
        z: 1
        x: layout.x + (root.activeItem ? root.activeItem.x : 0)
        y: layout.y + (root.activeItem ? root.activeItem.y : 0)
        width: root.activeItem ? root.activeItem.width : 0
        height: 26
        radius: 14
        color: Colorsheme.on_primary_container
        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 5

        Repeater {
            model: root.workspaceModel

            delegate: Item {
                id: delegateRoot

                // 统一属性映射：将不同 WM 的属性名归一化
                readonly property bool isActive: isHyprland ? modelData.active : model.isActive
                readonly property var workspaceId: isHyprland ? modelData.id : model.idx

                implicitWidth: isActive ? (numText.implicitWidth + 24) : (numText.implicitWidth + 12)
                implicitHeight: 26

                onIsActiveChanged: { if (isActive) root.activeItem = delegateRoot }
                Component.onCompleted: { if (isActive) root.activeItem = delegateRoot }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (isHyprland) {
                            modelData.activate()
                        } else if (isNiri) {
                            Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", workspaceId.toString()])
                        }
                    }
                }

                Text {
                    id: numText
                    anchors.centerIn: parent
                    text: workspaceId
                    font.bold: true
                    font.pixelSize: 14
                    // 如果是 Hyprland 额外支持 urgent 颜色
                    color: (isHyprland && modelData.urgent) ? "#ff5555" : (delegateRoot.isActive ? "#000000" : "#ffffff")
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }
    }
}
