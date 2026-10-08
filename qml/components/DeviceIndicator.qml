import QtQuick 2.0
import Sailfish.Silica 1.0

Row {
    id: indicator
    property int slot: 1
    property bool connected: false
    property string deviceName: ""

    spacing: 5

    Text {
        text: "DEV " + (slot < 10 ? "0" + slot : slot)
        color: "#7a4f0a"
        font.pixelSize: 8
        font.letterSpacing: 0.8
        anchors.verticalCenter: parent.verticalCenter
    }

    Rectangle {
        width: 6
        height: 6
        radius: 3
        color: indicator.connected ? "#3ddc84" : "#ff4f4f"
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        text: indicator.connected
              ? (indicator.deviceName || "BLE DEVICE")
              : "NOT PAIRED"
        color: indicator.connected ? "#3ddc84" : "#666878"
        font.pixelSize: 9
        font.letterSpacing: 0.5
        anchors.verticalCenter: parent.verticalCenter
    }
}
