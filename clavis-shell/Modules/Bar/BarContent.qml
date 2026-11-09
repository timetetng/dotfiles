import QtQuick
import QtQuick.Layouts
import QtQml.Models
import qs.Services

Item {
    id: root

    required property var screen
    required property var axis
    property bool vertical: false
    property string popupEdge: axis.edge
    property int itemRevision: 0
    readonly property Item leadingInputRegionItem: leadingSection
    readonly property Item trailingInputRegionItem: trailingSection
    readonly property var backgroundItems: {
        const revision = root.itemRevision;
        const items = [];
        for (let index = 0; index < componentInstantiator.count; index += 1) {
            const loader = componentInstantiator.objectAt(index);
            if (loader && loader.item)
                items.push(loader.item);

        }
        return items;
    }

    BarSection {
        id: leadingSection

        vertical: root.vertical
        componentCount: PersonalizationConfig.barLeadingComponents.length

        anchors {
            left: root.vertical ? undefined : parent.left
            top: root.vertical ? parent.top : undefined
            leftMargin: root.vertical ? 0 : 10
            topMargin: root.vertical ? 10 : 0
            verticalCenter: root.vertical ? undefined : parent.verticalCenter
            horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
        }

    }

    BarSection {
        id: trailingSection

        vertical: root.vertical
        componentCount: PersonalizationConfig.barTrailingComponents.length

        anchors {
            right: root.vertical ? undefined : parent.right
            bottom: root.vertical ? parent.bottom : undefined
            rightMargin: root.vertical ? 0 : 10
            bottomMargin: root.vertical ? 10 : 0
            verticalCenter: root.vertical ? undefined : parent.verticalCenter
            horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
        }

    }

    // 鼠标停在展开后的 pill 上也算停留在 bar 上，否则 auto-hide 会在
    // 用户正要点击时把 bar 收起。
    HoverHandler {
        parent: leadingSection
        onHoveredChanged: EdgeRevealService.setHovered(root.screen, root.axis.edge, "bar-leading", hovered)
    }

    HoverHandler {
        parent: trailingSection
        onHoveredChanged: EdgeRevealService.setHovered(root.screen, root.axis.edge, "bar-trailing", hovered)
    }

    // 托盘菜单与溢出面板是独立窗口，鼠标移进去后 bar 会失去 hover；
    // 弹层打开期间持住，避免 bar 在菜单下面滑走。
    property bool trayPopupOpen: false
    property bool trayPopupHeld: false

    onTrayPopupOpenChanged: {
        if (root.trayPopupOpen === root.trayPopupHeld)
            return;

        root.trayPopupHeld = root.trayPopupOpen;
        if (root.trayPopupHeld)
            EdgeRevealService.acquireHold(root.screen, root.axis.edge);
        else
            EdgeRevealService.releaseHold(root.screen, root.axis.edge);
    }

    Component.onDestruction: {
        if (root.trayPopupHeld)
            EdgeRevealService.releaseHold(root.screen, root.axis.edge);
    }

    Instantiator {
        id: componentInstantiator

        model: PersonalizationConfig.barComponentIds
        onObjectAdded: root.itemRevision += 1
        onObjectRemoved: root.itemRevision += 1

        delegate: BarComponentLoader {
            id: componentLoader

            required property string modelData
            readonly property int leadingIndex: PersonalizationConfig.barLeadingComponents.indexOf(modelData)
            readonly property int trailingIndex: PersonalizationConfig.barTrailingComponents.indexOf(modelData)
            readonly property int zoneIndex: leadingIndex >= 0 ? leadingIndex : trailingIndex

            componentId: modelData
            screen: root.screen
            axis: root.axis
            barVisualItem: root
            vertical: root.vertical
            active: zoneIndex >= 0
            visible: active
            parent: leadingIndex >= 0 ? leadingSection : trailingSection
            Layout.row: root.vertical ? Math.max(0, zoneIndex) : 0
            Layout.column: root.vertical ? 0 : Math.max(0, zoneIndex)
            Layout.alignment: Qt.AlignCenter
            onItemChanged: root.itemRevision += 1
        }

    }

}
