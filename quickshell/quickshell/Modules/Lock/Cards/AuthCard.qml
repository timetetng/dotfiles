import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: root
    
    // 这个卡片需要接收 context
    required property var context

    width: 320
    height: 65 
    color: "#1E1E1E"
    radius: 24
    
    border.color: context.showFailure ? "#ff4444" : (input.activeFocus ? "#555" : "transparent")
    border.width: 1

    // 错误震动动画
    SequentialAnimation on x {
        id: shakeAnim
        running: context.showFailure
        loops: 3
        PropertyAnimation { to: x - 10; duration: 50 }
        PropertyAnimation { to: x + 10; duration: 50 }
        onFinished: x = parent.x // 复位逻辑由 Layout 处理，这里稍微震动即可
    }

    TextInput {
        id: input
        anchors.fill: parent
        anchors.margins: 20
        
        color: "white"
        font.pixelSize: 18
        font.family: "LXGW WenKai GB Screen"
        
        echoMode: TextInput.Password
        passwordCharacter: "•"
        
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: TextInput.AlignLeft // 靠左输入比较像终端
        
        focus: true
        enabled: !context.unlockInProgress

        // 占位符
        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Password..."
            color: "#666"
            visible: !input.text && !input.activeFocus
            font.pixelSize: 16
            font.family: "LXGW WenKai GB Screen"
        }
        
        // 提示符 (像终端一样)
        Text {
            anchors.right: parent.left
            anchors.rightMargin: 5
            anchors.verticalCenter: parent.verticalCenter
            text: ">"
            color: "#4EC9B0" // 绿色箭头
            visible: input.activeFocus || input.text.length > 0
        }

        onTextChanged: context.currentText = text
        onAccepted: context.tryUnlock()
        
        Connections {
            target: context
            function onCurrentTextChanged() {
                if (context.currentText === "") input.text = ""
            }
        }
    }
    
    // 加载圈
    BusyIndicator {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 15
        running: context.unlockInProgress
        visible: running
        height: 24; width: 24
    }
}
