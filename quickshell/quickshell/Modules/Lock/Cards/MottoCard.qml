import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    
    // 【修改】高度变矮
    width: 260
    height: 160

    color: "#1E1E1E"
    radius: 24

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20 // 边距稍微减小
        spacing: 0

        // 上引号 (缩小一点)
        Text {
            text: "“"
            color: "#444"
            font.pixelSize: 48 // 缩小
            font.family: "LXGW WenKai GB Screen"
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            Layout.preferredHeight: 30
        }

        // 正文
        Text {
            text: "休息一下，\n马上回来。"
            color: "#E0E0E0"
            font.family: "LXGW WenKai GB Screen"
            font.pixelSize: 24
            font.bold: true
            font.italic: true
            
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            lineHeight: 1.2
        }

        // 下引号
        Text {
            text: "”"
            color: "#444"
            font.pixelSize: 48
            font.family: "LXGW WenKai GB Screen"
            Layout.alignment: Qt.AlignRight | Qt.AlignBottom
            Layout.preferredHeight: 30
        }
    }
}
