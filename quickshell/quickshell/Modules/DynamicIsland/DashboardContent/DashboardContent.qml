import QtQuick
import QtQuick.Layouts
import qs.config 

Item {
    id: root

    RowLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 15
        
        // 1. 左侧：日历组件
        CalendarWidget {
            Layout.fillHeight: true
            // 保持之前的 45% 宽度比例
            Layout.preferredWidth: parent.width * 0.45
        }
        
        // 2. 右侧：天气组件
        WeatherWidget {
            Layout.fillHeight: true
            Layout.fillWidth: true
        }
    }
}
