import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Components
import qs.Services
import qs.Widgets.common

WidgetPanel {
    id: root

    property bool foreground: false

    title: qsTr("电源模式")
    icon: PowerProfileService.icon
    showBackButton: true
    backAction: () => {
        return WidgetState.qsView = "settings";
    }
    onForegroundChanged: {
        if (foreground)
            PowerProfileService.refresh();

    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Appearance.spacing.small

        InlineStatusBanner {
            Layout.fillWidth: true
            visible: PowerProfileService.lastError.length > 0
            tone: "error"
            message: PowerProfileService.lastError
        }

        SettingsRow {
            Layout.fillWidth: true
            visible: PowerProfileService.lastError.length > 0 && PowerProfileService.supportedProfiles.length > 0
            iconName: "refresh"
            title: qsTr("重新应用「%1」").arg(PowerProfileService.labelForProfile(PowerProfileService.reapplyTarget))
            supportingText: qsTr("把系统电源状态与 CPU 设置重新同步到该档位")
            interactive: true
            enabled: !PowerProfileService.busy
            onClicked: PowerProfileService.reapply()
        }

        SettingsSection {
            Layout.fillWidth: true
            title: PowerProfileService.busy ? qsTr("正在同步…") : qsTr("当前：") + PowerProfileService.label

            Repeater {
                model: [{
                    "profile": "power-saver",
                    "description": qsTr("降低功耗，通常也能降低风扇噪声")
                }, {
                    "profile": "balanced",
                    "description": PowerProfileService.performanceViaBalanced ? qsTr("默认：日常优先节能，负载升高时仍可动态加速") : qsTr("兼顾性能与功耗")
                }, {
                    "profile": "performance",
                    "description": qsTr("优先性能，可能增加功耗与风扇噪声")
                }]

                delegate: SettingsRow {
                    id: profileRow

                    required property var modelData

                    Layout.fillWidth: true
                    iconName: PowerProfileService.iconForProfile(modelData.profile)
                    title: PowerProfileService.labelForProfile(modelData.profile)
                    supportingText: PowerProfileService.supportedProfiles.indexOf(modelData.profile) >= 0 ? modelData.description : qsTr("系统不支持此模式")
                    highlighted: PowerProfileService.profile === modelData.profile
                    interactive: true
                    enabled: PowerProfileService.available && !PowerProfileService.busy && PowerProfileService.supportedProfiles.indexOf(modelData.profile) >= 0
                    onClicked: PowerProfileService.setProfile(modelData.profile)

                    trailing: MaterialSymbol {
                        visible: PowerProfileService.profile === profileRow.modelData.profile
                        text: "check"
                        iconSize: 20
                        color: Appearance.colors.colPrimary
                    }

                }

            }

        }

        SettingsSection {
            Layout.fillWidth: true
            visible: PowerProfileService.gpuAvailable
            title: qsTr("GPU 频率档位")

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Metrics.spacingXS

                Text {
                    Layout.fillWidth: true
                    text: qsTr("当前：") + (PowerProfileService.gpuLevelLabel.length > 0 ? PowerProfileService.gpuLevelLabel : qsTr("未知"))
                    color: Appearance.colors.colOnSurface
                    font.family: Fonts.ui
                    font.pixelSize: Typography.bodyMedium.pixelSize
                    font.weight: Font.Medium
                }

                Text {
                    Layout.fillWidth: true
                    text: PowerProfileService.gpuLock.length === 0 || PowerProfileService.gpuLock === "reset" ? qsTr("不限制 GPU 频率，性能最高、功耗最大") : qsTr("dGPU 锁 %1 MHz，iGPU 上限 %2 MHz").arg(PowerProfileService.gpuLock).arg(PowerProfileService.igpuCap)
                    color: Appearance.colors.colOnSurfaceVariant
                    font.family: Fonts.ui
                    font.pixelSize: Typography.bodySmall.pixelSize
                    wrapMode: Text.Wrap
                }

                MaterialSlider {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    from: 0
                    to: Math.max(0, PowerProfileService.gpuLevelNames.length - 1)
                    stepSize: 1
                    value: PowerProfileService.gpuLevel
                    enabled: PowerProfileService.gpuAvailable && !PowerProfileService.busy
                    accessibleName: qsTr("GPU 频率档位")
                    valueFormatter: (sliderValue) => {
                        const names = PowerProfileService.gpuLevelNames;
                        const index = Math.round(sliderValue);
                        return index >= 0 && index < names.length ? names[index] : "";
                    }
                    onCommitted: (sliderValue) => {
                        PowerProfileService.setGpuLevel(Math.round(sliderValue));
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("切换电源档会套用该档预设（省电→省电、均衡→中、性能→不限），拖动滑块可单独覆盖。")
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colOnLayer1
                    font.family: Fonts.ui
                    font.pixelSize: 12
                }

            }

        }

        Text {
            Layout.fillWidth: true
            text: PowerProfileService.performanceViaBalanced ? qsTr("开机默认均衡；保留睿频与性能上限，不修改自定义风扇曲线。") : qsTr("仅切换系统电源策略，不改变音量或自定义风扇曲线。")
            wrapMode: Text.Wrap
            color: Appearance.colors.colOnLayer1
            font.family: Fonts.ui
            font.pixelSize: 12
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

    }

}
