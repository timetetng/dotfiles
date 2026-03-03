import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: root
    
    // 必须保留 context 属性定义（非 required）
    property var context: null

    // 适配放大后的尺寸
    width: 280
    height: 260

    // 【修改】背景颜色与其他卡片一致
    color: "#1E1E1E" 
    radius: 24
    
    // 稍微加一点边框增加质感（可选，这里设为透明或极淡）
    border.color: Qt.rgba(1,1,1,0.05)
    border.width: 1

    readonly property string termFont: "JetBrainsMono Nerd Font"

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - 40 // 内部留白
        spacing: 15

        // 【修改】只保留这一行指定的命令
        Text {
            Layout.fillWidth: true
            text: "xingjian@arch : ~$ auth"
            color: "#89b4fa" // 【修改】指定的淡蓝色
            font.family: root.termFont
            font.pixelSize: 14
            font.bold: true
            wrapMode: Text.WrapAnywhere
        }

        // 密码输入区域
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // 提示符
            Text {
                text: "Password:"
                color: "#666" // 暗灰色，低调
                font.family: root.termFont
                font.pixelSize: 14
            }

            // 输入框
            TextInput {
                id: input
                Layout.fillWidth: true
                
                color: "white"
                font.family: root.termFont
                font.pixelSize: 14
                
                echoMode: TextInput.Password
                passwordCharacter: "*" 
                
                focus: true
                enabled: root.context && !root.context.unlockInProgress
                
                // 光标
                cursorVisible: activeFocus
                
                // 错误时文字变红震慑一下
                ColorAnimation on color {
                    running: root.context && root.context.showFailure
                    from: "#ff4444"; to: "white"
                    duration: 500
                }

                onTextChanged: if(root.context) root.context.currentText = text
                onAccepted: if(root.context) root.context.tryUnlock()
                
                Connections {
                    target: root.context
                    function onCurrentTextChanged() {
                        if (root.context && root.context.currentText === "") input.text = ""
                    }
                }
            }
        }

        // 状态反馈 (平时隐藏，只有错误或验证时显示)
        Text {
            Layout.fillWidth: true
            text: {
                if (!root.context) return ""
                if (root.context.showFailure) return ">> Permission Denied"
                if (root.context.unlockInProgress) return ">> Verifying..."
                return ""
            }
            color: "#ff4444"
            font.family: root.termFont
            font.pixelSize: 12
            visible: text !== ""
        }
    }
}
