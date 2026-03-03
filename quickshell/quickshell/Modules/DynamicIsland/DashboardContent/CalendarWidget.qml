import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config 

Rectangle {
    id: root
    
    // 样式设定
    color: Colorsheme.background
    radius: 18

    // ================== 日历逻辑 ==================
    ListModel { id: calendarModel }
    property string currentMonthName: ""
    property int todayDate: new Date().getDate()

    function generateCalendar() {
        calendarModel.clear();
        let now = new Date();
        let year = now.getFullYear();
        let month = now.getMonth();
        let monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
        root.currentMonthName = monthNames[month];
        let startDay = (new Date(year, month, 1).getDay() + 6) % 7; 
        let daysInMonth = new Date(year, month + 1, 0).getDate();
        let daysInPrevMonth = new Date(year, month, 0).getDate();

        for (let i = 0; i < startDay; i++) calendarModel.append({ "dayText": daysInPrevMonth - startDay + 1 + i, "isCurrentMonth": false, "isToday": false });
        for (let i = 1; i <= daysInMonth; i++) calendarModel.append({ "dayText": i, "isCurrentMonth": true, "isToday": (i === root.todayDate) });
        for (let i = 1; i <= (42 - calendarModel.count); i++) calendarModel.append({ "dayText": i, "isCurrentMonth": false, "isToday": false });
    }

    Component.onCompleted: generateCalendar()

    // ================== 界面布局 ==================
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 5
        
        // 1. 月份标题
        Text {
            text: root.currentMonthName
            color: "#DDD"
            font.family: Sizes.fontFamily
            font.pixelSize: 18
            font.bold: true
            Layout.leftMargin: 2
        }
        
        // 2. 星期头 (Mo, Tu...)
        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                Item {
                    Layout.fillWidth: true; Layout.preferredHeight: 20
                    Text { 
                        anchors.centerIn: parent
                        text: modelData
                        color: "#777"
                        font.family: Sizes.fontFamily
                        font.pixelSize: 12
                        font.bold: true 
                    }
                }
            }
        }
        
        // 3. 日期网格
        GridLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            columns: 7; columnSpacing: 0; rowSpacing: 10
            Repeater {
                model: calendarModel
                Item {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    Rectangle {
                        width: 24; height: 24; radius: 12
                        anchors.centerIn: parent
                        color: model.isToday ? "#F4C242" : "transparent"
                    }
                    Text {
                        anchors.centerIn: parent
                        text: model.dayText
                        font.family: Sizes.fontFamily
                        font.pixelSize: 13
                        font.bold: model.isToday
                        color: !model.isCurrentMonth ? "#444" : (model.isToday ? "black" : "#EEE")
                    }
                }
            }
        }
    }
}
