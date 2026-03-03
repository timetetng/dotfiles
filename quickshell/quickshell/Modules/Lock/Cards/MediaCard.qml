import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects 
import Quickshell
import Quickshell.Services.Mpris

Rectangle {
    id: root
    
    // 适配之前的放大版尺寸
    width: 280
    height: 260 

    color: "#1E1E1E"
    radius: 24
    
    // 图标定义
    QtObject {
        id: icons
        readonly property string basePath: "/home/archirithm/.config/quickshell/assets/icons/"
        property string play: basePath + "play.svg"
        property string pause: basePath + "pause.svg"
        property string next: basePath + "next.svg"
        property string previous: basePath + "previous.svg"
    }

    // 播放器逻辑
    property var player: {
        let list = Mpris.players.values;
        for (let i = 0; i < list.length; i++) {
            if (list[i].isPlaying) return list[i];
        }
        return list.length > 0 ? list[0] : null;
    }

    property bool hasMedia: player !== null
    property bool isPlaying: player && player.isPlaying
    property string artUrl: (player && player.trackArtUrl) ? player.trackArtUrl : ""
    property string title: (player && player.trackTitle) ? player.trackTitle : "No Media"
    property string artist: (player && player.trackArtist) ? player.trackArtist : ""

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20 // 封面和按钮之间的间距

        // === 1. 专辑封面 (带文字) ===
        Rectangle {
            Layout.preferredWidth: 160
            Layout.preferredHeight: 160
            Layout.alignment: Qt.AlignHCenter
            
            radius: 16
            color: "#2a2a2a"
            clip: true // 裁切圆角
            
            // 封面原图 (无模糊)
            Image {
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                visible: root.artUrl !== ""
                smooth: true
            }

            // 无封面时的占位符
            Text {
                anchors.centerIn: parent
                text: "♫"
                color: "#444"
                font.pixelSize: 50
                visible: root.artUrl === ""
            }

            // --- 文字遮罩层 ---
            // 为了让白字在任何封面上都能看清，加一个底部黑色渐变
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 60 // 遮罩高度
                visible: root.artUrl !== ""
                
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: "#cc000000" } // 底部变黑
                }
            }

            // 歌曲信息 (叠加在封面上)
            ColumnLayout {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 10
                spacing: 2
                
                // 歌名
                Text {
                    Layout.fillWidth: true
                    text: root.title
                    color: "white"
                    font.bold: true
                    font.pixelSize: 15
                    font.family: "LXGW WenKai GB Screen"
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                }
                
                // 歌手
                Text {
                    Layout.fillWidth: true
                    text: root.artist
                    color: "#ddd" // 浅灰
                    font.pixelSize: 12
                    font.family: "LXGW WenKai GB Screen"
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // === 2. 控制按钮 (放在下面) ===
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 30

            // 上一曲
            MouseArea {
                Layout.preferredWidth: 32; Layout.preferredHeight: 32
                onClicked: if(root.player) root.player.previous()
                Image {
                    id: prevIcon
                    anchors.fill: parent
                    source: icons.previous
                    visible: false
                }
                ColorOverlay { anchors.fill: prevIcon; source: prevIcon; color: "white" }
            }

            // 播放/暂停 (大按钮)
            MouseArea {
                Layout.preferredWidth: 54; Layout.preferredHeight: 54
                onClicked: if(root.player) root.player.togglePlaying()
                
                // 按钮背景圈
                Rectangle {
                    anchors.fill: parent
                    radius: 27
                    color: "#89b4fa"
                }
                
                Image {
                    id: playIcon
                    anchors.centerIn: parent
                    width: 24; height: 24
                    source: root.isPlaying ? icons.pause : icons.play
                    visible: false
                }
                ColorOverlay { anchors.fill: playIcon; source: playIcon; color: "white" }
            }

            // 下一曲
            MouseArea {
                Layout.preferredWidth: 32; Layout.preferredHeight: 32
                onClicked: if(root.player) root.player.next()
                Image {
                    id: nextIcon
                    anchors.fill: parent
                    source: icons.next
                    visible: false
                }
                ColorOverlay { anchors.fill: nextIcon; source: nextIcon; color: "white" }
            }
        }
    }
}
