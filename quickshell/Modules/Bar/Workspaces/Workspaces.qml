import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Hyprland
import qs.Services
import qs.config

Item {
    id: root

    // --- 环境检测 ---
    readonly property string desktop: Quickshell.env("XDG_CURRENT_DESKTOP").toLowerCase()
    readonly property bool isHyprland: desktop.includes("hyprland")
    readonly property bool isNiri: desktop.includes("niri")

    readonly property var workspaceModel: isHyprland ? Hyprland.workspaces : (isNiri ? Niri.workspaces : [])

    // 用于滑动高亮块（Hyprland 模式下使用）
    property Item activeItem: null

    implicitHeight: 36
    implicitWidth: layout.width + 24

    // --- 1. 背景矩形（不可见，作为 MultiEffect 渲染源）---
    Rectangle {
        id: bgRect
        anchors.fill: parent
        color: Colorscheme.background
        radius: height / 2
        visible: false
    }

    // --- 2. MultiEffect：渲染背景 + 外部阴影 ---
    MultiEffect {
        source: bgRect
        anchors.fill: bgRect
        shadowEnabled: true
        shadowColor: Qt.alpha(Colorscheme.shadow, 0.4)
        shadowBlur: 0.8
        shadowVerticalOffset: 3
        shadowHorizontalOffset: 0
    }

    // --- 3. Hyprland 模式：滑动高亮块 ---
    Rectangle {
        id: indicator
        visible: root.isHyprland
        z: 1
        x: layout.x + (root.activeItem ? root.activeItem.x : 0)
        y: layout.y + (root.activeItem ? root.activeItem.y : 0)
        width: root.activeItem ? root.activeItem.width : 0
        height: 26
        radius: 13
        color: Colorscheme.on_primary_container
        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    }

    // --- 4. 工作区列表 ---
    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: root.isHyprland ? 5 : 8

        Repeater {
            model: root.workspaceModel

            delegate: Item {
                id: delegateRoot

                // 统一属性映射
                readonly property bool isActive: root.isHyprland ? modelData.active : model.isActive
                readonly property var workspaceId: root.isHyprland ? modelData.id : model.idx
                readonly property bool isHovered: mouseArea.containsMouse

                // hasWindows 仅 Niri 模式下使用
                property bool hasWindows: false

                function checkWindows() {
                    if (!root.isNiri) return;
                    let found = false;
                    for (let i = 0; i < Niri.windows.count; i++) {
                        if (Niri.windows.get(i).workspaceId === model.wsId) {
                            found = true;
                            break;
                        }
                    }
                    hasWindows = found;
                }

                Connections {
                    target: root.isNiri ? Niri : null
                    function onWindowsUpdated() { delegateRoot.checkWindows() }
                }

                Component.onCompleted: {
                    checkWindows();
                    if (isActive) root.activeItem = delegateRoot;
                }

                onIsActiveChanged: {
                    if (isActive) root.activeItem = delegateRoot;
                }

                // --- Hyprland 模式：数字标签宽度 ---
                // --- Niri 模式：圆点宽度 ---
                implicitWidth: root.isHyprland
                    ? (isActive ? (numText.implicitWidth + 24) : (numText.implicitWidth + 12))
                    : ((isActive || isHovered) ? 32 : 12)
                implicitHeight: root.isHyprland ? 26 : 12

                Behavior on implicitWidth {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }

                // --- Hyprland 模式：数字文字 ---
                Text {
                    id: numText
                    visible: root.isHyprland
                    anchors.centerIn: parent
                    text: delegateRoot.workspaceId
                    font.bold: true
                    font.pixelSize: 14
                    color: (root.isHyprland && modelData.urgent)
                        ? Colorscheme.error
                        : (delegateRoot.isActive ? Colorscheme.on_primary : Colorscheme.on_surface)
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                // --- Niri 模式：圆点矩形 ---
                Rectangle {
                    visible: root.isNiri
                    anchors.centerIn: parent
                    width: parent.implicitWidth
                    height: parent.implicitHeight
                    radius: height / 2
                    color: delegateRoot.isActive    ? Colorscheme.primary
                         : delegateRoot.hasWindows  ? Colorscheme.on_surface
                         : delegateRoot.isHovered   ? Colorscheme.surface_variant
                         : Colorscheme.surface_container_highest
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.isHyprland) {
                            modelData.activate()
                        } else if (root.isNiri) {
                            Quickshell.execDetached([
                                "niri", "msg", "action", "focus-workspace",
                                delegateRoot.workspaceId.toString()
                            ])
                        }
                    }
                }
            }
        }
    }
}

