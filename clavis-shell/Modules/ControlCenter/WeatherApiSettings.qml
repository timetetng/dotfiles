import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import Quickshell
import Clavis.WeatherMap
import qs.Common
import qs.Components
import qs.Modules.Keystone.WeatherContent
import qs.Services
import qs.Widgets.common

// Loaded on demand so a missing native plugin cannot block Control Center.
StyledFlickable {
    id: root

    clip: true
    contentWidth: width
    contentHeight: contentColumn.y + contentColumn.implicitHeight + 28

    readonly property real pageContentWidth: 600
    property bool revealApiKey: false
    property string feedbackText: ""
    property bool feedbackError: false
    property string selectedMapMode: "temp"
    property string locationFeedbackText: ""
    property bool locationFeedbackError: false

    Component.onCompleted: {
        if (!WeatherPlugin.hasValidData && !WeatherPlugin.loading)
            WeatherPlugin.refresh()
    }

    function applyApiKey() {
        const value = apiKeyField.text.trim()
        if (value.length < 16) {
            feedbackError = true
            feedbackText = qsTr("请输入有效的 OpenWeather API key")
            apiKeyField.forceActiveFocus()
            return
        }

        const result = WeatherMapPlugin.storeApiKey(value)
        feedbackError = !result.ok
        feedbackText = result.message || qsTr("无法更新 API key")
    }

    function clearApiKey() {
        const result = WeatherMapPlugin.clearApiKey()
        feedbackError = !result.ok
        feedbackText = result.message || qsTr("无法清除 API key")
    }

    function applyWeatherLocation() {
        const name = locationNameField.text.trim()
        const latitude = Number(latitudeField.text)
        const longitude = Number(longitudeField.text)
        if (!name.length || !isFinite(latitude) || latitude < -90 || latitude > 90
                || !isFinite(longitude) || longitude < -180 || longitude > 180) {
            locationFeedbackError = true
            locationFeedbackText = qsTr("请输入有效的地点名、纬度和经度")
            return
        }

        WeatherPlugin.setManualLocation(latitude, longitude, name)
        locationFeedbackError = false
        locationFeedbackText = qsTr("位置已保存，正在更新天气")
    }

    function clearWeatherLocation() {
        WeatherPlugin.clearManualLocation()
        locationFeedbackError = false
        locationFeedbackText = qsTr("已恢复自动定位")
    }

    function notifyMainShell() {
        Quickshell.execDetached([
            "qs",
            "--path",
            Paths.shellDir + "/shell.qml",
            "ipc",
            "call",
            "weather-map",
            "reloadCredentials"
        ])
    }

    Connections {
        target: WeatherMapPlugin

        function onCredentialOperationFinished(operation, success, message) {
            if (operation !== "openweather_store"
                && operation !== "openweather_clear") {
                return
            }

            root.feedbackError = !success
            root.feedbackText = message
            if (success
                && (operation === "openweather_store"
                    || operation === "openweather_clear")) {
                apiKeyField.clear()
                root.revealApiKey = false
                root.notifyMainShell()
            }
        }
    }

    ColumnLayout {
        id: contentColumn

        width: root.pageContentWidth
        x: Math.max(24, (root.width - width) / 2)
        y: 28
        spacing: 24

        WeatherMapCard {
            id: weatherMap

            Layout.fillWidth: true
            Layout.preferredHeight: 320
            latitude: Number(WeatherPlugin.latitude)
            longitude: Number(WeatherPlugin.longitude)
            locationAvailable: WeatherPlugin.hasValidData
            active: root.visible
            selectedMode: root.selectedMapMode
            showLayerSelector: false
        }

        WeatherMapLayerSelector {
            Layout.alignment: Qt.AlignHCenter
            currentMode: root.selectedMapMode
            onModeSelected: mode => root.selectedMapMode = mode
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: locationContent.implicitHeight + 48
            radius: Appearance.rounding.large
            color: Appearance.colors.colSurfaceContainer

            ColumnLayout {
                id: locationContent

                anchors.fill: parent
                anchors.margins: 24
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    MaterialSymbol {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        text: "location_on"
                        iconSize: 24
                        fill: 1
                        color: Appearance.colors.colPrimary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("天气位置")
                            color: Appearance.colors.colOnSurface
                            font.family: Fonts.ui
                            font.pixelSize: 16
                            font.weight: Font.Medium
                            textFormat: Text.PlainText
                        }

                        Text {
                            Layout.fillWidth: true
                            text: WeatherPlugin.hasManualLocation
                                ? qsTr("使用手动位置：") + WeatherPlugin.locationName
                                : qsTr("当前使用网络定位，代理可能导致位置偏差")
                            color: Appearance.colors.colOnSurfaceVariant
                            font.family: Fonts.ui
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            textFormat: Text.PlainText
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    MaterialTextField {
                        id: locationNameField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        placeholderText: qsTr("地点名称")
                        text: WeatherPlugin.locationName
                        onTextChanged: if (root.locationFeedbackError) root.locationFeedbackText = ""
                    }

                    MaterialTextField {
                        id: latitudeField
                        Layout.preferredWidth: 140
                        Layout.preferredHeight: 56
                        placeholderText: qsTr("纬度")
                        text: WeatherPlugin.hasManualLocation
                            ? Number(WeatherPlugin.latitude).toFixed(6) : ""
                        validator: DoubleValidator { bottom: -90; top: 90; decimals: 6 }
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                    }

                    MaterialTextField {
                        id: longitudeField
                        Layout.preferredWidth: 140
                        Layout.preferredHeight: 56
                        placeholderText: qsTr("经度")
                        text: WeatherPlugin.hasManualLocation
                            ? Number(WeatherPlugin.longitude).toFixed(6) : ""
                        validator: DoubleValidator { bottom: -180; top: 180; decimals: 6 }
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        onAccepted: root.applyWeatherLocation()
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.locationFeedbackText.length > 0
                    text: root.locationFeedbackText
                    color: root.locationFeedbackError
                        ? Appearance.colors.colError
                        : Appearance.colors.colOnSurfaceVariant
                    font.family: Fonts.ui
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                    textFormat: Text.PlainText
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Item { Layout.fillWidth: true }

                    Button {
                        text: qsTr("恢复自动定位")
                        flat: true
                        enabled: WeatherPlugin.hasManualLocation
                        Material.foreground: Appearance.colors.colOnSurfaceVariant
                        onClicked: root.clearWeatherLocation()
                    }

                    Button {
                        text: qsTr("保存位置")
                        highlighted: true
                        enabled: locationNameField.text.trim().length > 0
                        Material.background: Appearance.colors.colPrimary
                        Material.foreground: Appearance.colors.colOnPrimary
                        onClicked: root.applyWeatherLocation()
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            MaterialSymbol {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                text: "partly_cloudy_day"
                iconSize: 30
                fill: 1
                color: Appearance.colors.colOnSecondaryContainer
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: qsTr("天气")
                    color: Appearance.colors.colOnSurface
                    font.family: Fonts.ui
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                    textFormat: Text.PlainText
                }

            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: serviceContent.implicitHeight + 48
            radius: Appearance.rounding.large
            color: Appearance.colors.colSurfaceContainer

            ColumnLayout {
                id: serviceContent

                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colPrimaryContainer

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "key"
                            iconSize: 22
                            fill: 1
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: "OpenWeather Weather Maps"
                            color: Appearance.colors.colOnSurface
                            font.family: Fonts.ui
                            font.pixelSize: 16
                            font.weight: Font.Medium
                            textFormat: Text.PlainText
                        }

                    }

                    Rectangle {
                        implicitWidth: statusContent.implicitWidth + 24
                        implicitHeight: 34
                        radius: Appearance.rounding.full
                        color: WeatherMapPlugin.apiConfigured
                            ? Appearance.colors.colPrimaryContainer
                            : Appearance.colors.colSurfaceContainerHighest

                        RowLayout {
                            id: statusContent

                            anchors.centerIn: parent
                            spacing: 6

                            MaterialSymbol {
                                text: !WeatherMapPlugin.credentialsReady
                                    || WeatherMapPlugin.credentialBusy
                                    ? "sync"
                                    : WeatherMapPlugin.apiConfigured
                                        ? "check_circle"
                                        : "key_off"
                                iconSize: 17
                                fill: WeatherMapPlugin.apiConfigured ? 1 : 0
                                color: WeatherMapPlugin.apiConfigured
                                    ? Appearance.colors.colOnPrimaryContainer
                                    : Appearance.colors.colOnSurfaceVariant
                            }

                            Text {
                                id: serviceStatus

                                text: !WeatherMapPlugin.credentialsReady
                                    ? qsTr("正在检查")
                                    : WeatherMapPlugin.credentialBusy
                                        ? qsTr("处理中")
                                        : WeatherMapPlugin.apiConfigured
                                            ? qsTr("已配置")
                                            : qsTr("未配置")
                                color: WeatherMapPlugin.apiConfigured
                                    ? Appearance.colors.colOnPrimaryContainer
                                    : Appearance.colors.colOnSurfaceVariant
                                font.family: Fonts.ui
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                textFormat: Text.PlainText
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Appearance.colors.colOutlineVariant
                }

                Text {
                    Layout.fillWidth: true
                    text: "OpenWeather API key"
                    color: Appearance.colors.colOnSurface
                    font.family: Fonts.ui
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    textFormat: Text.PlainText
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56

                    MaterialTextField {
                        id: apiKeyField

                        anchors.fill: parent
                        placeholderText: qsTr("输入 OpenWeather API key")
                        echoMode: root.revealApiKey
                            ? TextInput.Normal
                            : TextInput.Password
                        inputMethodHints: Qt.ImhSensitiveData
                            | Qt.ImhNoPredictiveText
                            | Qt.ImhNoAutoUppercase
                        maximumLength: 128
                        enabled: WeatherMapPlugin.credentialsReady
                            && !WeatherMapPlugin.credentialBusy
                        trailingContent: Component {
                            IconButton {
                                anchors.fill: parent
                                iconName: root.revealApiKey
                                    ? "visibility_off" : "visibility"
                                iconSize: 20
                                iconColor:
                                    Appearance.colors.colOnSurfaceVariant
                                accessibleName: root.revealApiKey
                                    ? qsTr("隐藏 API key")
                                    : qsTr("显示 API key")
                                hoverStateLayerColor:
                                    Appearance.colors.colLayer3Hover
                                pressedStateLayerColor:
                                    Appearance.colors.colLayer3Active
                                onClicked: root.revealApiKey =
                                    !root.revealApiKey
                            }
                        }
                        Accessible.name: "OpenWeather API key"
                        Accessible.description: qsTr("安全保存到系统密钥环")
                        onTextChanged: {
                            if (root.feedbackError) {
                                root.feedbackError = false
                                root.feedbackText = ""
                            }
                        }
                        onAccepted: root.applyApiKey()
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("密钥保存在系统密钥环中，保存后立即生效。")
                    color: Appearance.colors.colOnSurfaceVariant
                    font.family: Fonts.ui
                    font.pixelSize: 12
                    lineHeight: 1.35
                    wrapMode: Text.WordWrap
                    textFormat: Text.PlainText
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: feedbackRow.implicitHeight + 20
                    radius: Appearance.rounding.small
                    visible: root.feedbackText !== ""
                    color: root.feedbackError
                        ? Appearance.colors.colErrorContainer
                        : Appearance.colors.colPrimaryContainer

                    RowLayout {
                        id: feedbackRow

                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        MaterialSymbol {
                            text: WeatherMapPlugin.credentialBusy
                                ? "sync"
                                : root.feedbackError
                                    ? "error"
                                    : "check_circle"
                            iconSize: 18
                            fill: WeatherMapPlugin.credentialBusy ? 0 : 1
                            color: root.feedbackError
                                ? Appearance.colors.colOnErrorContainer
                                : Appearance.colors.colOnPrimaryContainer
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.feedbackText
                            color: root.feedbackError
                                ? Appearance.colors.colOnErrorContainer
                                : Appearance.colors.colOnPrimaryContainer
                            font.family: Fonts.ui
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            textFormat: Text.PlainText
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Item {
                        Layout.fillWidth: true
                    }

                    Button {
                        text: qsTr("清除密钥")
                        flat: true
                        enabled: WeatherMapPlugin.apiConfigured
                            && !WeatherMapPlugin.credentialBusy
                        focusPolicy: Qt.StrongFocus
                        Material.foreground: Appearance.colors.colOnSurfaceVariant
                        Accessible.description: qsTr("从系统密钥环移除 OpenWeather API key")
                        onClicked: root.clearApiKey()
                    }

                    Button {
                        id: saveButton

                        text: qsTr("保存密钥")
                        highlighted: true
                        enabled: WeatherMapPlugin.credentialsReady
                            && !WeatherMapPlugin.credentialBusy
                            && apiKeyField.text.trim().length >= 16
                        focusPolicy: Qt.StrongFocus
                        Material.background: Appearance.colors.colPrimary
                        Material.foreground: Appearance.colors.colOnPrimary
                        Material.elevation: 2
                        Accessible.description: qsTr("安全保存并立即应用，无需重启")
                        onClicked: root.applyApiKey()

                        contentItem: Text {
                            text: saveButton.text
                            color: saveButton.enabled
                                ? Appearance.colors.colOnPrimary
                                : Appearance.applyAlpha(
                                    Appearance.colors.colOnSurface,
                                    0.72
                                )
                            font: saveButton.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            textFormat: Text.PlainText
                        }
                    }
                }
            }
        }

        MapTilerApiSettingsCard {
            Layout.fillWidth: true
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: helpContent.implicitHeight + 32
            radius: Appearance.rounding.normal
            color: Appearance.m3colors.m3surfaceContainerHigh

            RowLayout {
                id: helpContent

                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                MaterialSymbol {
                    Layout.alignment: Qt.AlignTop
                    text: "info"
                    iconSize: 21
                    color: Appearance.colors.colPrimary
                }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("密钥仅保存在系统密钥环中，不会写入项目配置或显示在界面中。")
                    color: Appearance.colors.colOnSurfaceVariant
                    font.family: Fonts.ui
                    font.pixelSize: 12
                    lineHeight: 1.35
                    wrapMode: Text.WordWrap
                    textFormat: Text.PlainText
                }
            }
        }
    }
}
