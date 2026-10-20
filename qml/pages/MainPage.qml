import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.Landscape | Orientation.Portrait

    readonly property color colorBg: "#0c0d10"
    readonly property color colorPanel: "#131419"
    readonly property color colorSurface: "#1a1c24"
    readonly property color colorBorder: "#2a2d3a"
    readonly property color colorAmber: "#e8a020"
    readonly property color colorGreen: "#3ddc84"
    readonly property color colorRed: "#ff4f4f"
    readonly property color colorBlue: "#4fa8ff"
    readonly property color colorText: "#d4d6e0"
    readonly property color colorMuted: "#666878"
    readonly property color colorTerminalBg: "#050608"
    readonly property color colorTerminalText: "#c8ffc8"
    readonly property color colorLogBg: "#0a0b0e"
    readonly property color colorLogText: "#8890a8"

    property string currentTab: "upload"
    property string filePath: ""
    property string uploadStatus: "Ready"


    property int progress: 0
    property string commandInput: ""

    Rectangle {
        anchors.fill: parent
        color: page.colorBg
    }

    Column {
        anchors.fill: parent

        Rectangle {
            width: parent.width
            height: 48
            color: "#0f1015"

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: page.colorBorder
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Image {
                    source: "../icons/bluetooth.svg"
                    sourceSize.width: 20
                    sourceSize.height: 20
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: 1
                    height: 20
                    color: page.colorBorder
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: pairLabel.width + 24
                    height: 26
                    radius: 2

                    color: backend.isConnected ? "transparent" : page.colorAmber
                    border.color: backend.isConnected ? page.colorRed : page.colorAmber
                    border.width: backend.isConnected ? 1 : 0
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        id: pairLabel
                        anchors.centerIn: parent

                        text: backend.isConnected ? "DISCONNECT" : "⬡  PAIR DEVICE"
                        color: backend.isConnected ? page.colorRed : "#0c0d10"
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 1.2
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: backend.toggleConnection()
                    }
                }

                Row {
                    spacing: 12
                    anchors.verticalCenter: parent.verticalCenter

                    DeviceIndicator {
                        slot: 1

                        connected: backend.isConnected
                        deviceName: backend.isConnected ? "STM32 (TCP)" : ""
                    }
                    DeviceIndicator {
                        slot: 2
                        connected: false
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 36
            color: "#0f1015"

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: page.colorBorder
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.bottom: parent.bottom
                height: parent.height
                spacing: 0

                TabButton {
                    text: "[ FIRMWARE UPLOAD ]"
                    active: page.currentTab === "upload"
                    onClicked: pager.contentX = 0
                }
                TabButton {
                    text: "[ SERIAL TERMINAL ]"
                    active: page.currentTab === "terminal"
                    onClicked: pager.contentX = pager.width
                }
            }
        }

        Item {
            id: contentArea
            width: parent.width
            height: parent.height - 48 - 36

            Flickable {
                id: pager
                anchors.fill: parent
                contentWidth: width * 2
                contentHeight: height
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                pressDelay: 100

                onMovementEnded: {
                    var target = (contentX < width / 2) ? 0 : width
                    if (contentX !== target) {
                        contentX = target
                    }
                }

                onContentXChanged: {
                    var newTab = (contentX < width / 2) ? "upload" : "terminal"
                    if (page.currentTab !== newTab) {
                        page.currentTab = newTab
                    }
                }

                Item {
                    x: 0
                    width: pager.width
                    height: pager.height

                    Flickable {
                        id: uploadFlick
                        anchors.fill: parent
                        contentWidth: width
                        contentHeight: uploadColumn.height + 24
                        flickableDirection: Flickable.VerticalFlick
                        clip: true

                        Column {
                            id: uploadColumn
                            width: parent.width - 24
                            x: 12
                            y: 12
                            spacing: 10

                            Section {
                                label: "FIRMWARE FILE"
                                width: parent.width

                                Row {
                                    width: parent.width
                                    spacing: 6

                                    Rectangle {
                                        width: parent.width - browseBtn.width - 6
                                        height: 28
                                        color: "#0a0b0e"
                                        border.color: page.colorBorder
                                        border.width: 1
                                        radius: 2

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 8
                                            anchors.right: parent.right
                                            anchors.rightMargin: 8
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: page.filePath || "No file selected..."
                                            color: page.filePath ? page.colorText : page.colorMuted
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Rectangle {
                                        id: browseBtn
                                        width: browseText.width + 16
                                        height: 28
                                        color: "transparent"
                                        border.color: page.colorBorder
                                        border.width: 1
                                        radius: 2

                                        Text {
                                            id: browseText
                                            anchors.centerIn: parent
                                            text: "BROWSE..."
                                            color: page.colorText
                                            font.pixelSize: 10
                                            font.bold: true
                                            font.letterSpacing: 1
                                        }

                                        MouseArea {
                                            anchors.fill: parent

                                            onClicked: page.filePath = "firmware.bin"
                                        }
                                    }
                                }
                            }

                            Text {
                                text: "▸ Передача через TCP/BLE — блоки по 128 байт · MTU 20 байт · протокол Nordic UART"
                                color: "#3a3f52"
                                font.pixelSize: 9
                                font.letterSpacing: 0.5
                                width: parent.width
                                wrapMode: Text.Wrap
                            }

                            Section {
                                label: "UPLOAD PROGRESS"
                                width: parent.width

                                Rectangle {
                                    id: progressTrack
                                    width: parent.width
                                    height: 6
                                    color: page.colorSurface
                                    border.color: page.colorBorder
                                    border.width: 1
                                    radius: 1

                                    Rectangle {
                                        width: progressTrack.width * (page.progress / 100)
                                        height: progressTrack.height - 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: 1
                                        color: page.colorAmber
                                    }
                                }

                                Item {
                                    width: parent.width
                                    height: 8
                                }

                                Row {
                                    width: parent.width
                                    height: 16

                                    Text {
                                        width: parent.width * 0.6
                                        height: parent.height
                                        text: page.uploadStatus
                                        color: page.colorLogText
                                        font.pixelSize: 10
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    Text {
                                        width: parent.width * 0.4
                                        height: parent.height
                                        text: page.progress + "%"
                                        color: page.progress === 100 ? page.colorGreen : page.colorMuted
                                        font.pixelSize: 10
                                        font.bold: true
                                        horizontalAlignment: Text.AlignRight
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }

                            Rectangle {
                                width: uploadBtnText.width + 40
                                height: 36
                                color: backend.isConnected ? page.colorAmber : page.colorSurface
                                border.color: backend.isConnected ? page.colorAmber : page.colorBorder
                                border.width: 1
                                radius: 2

                                Text {
                                    id: uploadBtnText
                                    anchors.centerIn: parent
                                    text: "▶  UPLOAD FIRMWARE"
                                    color: backend.isConnected ? "#0c0d10" : page.colorMuted
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.letterSpacing: 1
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (backend.isConnected) {
                                            console.log("Кнопка загрузки нажата, но логика еще не реализована");
                                            page.uploadStatus = "Waiting for logic...";
                                        }
                                    }
                                }
                            }

                            Section {
                                label: "UPLOAD LOG"
                                width: parent.width

                                Rectangle {
                                    width: parent.width
                                    height: 180
                                    color: page.colorLogBg
                                    border.color: page.colorBorder
                                    border.width: 1
                                    clip: true

                                    Flickable {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        contentWidth: width
                                        contentHeight: uploadLogText.implicitHeight
                                        clip: true
                                        flickableDirection: Flickable.VerticalFlick

                                        Text {
                                            id: uploadLogText
                                            width: parent.width
                                            text: backend.logText.length === 0 ? "-- awaiting events --" : backend.logText
                                            color: backend.logText.length === 0 ? "#3a3f52" : page.colorLogText
                                            font.pixelSize: 10
                                            font.family: "monospace"
                                            wrapMode: Text.Wrap
                                        }

                                        onContentHeightChanged: {
                                            if (contentHeight > height) {
                                                contentY = contentHeight - height;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    x: pager.width
                    width: pager.width
                    height: pager.height

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Row {
                            width: parent.width
                            spacing: 6

                            Rectangle {
                                width: parent.width - sendBtn.width - 6
                                height: 34
                                color: "#0a0b0e"
                                border.color: page.colorBorder
                                border.width: 1
                                radius: 2

                                TextInput {
                                    id: commandField
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: page.colorText
                                    font.pixelSize: 12
                                    font.family: "monospace"
                                    enabled: backend.isConnected
                                    clip: true
                                    selectByMouse: true
                                    onTextChanged: page.commandInput = text

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "Enter command..."
                                        color: page.colorMuted
                                        font.pixelSize: 12
                                        font.family: "monospace"
                                        visible: commandField.text.length === 0
                                    }
                                }
                            }

                            Rectangle {
                                id: sendBtn
                                width: sendText.width + 20
                                height: 34
                                color: (backend.isConnected && page.commandInput.length > 0)
                                       ? page.colorAmber : "transparent"
                                border.color: (backend.isConnected && page.commandInput.length > 0)
                                              ? page.colorAmber : page.colorBorder
                                border.width: 1
                                radius: 2

                                Text {
                                    id: sendText
                                    anchors.centerIn: parent
                                    text: "SEND  ↵"
                                    color: (backend.isConnected && page.commandInput.length > 0)
                                           ? "#0c0d10" : page.colorMuted
                                    font.pixelSize: 10
                                    font.bold: true
                                    font.letterSpacing: 1
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (backend.isConnected && page.commandInput.length > 0) {
                                            page.commandInput = ""
                                            commandField.text = ""
                                        }
                                    }
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            height: 20

                            Text {
                                text: "TERMINAL OUTPUT"
                                color: page.colorMuted
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 1.2
                                width: parent.width - clrBtn.width
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                            }

                            Rectangle {
                                id: clrBtn
                                width: clrText.width + 16
                                height: 20
                                color: "transparent"
                                border.color: page.colorBorder
                                border.width: 1
                                radius: 2

                                Text {
                                    id: clrText
                                    anchors.centerIn: parent
                                    text: "CLR"
                                    color: page.colorMuted
                                    font.pixelSize: 9
                                    font.bold: true
                                    font.letterSpacing: 1
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: page.terminalOutput = ""
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: parent.height - (34 + 10 + 20 + 10 + 10)
                            color: page.colorTerminalBg
                            border.color: page.colorBorder
                            border.width: 1

                            Flickable {
                                anchors.fill: parent
                                anchors.margins: 10
                                contentWidth: width
                                contentHeight: termText.height
                                clip: true
                                flickableDirection: Flickable.VerticalFlick

                                Text {
                                    id: termText
                                    width: parent.width
                                    text: backend.logText.length === 0
                                          ? "> waiting for connection..."
                                          : backend.logText
                                    color: backend.logText.length === 0
                                           ? "#1a3a1a" : page.colorTerminalText
                                    font.pixelSize: 11
                                    font.family: "monospace"
                                    wrapMode: Text.Wrap
                                    lineHeight: 1.5
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
