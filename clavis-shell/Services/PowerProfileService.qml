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
    // Whatever the power daemon reports, even when the CPU state cannot be
    // classified. Used to offer a sensible "re-apply" target.
    property string daemonProfile: ""
    readonly property string lastError: operationFailure || queryFailure
    readonly property bool available: supportedProfiles.length > 0 && profile.length > 0
    readonly property string reapplyTarget: requestedProfile.length > 0 ? requestedProfile : (profile.length > 0 ? profile : fallbackTarget(daemonProfile))
    readonly property bool busy: queryProcess.running || setProcess.running
    readonly property string label: labelForProfile(profile)
    readonly property string icon: iconForProfile(profile)
    // The installed, root-owned helper implements three CPU policies on this
    // firmware/driver combination. Other machines keep using native profiles.
    // It reads actual EPP values; platform_profile is informational because the
    // firmware readback drifts for identical requests.
    readonly property bool performanceViaBalanced: productName.text().trim() === "Redmi G 2022" && biosVersion.text().trim() === "RMGAD6T0P1313" && platformDriver.text().trim() === "bitland-mifs-wmi"
    // GPU 频率档位由 powermode 定义；切换电源档时会套用该档预设，滑块可单独覆盖。
    property int gpuLevel: 0
    property var gpuLevelNames: []
    property string gpuLock: ""
    property int igpuCap: 0
    readonly property bool gpuAvailable: performanceViaBalanced && gpuLevelNames.length === 4
    readonly property string gpuLevelLabel: gpuAvailable && gpuLevel >= 0 && gpuLevel < gpuLevelNames.length ? gpuLevelNames[gpuLevel] : ""

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

    function fallbackTarget(daemon) {
        // The helper maps both balanced and performance onto the daemon's
        // performance profile; only power-saver is unambiguous.
        if (performanceViaBalanced)
            return daemon === "power-saver" ? "power-saver" : "balanced";

        return supportedProfiles.indexOf(daemon) >= 0 ? daemon : "balanced";
    }

    function refresh() {
        if (busy)
            return ;

        queryProcess.running = true;
        commandTimeout.restart();
    }

    function applyProfile(value, force) {
        if (busy || supportedProfiles.indexOf(value) < 0)
            return ;

        if (!force && value === profile)
            return ;

        operationFailure = "";
        requestedProfile = value;
        setProcess.command = performanceViaBalanced ? ["/usr/bin/sudo", "-n", "/usr/local/libexec/clavis-power-profile", "set", value] : ["powerprofilesctl", "set", value];
        setProcess.running = true;
        commandTimeout.restart();
    }

    function setProfile(value) {
        applyProfile(value, false);
    }

    // 只改 GPU 档位，不动 CPU 电源档；失败由 operationFailure 托住。
    function setGpuLevel(level) {
        if (!gpuAvailable || busy || level === gpuLevel)
            return ;

        operationFailure = "";
        setProcess.command = ["/usr/bin/sudo", "-n", "/usr/local/libexec/clavis-power-profile", "gpu", String(level)];
        setProcess.running = true;
        commandTimeout.restart();
    }

    // Re-applies the last known target even when the readback already shows it,
    // which is how a daemon/CPU mismatch gets repaired.
    function reapply() {
        applyProfile(reapplyTarget, true);
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
                    root.daemonProfile = String(result.daemonProfile || "");
                    root.gpuLevelNames = Array.isArray(result.gpuLevelNames) ? result.gpuLevelNames.map((name) => {
                        return String(name);
                    }) : [];
                    root.gpuLevel = Number(result.gpuLevel) || 0;
                    root.gpuLock = String(result.gpuLock || "");
                    root.igpuCap = Number(result.igpuCap) || 0;
                    if (profiles.indexOf(result.profile) >= 0)
                        active = result.profile;
                    else
                        parseFailure = qsTr("系统电源状态与 CPU 设置不一致，可点「重新应用」修复。");
                } catch (error) {
                    parseFailure = String(error);
                }
            } else if (exitCode === 0) {
                root.gpuLevelNames = [];
                root.gpuLock = "";
                root.igpuCap = 0;
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
            if (!root.performanceViaBalanced)
                root.daemonProfile = active;

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
