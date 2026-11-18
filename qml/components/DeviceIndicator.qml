import QtQuick 2.0
import Sailfish.Silica 1.0

Row {
    id: indicator
    property int slot: 1
    property bool connected: false
    property string deviceName: ""
    property real scale: 1.0

    spacing: 5 * scale

    Text {
        text: "DEV " + (slot < 10 ? "0" + slot : slot)
        color: "#7a4f0a"
        font.pixelSize: 8 * scale
        font.letterSpacing: 0.8
        anchors.verticalCenter: parent.verticalCenter
    }

    Rectangle {
        width: 6 * scale
        height: 6 * scale
        radius: 3 * scale
        color: indicator.connected ? "#3ddc84" : "#ff4f4f"
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        width: 60 * scale
        text: connected ? (deviceName || "READY") : "NOT PAIRED"
        color: connected ? "#3ddc84" : "#666878"
        font.pixelSize: 10 * scale
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
