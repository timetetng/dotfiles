import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.config 

Rectangle {
    id: root

    // ============================================================
    // 1. 样式与尺寸
    // ============================================================
    color: Colorsheme.background
    radius: Sizes.cornerRadius
    
    // 【核心】裁剪：这是实现“滑出”效果的关键
    clip: true

    property bool expanded: false
    property int barHeight: Sizes.barHeight
    
    // 动态宽度计算
    width: expanded ? (contentLayout.implicitWidth + 24) : (ramGroup.implicitWidth + 24)
    height: barHeight

    implicitWidth: width
    implicitHeight: height

    // 宽度动画
    Behavior on width { 
        NumberAnimation { 
            duration: 300
            easing.type: Easing.OutQuart 
        } 
    }

    // ============================================================
    // 2. 数据源 (Python 后端)
    // ============================================================
    property string ramText: "..."
    property string cpuText: "0%"
    property string tempText: "0°C"
    property int tempValue: 0 
    property int cpuValue: 0

    Process {
        id: proc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/sys_monitor.py"]
        stdout: SplitParser {
            onRead: (data) => {
                try {
                    let json = JSON.parse(data.trim());
                    root.ramText = json.ram;
                    root.cpuText = json.cpu;
                    root.tempText = json.temp;
                    root.cpuValue = parseInt(json.cpu);
                    root.tempValue = parseInt(json.temp);
                } catch(e) {}
            }
        }
    }

    // 定时刷新数据 (2秒一次)
    Timer { 
        interval: 2000; 
        running: true; 
        repeat: true; 
        triggeredOnStart: true; 
        onTriggered: proc.running = true 
    }

    // 【已删除】自动收起的 Timer 这里已经被删掉了
    // 现在的状态完全由 expanded 变量控制，直到你再次点击

    // ============================================================
    // 3. 颜色逻辑
    // ============================================================
    readonly property color colorNormal: "#ffffff"
    readonly property color colorWarn: "#f9e2af"
    readonly property color colorCrit: "#f38ba8"

    function getTempColor(val) {
        if (val > 85) return colorCrit;
        if (val > 70) return colorWarn;
        return colorNormal;
    }
    
    function getCpuColor(val) {
        if (val > 90) return colorCrit;
        if (val > 70) return colorWarn;
        return colorNormal;
    }

    // ============================================================
    // 4. 交互区域
    // ============================================================
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        
        // 点击切换：展开 <-> 收起
        onClicked: {
            root.expanded = !root.expanded;
            proc.running = true; // 点击时顺便刷新一下数据
        }
        
        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                Quickshell.execDetached(["gnome-system-monitor"]);
            }
        }
    }

    // ============================================================
    // 5. 布局内容
    // ============================================================
    RowLayout {
        id: contentLayout
        
        // ★ 核心 1：钉在右边
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 12
        
        spacing: 12
        
        // ★ 核心 2：从右向左排 (RAM在最右)
        layoutDirection: Qt.RightToLeft

        // --- 1. RAM (常驻，最右) ---
        RowLayout {
            id: ramGroup
            spacing: 4
            
            Text { 
                text: "" 
                color: "#a6e3a1" 
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
            }
            Text { 
                text: root.ramText 
                color: "#ffffff" 
                font.family: "LXGW WenKai GB Screen"
                font.bold: true 
                font.pixelSize: 13 
            }
        }

        // --- 2. Temp (抽屉，RAM 左边) ---
        RowLayout {
            id: tempGroup
            spacing: 4
            
            visible: opacity > 0
            opacity: root.expanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            
            Text { 
                text: "" 
                color: root.getTempColor(root.tempValue)
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
            }
            Text { 
                text: root.tempText 
                color: root.getTempColor(root.tempValue)
                font.family: "LXGW WenKai GB Screen"
                font.bold: true 
                font.pixelSize: 13 
            }
        }

        // --- 3. CPU (抽屉，最左边) ---
        RowLayout {
            id: cpuGroup
            spacing: 4
            
            visible: opacity > 0
            opacity: root.expanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            
            Text { 
                text: "" 
                color: root.getCpuColor(root.cpuValue)
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
            }
            Text { 
                text: root.cpuText 
                color: root.getCpuColor(root.cpuValue)
                font.family: "LXGW WenKai GB Screen"
                font.bold: true 
                font.pixelSize: 13 
            }
        }
    }
}
