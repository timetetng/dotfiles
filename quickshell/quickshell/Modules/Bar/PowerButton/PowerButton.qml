import QtQuick
import Quickshell
import qs.config

Rectangle {
    id: root

    // --- 样式设定 ---
    color: Colorsheme.error 
    
// 设定固定的宽高，让它变小且精致
    implicitWidth: 36
    implicitHeight: 36
    
    // 如果你想要完美的圆形，可以用 height / 2；如果你想保持圆角矩形，就保留 Sizes.cornerRadius
    radius: height / 2

    // --- 交互区域 ---
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        
        // 左键点击运行 wlogout 命令
        onClicked: {
            Quickshell.execDetached(["wlogout", "-p", "layer-shell", "-b", "2"])
        }
    }

    // --- 图标内容 ---
    Text {
        id: icon
        anchors.centerIn: parent
        
        text: "⏻"
        font.pixelSize: 15 //稍微大一点，突出电源键
        font.bold: true
        
        color: Colorsheme.background 
    }
}
