import QtQuick
// 【重要】引入 Sizes.qml 所在的目录
// 假设 ClockContent.qml 在 qs/Modules/DynamicIsland/Clock/，你需要向上跳 3 级
import qs.config 

Item {
    id: root
    property var player 

    Row {
        anchors.centerIn: parent
        spacing: 8
        
        Text {
            id: timeTxt
            text: new Date().toLocaleString(Qt.locale("en_US"), "ddd dd MMM | hh:mm AP")
            
            color: "white"
            
            // ============================================================
            // 【核心修改】引用 Sizes 里的统一字体
            // ============================================================
            font.family: Sizes.fontFamily 
            
            // 也可以顺便引用统一的字号 (可选)
            // font.pixelSize: Sizes.fontSizeText 
            // 或者保持原来的 14
            font.pixelSize: 14
            
            font.bold: true
            
            anchors.verticalCenter: parent.verticalCenter
            
            Timer {
                interval: 1000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: timeTxt.text = new Date().toLocaleString(Qt.locale("en_US"), "ddd dd MMM | hh:mm AP")
            }
        }
    }
}
