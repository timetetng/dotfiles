import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Widgets.common

PanelWindow {
    id: root

    required property string edge
    readonly property real visualThickness: Sizes.barVisualThickness
    readonly property real outerEdgeMargin: Sizes.barOuterEdgeMargin
    readonly property real shadowBuffer: Sizes.barShadowBuffer
    readonly property real surfaceThickness: outerEdgeMargin + visualThickness + shadowBuffer
    readonly property real exclusiveThickness: outerEdgeMargin + visualThickness

    // Auto-hide：bar 仍保留窗口与输入表面，只把视觉带滑出屏幕边缘。
    readonly property bool autoHidden: PersonalizationConfig.barAutoHide
    readonly property bool revealed: !root.autoHidden
        || EdgeRevealService.isRevealed(root.screen, root.edge)
    property real hideShift: root.revealed ? 0 : root.visualThickness
    // Region 只跟随 item 自身几何；视觉带是靠 x 动画移走的，所以用一个
    // 零尺寸 Region 的 y 变化强制重建 mask。
    property int maskRevision: 0

    implicitWidth: surfaceThickness
    color: "transparent"
    exclusiveZone: root.autoHidden ? 0 : root.exclusiveThickness
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "clavis-shell-bar-vertical"
    WlrLayershell.exclusionMode: ExclusionMode.Normal

    Behavior on hideShift {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
            onFinished: root.maskRevision += 1
        }

    }

    BarAxis {
        id: axis

        edge: root.edge
    }

    anchors {
        top: true
        bottom: true
        left: axis.isLeft
        right: axis.isRight
    }

    Item {
        id: visualBand

        x: axis.isLeft ? root.outerEdgeMargin - root.hideShift : root.shadowBuffer + root.hideShift
        y: 0
        width: root.visualThickness
        height: parent.height

        VerticalBarContent {
            id: content

            anchors.fill: parent
            screen: root.screen
            axis: axis
        }

    }

    Item {
        id: revealHotzone

        // 收起后唯一留在屏幕边缘的输入区域，悬停即唤出。
        x: axis.isLeft ? 0 : parent.width - Sizes.edgeRevealHotzone
        y: 0
        width: Sizes.edgeRevealHotzone
        height: parent.height

        HoverHandler {
            onHoveredChanged: EdgeRevealService.setHovered(root.screen, root.edge, "bar-hotzone", hovered)
        }

    }

    CompositorBlurRegion {
        targetWindow: root
        backgroundItem: content.backgroundItems.length > 0 ? content.backgroundItems[0] : null
        additionalBackgroundItems: content.backgroundItems.slice(1)
        radius: 18
    }

    mask: Region {
        Region {
            y: root.hideShift + root.maskRevision
        }

        Region {
            item: content.leadingInputRegionItem
        }

        Region {
            item: content.trailingInputRegionItem
        }

        Region {
            item: revealHotzone
        }

    }

    Component.onDestruction: EdgeRevealService.clear(root.screen, root.edge)

}
