pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string profile: ""
    property var supportedProfiles: []
    property string queryFailure: ""
    property string operationFailure: ""
    property string requestedProfile: ""
    readonly property string lastError: operationFailure || queryFailure
    readonly property bool available: supportedProfiles.length > 0 && profile.length > 0
    readonly property bool busy: queryProcess.running || setProcess.running
    readonly property string label: labelForProfile(profile)
    readonly property string icon: iconForProfile(profile)

    function labelForProfile(value) {
        switch (value) {
        case "power-saver":
            return qsTr("省电");
        case "balanced":
            return qsTr("均衡");
        case "performance":
            return qsTr("性能");
        default:
            return qsTr("不可用");
        }
    }

    function iconForProfile(value) {
        switch (value) {
        case "power-saver":
            return "eco";
        case "balanced":
            return "balance";
        case "performance":
            return "speed";
        default:
            return "power_settings_new";
        }
    }

    function refresh() {
        if (busy)
            return ;

        queryProcess.running = true;
        commandTimeout.restart();
    }

    function setProfile(value) {
        if (busy || supportedProfiles.indexOf(value) < 0 || value === profile)
            return ;

        operationFailure = "";
        requestedProfile = value;
        setProcess.command = ["powerprofilesctl", "set", value];
        setProcess.running = true;
        commandTimeout.restart();
    }

    Component.onCompleted: refresh()

    Process {
        id: queryProcess

        command: ["powerprofilesctl", "list"]
        environment: ({
            "LC_ALL": "C"
        })
        onExited: (exitCode) => {
            commandTimeout.stop();
            const profiles = [];
            let active = "";
            if (exitCode === 0) {
                for (const line of queryOutput.text.split("\n")) {
                    const match = line.match(/^\s*(\*)?\s*(power-saver|balanced|performance):/);
                    if (!match)
                        continue;

                    profiles.push(match[2]);
                    if (match[1])
                        active = match[2];

                }
            }
            root.supportedProfiles = profiles;
            root.profile = active;
            root.queryFailure = root.available ? "" : queryError.text.trim() || qsTr("无法读取系统电源模式，请确认 power-profiles-daemon 正常运行。");
            if (root.requestedProfile.length > 0 && root.available) {
                if (root.profile !== root.requestedProfile && root.operationFailure.length === 0)
                    root.operationFailure = qsTr("请求切换到「%1」，但系统实际为「%2」。").arg(root.labelForProfile(root.requestedProfile)).arg(root.label);

                root.requestedProfile = "";
            }
        }

        stdout: StdioCollector {
            id: queryOutput
        }

        stderr: StdioCollector {
            id: queryError
        }

    }

    Process {
        id: setProcess

        onExited: (exitCode) => {
            commandTimeout.stop();
            if (exitCode !== 0)
                root.operationFailure = setError.text.trim() || qsTr("切换电源模式失败。");

            Qt.callLater(root.refresh);
        }

        stderr: StdioCollector {
            id: setError
        }

    }

    Timer {
        id: commandTimeout

        interval: 5000
        onTriggered: {
            queryProcess.running = false;
            setProcess.running = false;
            root.queryFailure = qsTr("电源模式命令未完成，请检查 powerprofilesctl 和系统电源服务。");
        }
    }

    Timer {
        interval: 15000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

}
