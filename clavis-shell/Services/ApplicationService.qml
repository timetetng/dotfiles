pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property var applications: []

    function isVisibleApplication(application) {
        if (!application)
            return false;
        if (application.noDisplay === true || application.hidden === true)
            return false;
        return String(application.id || "").trim() !== ""
            && String(application.execString || application.exec || "").trim() !== "";
    }

    function refresh() {
        const source = DesktopEntries.applications.values || [];
        const seen = new Set();
        const next = [];
        for (const application of source) {
            if (!root.isVisibleApplication(application))
                continue;
            const id = String(application.id);
            if (seen.has(id))
                continue;
            seen.add(id);
            next.push(application);
        }
        next.sort((left, right) => {
            const byName = String(left.name || left.id).localeCompare(
                String(right.name || right.id));
            return byName !== 0 ? byName : String(left.id).localeCompare(String(right.id));
        });
        root.applications = next;
    }

    function getVisibleApplications() {
        return root.applications.slice();
    }

    function findById(identifier) {
        const value = String(identifier || "");
        const withoutSuffix = value.endsWith(".desktop")
            ? value.substring(0, value.length - ".desktop".length) : value;
        for (const application of root.applications) {
            const id = String(application.id || "");
            if (id === value || id === withoutSuffix
                    || id === withoutSuffix + ".desktop") {
                return application;
            }
        }
        return null;
    }

    function iconSource(iconName) {
        const value = String(iconName || "");
        if (value.startsWith("file://") || value.startsWith("image://"))
            return value;
        if (value.startsWith("/"))
            return "file://" + value;
        const resolved = Quickshell.iconPath(
            value || "application-x-executable", "application-x-executable");
        return resolved && resolved !== ""
            ? resolved : "image://icon/application-x-executable";
    }

    function iconSourceForEntry(entry) {
        if (!entry)
            return root.iconSource("");
        const application = root.findById(entry.id);
        if (application && application.icon)
            return root.iconSource(application.icon);
        if (entry.icon)
            return root.iconSource(entry.icon);

        const command = String(entry.exec || "").trim().split(/\s+/)[0];
        const commandName = command.substring(command.lastIndexOf("/") + 1);
        if (commandName) {
            for (const candidate of root.applications) {
                const candidateCommand = String(
                    candidate.execString || candidate.exec || "").trim().split(/\s+/)[0];
                if (candidateCommand.substring(candidateCommand.lastIndexOf("/") + 1)
                        === commandName) {
                    return root.iconSource(candidate.icon);
                }
            }
        }
        return root.iconSource("");
    }

    // 通知/托盘里拿到的 appIcon 经常是空的或不存在的名字：
    // 先用它本身，失败则按 appName 去 .desktop 里找图标
    function resolveAppIcon(appName, iconName) {
        const direct = String(iconName || "");
        if (direct.startsWith("/") || direct.startsWith("file://"))
            return direct;
        if (direct !== "" && Quickshell.hasThemeIcon(direct))
            return direct;

        const name = String(appName || "").trim();
        if (name === "")
            return "";

        const lower = name.toLowerCase();
        const ids = [name, name + ".desktop", lower, lower + ".desktop"];
        for (const id of ids) {
            const application = root.findById(id);
            if (application && application.icon && Quickshell.hasThemeIcon(application.icon))
                return application.icon;
        }

        const heuristic = DesktopEntries.heuristicLookup(name);
        if (heuristic && heuristic.icon && Quickshell.hasThemeIcon(heuristic.icon))
            return heuristic.icon;

        for (const application of root.applications) {
            const title = String(application.name || "").toLowerCase();
            const execBase = String(application.execString || application.exec || "").trim().split(/\s+/)[0];
            const base = execBase.substring(execBase.lastIndexOf("/") + 1).toLowerCase();
            if ((title === lower || base === lower)
                    && application.icon && Quickshell.hasThemeIcon(application.icon)) {
                return application.icon;
            }
        }
        return "";
    }

    Connections {
        target: DesktopEntries

        function onApplicationsChanged() {
            root.refresh();
        }
    }

    Component.onCompleted: root.refresh()
}
