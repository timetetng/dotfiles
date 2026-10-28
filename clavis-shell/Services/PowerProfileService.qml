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
    // The installed, root-owned helper implements three CPU policies on this
    // firmware/driver combination. Other machines keep using native profiles.
    // It reads actual EPP values, so software balanced is not shown as performance.
    readonly property bool performanceViaBalanced: productName.text().trim() === "Redmi G 2022" && biosVersion.text().trim() === "RMGAD6T0P1313" && platformDriver.text().trim() === "bitland-mifs-wmi"

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
        setProcess.command = performanceViaBalanced ? ["/usr/bin/sudo", "-n", "/usr/local/libexec/clavis-power-profile", "set", value] : ["powerprofilesctl", "set", value];
        setProcess.running = true;
        commandTimeout.restart();
    }

    Component.onCompleted: refresh()

    FileView {
        id: productName

        path: "/sys/class/dmi/id/product_name"
        blockLoading: true
    }

    FileView {
        id: biosVersion

        path: "/sys/class/dmi/id/bios_version"
        blockLoading: true
    }

    FileView {
        id: platformDriver

        path: "/sys/class/platform-profile/platform-profile-0/name"
        blockLoading: true
    }

    Process {
        id: queryProcess

        command: root.performanceViaBalanced ? ["/usr/local/libexec/clavis-power-profile", "status"] : ["powerprofilesctl", "list"]
        environment: ({
            "LC_ALL": "C"
        })
        onExited: (exitCode) => {
            commandTimeout.stop();
            let profiles = [];
            let active = "";
            let parseFailure = "";
            if (exitCode === 0 && root.performanceViaBalanced) {
                try {
                    const result = JSON.parse(queryOutput.text);
                    if (result.schemaVersion !== 1 || !Array.isArray(result.supportedProfiles) || result.supportedProfiles.length !== 3 || !["power-saver", "balanced", "performance"].every((value) => {
                        return result.supportedProfiles.indexOf(value) >= 0;
                    }))
                        throw new Error(qsTr("电源助手返回了不支持的数据格式。"));

                    profiles = result.supportedProfiles;
                    if (profiles.indexOf(result.profile) >= 0)
                        active = result.profile;
                    else
                        parseFailure = qsTr("CPU 与平台电源策略不一致，请检查外部电源设置。");
                } catch (error) {
                    parseFailure = String(error);
                }
            } else if (exitCode === 0) {
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
            root.queryFailure = root.available ? "" : parseFailure || queryError.text.trim() || qsTr("无法读取系统电源模式，请确认电源助手和系统电源服务可用。");
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

        interval: setProcess.running ? 45000 : 10000
        onTriggered: {
            queryProcess.running = false;
            setProcess.running = false;
            root.queryFailure = qsTr("电源模式命令未完成，请检查电源助手和系统电源服务。");
        }
    }

    Timer {
        interval: 15000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

}
