import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.config

Item {
    id: root
    signal launchRequested()

    ListModel { id: allAppsModel }
    ListModel { id: filteredApps }
    property bool isLoading: true
    property var tempAppsData: ({}) 

    // 图标路径
    property string iconThemePath: Quickshell.env("HOME") + "/.local/share/icons/Tela-circle-dracula/scalable/apps/"

    // ============================================================
    // 【核心策略：预加载】
    // ============================================================
    Component.onCompleted: {
        appScanner.running = true;
    }

    // 扫描进程
    Process {
        id: appScanner
        command: ["bash", "-c", "find /usr/share/applications ~/.local/share/applications -name '*.desktop' 2>/dev/null -exec grep -H -E '^(Name|Exec|Icon|NoDisplay|Categories)=' {} + > /tmp/qs_apps.txt"]
        running: false 
        onExited: (code, status) => {
            if (code === 0) {
                root.tempAppsData = {};
                appReader.running = true;
            } else {
                root.isLoading = false;
            }
        }
    }

    // 读取进程
    Process {
        id: appReader
        command: ["cat", "/tmp/qs_apps.txt"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => root.parseSingleLine(line)
        }
        onExited: (code, status) => root.finalizeApps()
    }

    // 解析逻辑
    function parseSingleLine(line) {
        line = line.trim();
        if (!line) return;
        let firstColon = line.indexOf(":");
        if (firstColon === -1) return;
        let path = line.substring(0, firstColon);
        let content = line.substring(firstColon + 1);
        let firstEq = content.indexOf("=");
        if (firstEq === -1) return;
        let key = content.substring(0, firstEq);
        let value = content.substring(firstEq + 1);

        if (!root.tempAppsData[path]) {
            root.tempAppsData[path] = { name: "", exec: "", icon: "", noDisplay: false, categories: "" };
        }

        if (key === "Name" && !root.tempAppsData[path].name) root.tempAppsData[path].name = value;
        else if (key === "Exec" && !root.tempAppsData[path].exec) root.tempAppsData[path].exec = value.replace(/ %[fFuUdDnNickvm].*/, "").trim();
        else if (key === "Icon") {
            if (!root.tempAppsData[path].icon) root.tempAppsData[path].icon = value;
        }
        else if (key === "NoDisplay" && value === "true") root.tempAppsData[path].noDisplay = true;
        else if (key === "Categories") root.tempAppsData[path].categories = value;
    }

    function finalizeApps() {
        allAppsModel.clear();
        for (let path in root.tempAppsData) {
            let app = root.tempAppsData[path];
            if (app.name && app.exec) {
                if (!shouldHideApp(app)) {
                    allAppsModel.append(app);
                }
            }
        }
        root.isLoading = false;
        root.tempAppsData = {}; 
        search(""); // 初始化列表
    }

    // 黑名单过滤
    function shouldHideApp(app) {
        let name = app.name.toLowerCase();
        let exec = app.exec.toLowerCase();
        if (app.noDisplay === true) return true;
        const blockedKeywords = [
            "avahi", "fcitx", "cmake", "qt v4l2", "qvidcap", "display cal",
            "lstopo", "compton", "picom", "nitrogen", "uxterm", "xterm",
            "hicolor", "xdg", "configuration", "keyboard layout", "gcr prompter",
            "viewer", "wizard", "qt5", "qt6", "manage printing",
            "rofi", "blueman", "bluetooth adapters", "btop"
        ];
        for (let i = 0; i < blockedKeywords.length; i++) {
            if (name.includes(blockedKeywords[i]) || exec.includes(blockedKeywords[i])) return true;
        }
        return false;
    }

    function search(text) {
        filteredApps.clear();
        let q = text.toLowerCase();
        let count = 0;
        
        if (root.isLoading) return;

        for(let i = 0; i < allAppsModel.count; i++) {
            let item = allAppsModel.get(i);
            if(item.name.toLowerCase().includes(q) || item.exec.toLowerCase().includes(q)) {
                filteredApps.append(item);
                count++;
                if (count >= 50) break;
            }
        }
        appsList.currentIndex = 0;
    }

    // ============================================================
    // 【核心策略：显示时零计算】
    // ============================================================
    onVisibleChanged: {
        if (visible) {
            searchBox.text = "";
            searchBox.forceActiveFocus();
            
            // 只有当预加载意外失败或者列表为空时，才尝试补救扫描
            if (allAppsModel.count === 0 && !root.isLoading) {
                appScanner.running = true;
            } else {
                search("");
            }
        }
    }

    // 界面布局
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        // 搜索框
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            color: Colorsheme.background
            radius: 12
            border.width: 1
            border.color: searchBox.activeFocus ? "#666" : "#333"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8
                Text { text: "🔍"; color: "#888"; font.pixelSize: 14 }
                TextInput {
                    id: searchBox
                    Layout.fillWidth: true
                    color: "white"
                    font.pixelSize: 16
                    verticalAlignment: Text.AlignVCenter
                    selectByMouse: true
                    activeFocusOnTab: true
                    Text {
                        text: root.isLoading ? "Loading apps..." : "Search..."
                        color: "#555"
                        visible: parent.text === ""
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    onTextChanged: root.search(text)
                    Keys.onUpPressed: appsList.decrementCurrentIndex()
                    Keys.onDownPressed: appsList.incrementCurrentIndex()
                    Keys.onReturnPressed: runSelectedApp()
                    Keys.onEnterPressed: runSelectedApp()
                }
            }
        }

        // 列表视图
        ListView {
            id: appsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: filteredApps
            spacing: 2
            cacheBuffer: 200 
            
            highlight: Rectangle { color: "#333"; radius: 8 }
            highlightMoveDuration: 0 

            delegate: Item {
                width: ListView.view.width
                height: 48

                TapHandler {
                    onTapped: {
                        appsList.currentIndex = index;
                        runSelectedApp();
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 12

                    // 图标容器
                    Item {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32

                        // 底层：文字头像
                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: "#444"
                            Text {
                                anchors.centerIn: parent
                                text: model.name ? model.name.charAt(0).toUpperCase() : "?"
                                color: "#aaa"
                                font.bold: true
                                font.pixelSize: 16
                            }
                        }

                        // 上层：图片
                        Image {
                            id: appIcon
                            anchors.fill: parent
                            sourceSize.width: 64
                            sourceSize.height: 64
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            cache: true
                            smooth: true

                            // 优先系统 -> 备用 Tela
                            source: {
                                if (!model.icon) return "";
                                if (model.icon.indexOf("/") !== -1) return "file://" + model.icon;
                                return "image://icon/" + model.icon;
                            }
                            
                            visible: status === Image.Ready

                            onStatusChanged: {
                                if (status === Image.Error) {
                                    let src = source.toString();
                                    if (src.indexOf("image://icon/") !== -1) {
                                        source = "file://" + root.iconThemePath + model.icon + ".svg";
                                    }
                                    else if (src.indexOf("Tela") !== -1) {
                                        if (/[A-Z]/.test(model.icon)) {
                                            source = "file://" + root.iconThemePath + model.icon.toLowerCase() + ".svg";
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: model.name
                        color: ListView.isCurrentItem ? "white" : "#ccc"
                        font.pixelSize: 14
                        font.bold: ListView.isCurrentItem
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering 
                    }

                    Text { text: "⏎"; color: "#666"; visible: ListView.isCurrentItem }
                }
            }
        }
    }

    function runSelectedApp() {
        if (filteredApps.count > 0 && appsList.currentIndex >= 0) {
            let cmd = filteredApps.get(appsList.currentIndex).exec;
            launchProcess.command = ["bash", "-c", "nohup " + cmd + " > /dev/null 2>&1 &"];
            launchProcess.running = true;
            root.launchRequested();
        }
    }
    Process { id: launchProcess; onExited: running = false }
}
