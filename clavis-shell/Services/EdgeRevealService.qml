pragma Singleton

import QtQuick
import Quickshell

// 按「屏幕 + 屏幕边缘」聚合唤出状态。
//
// 顶部 bar 与钥石可能锚在同一条边上，两者各自上报 hover，只有最后收下的
// 那个窗口会真的收到指针事件；因此不能各自维护 hover，否则同一条边上会
// 出现「只出来一个」的现象。这里以 (screen, edge) 为键共享状态：
//
// 任意上报源进入热区即立即可见，全部离开后延迟 hideDelay 收起。
// 上报源用 id 标识而不是计数，重复上报同一个 id 不会让状态漂移。
Singleton {
    id: root

    // 鼠标离开后延迟多久收起，给「热区 → 展开的 bar / 弹层」留出容错时间。
    property int hideDelay: 400

    // key -> { hoverers: { sourceId: true }, hold: number, revealed: bool }
    // 每次写入都整体重新赋值，绑定的 isRevealed() 才能收到通知。
    property var entries: ({})

    function keyFor(screen, edge) {
        const name = screen && screen.name ? String(screen.name) : "";
        return name + "|" + String(edge || "");
    }

    function entryFor(key) {
        const entry = root.entries[key];
        if (entry !== undefined)
            return entry;
        return {
            "hoverers": {},
            "hold": 0,
            "revealed": false
        };
    }

    function isRevealed(screen, edge) {
        const entry = root.entryFor(root.keyFor(screen, edge));
        return entry.revealed === true;
    }

    function writeEntry(key, hoverers, hold, revealed) {
        const next = Object.assign({}, root.entries);
        next[key] = {
            "hoverers": hoverers,
            "hold": hold,
            "revealed": revealed
        };
        root.entries = next;
        hideTimer.restart();
    }

    function activeHoverers(hoverers) {
        return Object.keys(hoverers).length;
    }

    function setHovered(screen, edge, sourceId, hovered) {
        const key = root.keyFor(screen, edge);
        const current = root.entryFor(key);
        const hoverers = Object.assign({}, current.hoverers);
        if (hovered)
            hoverers[String(sourceId)] = true;
        else
            delete hoverers[String(sourceId)];

        const active = root.activeHoverers(hoverers) > 0;
        // 一旦可见就保持可见，真正的收起交给 hideDelay 之后的 sweep()。
        root.writeEntry(key, hoverers, current.hold, active || current.hold > 0 || current.revealed === true);
    }

    function acquireHold(screen, edge) {
        const key = root.keyFor(screen, edge);
        const current = root.entryFor(key);
        root.writeEntry(key, current.hoverers, current.hold + 1, true);
    }

    function releaseHold(screen, edge) {
        const key = root.keyFor(screen, edge);
        const current = root.entryFor(key);
        if (current.hold <= 0 && current.revealed !== true)
            return;

        const hold = Math.max(0, current.hold - 1);
        root.writeEntry(key, current.hoverers, hold, root.activeHoverers(current.hoverers) > 0 || hold > 0 || current.revealed === true);
    }

    // 窗口销毁时清掉该边的全部来源，避免持有的 hover 泄漏成永久可见。
    function clear(screen, edge) {
        const key = root.keyFor(screen, edge);
        if (root.entries[key] === undefined)
            return;

        const next = Object.assign({}, root.entries);
        delete next[key];
        root.entries = next;
    }

    function sweep() {
        const next = {};
        let changed = false;
        for (const key in root.entries) {
            const entry = root.entries[key];
            const revealed = root.activeHoverers(entry.hoverers) > 0 || entry.hold > 0;
            next[key] = {
                "hoverers": entry.hoverers,
                "hold": entry.hold,
                "revealed": revealed
            };
            if (revealed !== entry.revealed)
                changed = true;
        }
        if (changed)
            root.entries = next;
    }

    Timer {
        id: hideTimer

        interval: root.hideDelay
        repeat: false
        onTriggered: root.sweep()
    }
}
