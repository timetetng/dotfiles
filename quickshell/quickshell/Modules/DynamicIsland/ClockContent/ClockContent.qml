import QtQuick
import qs.config 

Item {
    id: root
    property var player 

    Row {
        anchors.centerIn: parent
        spacing: 8
        
        Text {
            id: timeTxt
            text: new Date().toLocaleString(Qt.locale("en_US"), "ddd dd MMM | hh:mm AP")
            
            color: "white"
 
            font.family: Sizes.fontFamily 
            
            font.pixelSize: 14
            
            font.bold: true
            
            anchors.verticalCenter: parent.verticalCenter
            
            Timer {
                interval: 1000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: timeTxt.text = new Date().toLocaleString(Qt.locale("en_US"), "ddd dd MMM | hh:mm AP")
            }
        }
    }
}
