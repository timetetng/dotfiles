import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtWebSockets 1.15
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../config"
import "common"

SlideWindow {
    id: root
    
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    title: "哔哩哔哩直播"
    icon: "\uf26c"
    windowHeight: 600

    Connections {
        target: WidgetState
        function onShowBiliBarrageChanged() {
            if (root.isOpen !== WidgetState.showBiliBarrage) {
                root.isOpen = WidgetState.showBiliBarrage;
            }
        }
    }
    onIsOpenChanged: {
        if (WidgetState.showBiliBarrage !== root.isOpen) {
            WidgetState.showBiliBarrage = root.isOpen;
        }
    }


    ListModel { id: barrageModel }

    WebSocket {
        id: wsClient
        url: "ws://10.0.0.2:7777"
        active: true 
        onStatusChanged: {
            if (wsClient.status === WebSocket.Closed || wsClient.status === WebSocket.Error) {
                wsClient.active = false;
                reconnectTimer.start();
            }
        }
        onTextMessageReceived: function(message) {
            try {
                var msg = JSON.parse(message);
                if (msg.platform !== "bilibili") return;
                var isChat = msg.type === "Chat", isGift = msg.type === "Gift", isEnter = msg.type === "EnterRoom";
                if (!isChat && !isGift && !isEnter) return;

                barrageModel.append({
                    "msgType": msg.type,
                    "name": msg.data.name || "未知",
                    "content": isChat ? msg.data.content : (isGift ? ("送出了 " + msg.data.item + " x" + msg.data.num) : "进入直播间"),
                    "avatarUrl": msg.data.avatar || "",
                    "textColor": isChat ? "#cdd6f4" : (isGift ? "#f9e2af" : "#a6adc8")
                });
                if (barrageModel.count > 100) barrageModel.remove(0, 1);
                Qt.callLater(function() { listView.positionViewAtEnd(); });
            } catch(e) {}
        }
    }

    Timer { id: reconnectTimer; interval: 5000; onTriggered: wsClient.active = true }

    headerTools: RowLayout {
        Text {
            text: wsClient.status === WebSocket.Open ? "🟢" : "🔴"
            font.pixelSize: 12
        }
    }

    ListView {
        id: listView
        Layout.fillWidth: true; Layout.fillHeight: true
        model: barrageModel; spacing: 14; clip: true

        delegate: RowLayout {
            width: listView.width; spacing: 12
            
            Image {
                source: model.avatarUrl
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                sourceSize: Qt.size(32, 32) 
                Layout.alignment: Qt.AlignTop
                visible: model.avatarUrl !== ""
                fillMode: Image.PreserveAspectCrop
            }
            Text {
                text: "<b>" + model.name + "</b>: " + model.content
                color: model.textColor
                font.pixelSize: 16 
                lineHeight: 1.3
                wrapMode: Text.Wrap; Layout.fillWidth: true
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true; spacing: 8; Layout.bottomMargin: 10
        TextField {
            id: inputField
            Layout.fillWidth: true; placeholderText: "输入弹幕内容..."
            color: "#cdd6f4"; font.pixelSize: 16 
            background: Rectangle { color: "#313244"; radius: 6 }
            onAccepted: root.sendDanmaku()
        }
        Button {
            text: "发送"
            background: Rectangle { color: "#cba6f7"; radius: 6; opacity: parent.pressed ? 0.8 : 1.0 }
            contentItem: Text {
                text: parent.text; color: "#11111b"; font.bold: true
                font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
            onClicked: root.sendDanmaku()
        }
    }

    Process {
        id: curlSendProcess
        property string msgText: ""

        command: [
            "curl", "-s", "-X", "POST", "https://api.live.bilibili.com/msg/send",
            "-H", "Content-Type: application/x-www-form-urlencoded",
            "-b", BiliConfig.cookie,
            "--data-urlencode", "color=16777215",
            "--data-urlencode", "fontsize=25",
            "--data-urlencode", "mode=1",
            "--data-urlencode", "msg=" + msgText,
            "--data-urlencode", "rnd=" + Math.floor(Date.now() / 1000),
            "--data-urlencode", "roomid=" + BiliConfig.roomId,
            "--data-urlencode", "bubble=0",
            "--data-urlencode", "csrf=" + BiliConfig.jct,
            "--data-urlencode", "csrf_token=" + BiliConfig.jct
        ]
        
        stdout: SplitParser {
            onRead: (data) => {
                try {
                    var res = JSON.parse(data);
                    if (res.code === 0) {
                        console.log("[Bilibili] 发送成功");
                        inputField.text = ""; 
                    } else console.log("[Bilibili] 发送失败:", res.message);
                } catch(e) {}
            }
        }
    }

    function sendDanmaku() {
        var text = inputField.text.trim();
        if (text === "") return;
        curlSendProcess.msgText = text;
        curlSendProcess.running = true;
      }
IpcHandler {
    target: "biliBarrage"

    function toggle(): void {
        root.isOpen = !root.isOpen;
        console.log("[Bili IPC] toggle ->", root.isOpen)
    }

    function show(): void {
        root.isOpen = true;
        console.log("[Bili IPC] show ->", root.isOpen)
    }

    function hide(): void {
        root.isOpen = false;
        console.log("[Bili IPC] hide ->", root.isOpen)
    }
}


}
