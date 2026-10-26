import QtQuick
import qs.Common
import qs.Services
import qs.Widgets.common

BarCircularButton {
    id: root

    property var screen: null
    readonly property bool active: WidgetState.qsOpen && WidgetState.qsView === "powerProfile"

    iconName: PowerProfileService.icon
    selected: root.active
    tooltipText: qsTr("电源模式：") + PowerProfileService.label + qsTr("\n点击选择省电 / 性能")
    onClicked: {
        if (root.screen && root.screen.name)
            WidgetState.qsScreenName = root.screen.name;

        if (root.active) {
            WidgetState.qsOpen = false;
        } else {
            PowerProfileService.refresh();
            WidgetState.qsView = "powerProfile";
            WidgetState.qsOpen = true;
        }
    }
}
