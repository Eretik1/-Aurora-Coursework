import QtQuick 2.0

Rectangle {
    id: tabButton
    property string text: ""
    property bool active: false
    signal clicked()
    property real scale: 1.2

    width: label.width + 40
    height: 36 * scale
    color: "transparent"

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 2
        color: tabButton.active ? "#e8a020" : "transparent"
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: tabButton.text
        color: tabButton.active ? "#e8a020" : "#666878"
        font.pixelSize: 10 * scale
        font.bold: true
        font.letterSpacing: 1.2

    }

    MouseArea {
        anchors.fill: parent
        onClicked: tabButton.clicked()
    }
}
