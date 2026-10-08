import QtQuick 2.0
import Sailfish.Silica 1.0

Rectangle {
    id: section
    property string label: ""
    default property alias content: innerColumn.data

    color: "#131419"
    border.color: "#2a2d3a"
    border.width: 1
    radius: 3
    implicitHeight: innerColumn.implicitHeight + 24
    implicitWidth: innerColumn.implicitWidth + 24

    Column {
        id: innerColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 6

        Text {
            text: section.label
            color: "#666878"
            font.pixelSize: 9
            font.bold: true
            font.letterSpacing: 1.2
        }
    }
}
