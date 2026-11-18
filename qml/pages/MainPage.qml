import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import Sailfish.Pickers 1.0
import QtQuick.LocalStorage 2.0

Page {
    id: page
    allowedOrientations: Orientation.Landscape | Orientation.Portrait

    readonly property real uiScale: 1.5

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

    // ==========================================
    // БЛОК РАБОТЫ С БАЗОЙ ДАННЫХ (LocalStorage)
    // ==========================================
    function getDatabase() {
        return LocalStorage.openDatabaseSync("ProgrammerDB_v3", "1.0", "Programmer History", 1000000);
    }

    function initDatabase() {
        console.log("!!! INITIALIZING DATABASE...");
        var db = getDatabase();
        db.transaction(function(tx) {
            tx.executeSql('CREATE TABLE IF NOT EXISTS devices (' +
                          'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
                          'mac_address TEXT UNIQUE, ' +
                          'name TEXT, ' +
                          'last_connected TEXT)');

            tx.executeSql('CREATE TABLE IF NOT EXISTS firmwares (' +
                          'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
                          'file_name TEXT, ' +
                          'file_path TEXT, ' +
                          'file_size INTEGER, ' +
                          'created_at TEXT)');

            tx.executeSql('CREATE TABLE IF NOT EXISTS upload_history (' +
                          'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
                          'device_id INTEGER, ' +
                          'firmware_id INTEGER, ' +
                          'timestamp TEXT, ' +
                          'status TEXT)');
            console.log("!!! TABLES CREATED SUCCESSFULLY");
        });
        historyPage.refreshHistory();
    }
    // Вспомогательная функция: найти или создать устройство
    function getOrCreateDevice(tx, mac, name) {
        var rs = tx.executeSql('SELECT id FROM devices WHERE mac_address = ?', [mac]);
        if (rs.rows.length > 0) {
            return rs.rows.item(0).id;
        } else {
            var now = new Date().toLocaleString(Qt.locale(), "yyyy-MM-dd HH:mm:ss");
            var res = tx.executeSql('INSERT INTO devices (mac_address, name, last_connected) VALUES (?, ?, ?)', [mac, name, now]);
            return res.insertId;
        }
    }

    // Вспомогательная функция: найти или создать прошивку
    function getOrCreateFirmware(tx, fileName, filePath, fileSize) {
        // Ищем по пути и размеру
        var rs = tx.executeSql('SELECT id FROM firmwares WHERE file_path = ? AND file_size = ?', [filePath, fileSize]);
        if (rs.rows.length > 0) {
            return rs.rows.item(0).id;
        } else {
            var now = new Date().toLocaleString(Qt.locale(), "yyyy-MM-dd HH:mm:ss");
            var res = tx.executeSql('INSERT INTO firmwares (file_name, file_path, file_size, created_at) VALUES (?, ?, ?, ?)', [fileName, filePath, fileSize, now]);
            return res.insertId;
        }
    }

    function saveToHistory(fileName, filePath, fileSize) {
        var db = getDatabase();
        var now = new Date().toLocaleString(Qt.locale(), "yyyy-MM-dd HH:mm:ss");

        db.transaction(function(tx) {
            // Пока используем фейковый MAC-адрес, так как подключаемся по TCP
            var fakeMac = "00:11:22:33:44:55";
            var devId = getOrCreateDevice(tx, fakeMac, "STM32 (TCP)");
            var fwId = getOrCreateFirmware(tx, fileName, filePath, fileSize);

            tx.executeSql('INSERT INTO upload_history (device_id, firmware_id, timestamp, status) VALUES (?, ?, ?, ?)',
                          [devId, fwId, now, 'SUCCESS']);
        });

        historyPage.refreshHistory();
    }

    function loadHistoryFromDB() {
        var list = [];
        var db = getDatabase();
        db.readTransaction(function(tx) {
            // Делаем JOIN трех таблиц, чтобы получить красивые данные для списка
            var rs = tx.executeSql(
                'SELECT h.timestamp, d.name as device_name, f.file_name, f.file_size, h.status ' +
                'FROM upload_history h ' +
                'JOIN devices d ON h.device_id = d.id ' +
                'JOIN firmwares f ON h.firmware_id = f.id ' +
                'ORDER BY h.id DESC LIMIT 50'
            );
            for (var i = 0; i < rs.rows.length; i++) {
                list.push({
                    "time": rs.rows.item(i).timestamp,
                    "device": rs.rows.item(i).device_name,
                    "file": rs.rows.item(i).file_name,
                    "size": rs.rows.item(i).file_size,
                    "status": rs.rows.item(i).status
                });
            }
        });
        return list;
    }

    function clearHistoryDB() {
        var db = getDatabase();
        db.transaction(function(tx) {
            tx.executeSql('DELETE FROM upload_history');
            // Прошивки и устройства можно не удалять, они привязаны к истории
        });
        historyPage.refreshHistory();
    }
    // ==========================================

    Component.onCompleted: {
        initDatabase();
    }

    Connections {
        target: backend
        onFirmwareUploaded: {
            console.log("Saving to DB: " + fileName + " | " + filePath);
            saveToHistory(fileName, filePath, fileSize);
        }
    }
    // Компонент выбора файла
    Component {
        id: filePickerPage
        FilePickerPage {
            nameFilters: [ '*.bin', '*' ]
            onSelectedContentPropertiesChanged: {
                page.filePath = selectedContentProperties.filePath
                pageStack.pop()
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: page.colorBg
    }

    Column {
        anchors.fill: parent

        // --- ВЕРХНЯЯ ПАНЕЛЬ ---
        Rectangle {
            width: parent.width
            height: 48 * page.uiScale
            color: "#0f1015"

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: page.colorBorder
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 12 * page.uiScale
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10 * page.uiScale

                Image {
                    source: "../icons/bluetooth.svg"
                    sourceSize.width: 20 * page.uiScale
                    sourceSize.height: 20 * page.uiScale
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: 1
                    height: 20 * page.uiScale
                    color: page.colorBorder
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: pairLabel.width + 24 * page.uiScale
                    height: 26 * page.uiScale
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
                        font.pixelSize: 10 * page.uiScale
                        font.bold: true
                        font.letterSpacing: 1.2
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: backend.toggleConnection()
                    }
                }

                Row {
                    spacing: 12 * page.uiScale
                    anchors.verticalCenter: parent.verticalCenter

                    DeviceIndicator {
                        slot: 1
                        connected: backend.isConnected
                        deviceName: backend.isConnected ? "STM32" : ""
                        scale: page.uiScale
                    }
                    DeviceIndicator {
                        slot: 2
                        connected: backend.targetConnected
                        deviceName: backend.targetConnected ? "Target MCU" : ""
                        scale: page.uiScale
                    }
                }
            }
        }

        // --- ПАНЕЛЬ ВКЛАДОК ---
        Rectangle {
            width: parent.width
            height: 36 * page.uiScale
            color: "#0f1015"

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: page.colorBorder
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 12 * page.uiScale
                anchors.bottom: parent.bottom
                height: parent.height
                spacing: 0

                TabButton {
                    text: "[ UPLOAD ]"
                    active: page.currentTab === "upload"
                    onClicked: pager.contentX = 0
                    scale: page.uiScale
                }
                TabButton {
                    text: "[ TERMINAL ]"
                    active: page.currentTab === "terminal"
                    onClicked: pager.contentX = pager.width
                    scale: page.uiScale
                }
                TabButton {
                    text: "[ HISTORY ]"
                    active: page.currentTab === "history"
                    onClicked: pager.contentX = pager.width * 2
                    scale: page.uiScale
                }
            }
        }

        Item {
            id: contentArea
            width: parent.width
            height: parent.height - (48 * page.uiScale) - (36 * page.uiScale)

            Flickable {
                id: pager
                anchors.fill: parent
                contentWidth: width * 3
                contentHeight: height
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                pressDelay: 100

                onMovementEnded: {
                    var target = Math.round(contentX / width) * width
                    if (contentX !== target) contentX = target
                }

                onContentXChanged: {
                    var tabIndex = Math.round(contentX / width)
                    var newTab = tabIndex === 0 ? "upload" : (tabIndex === 1 ? "terminal" : "history")
                    if (page.currentTab !== newTab) page.currentTab = newTab
                }

                // --- ВКЛАДКА 1: UPLOAD ---
                Item {
                    x: 0
                    width: pager.width
                    height: pager.height

                    Flickable {
                        id: uploadFlick
                        anchors.fill: parent
                        contentWidth: width
                        contentHeight: uploadColumn.height + 24 * page.uiScale
                        flickableDirection: Flickable.VerticalFlick
                        clip: true

                        Column {
                            id: uploadColumn
                            width: parent.width - 24 * page.uiScale
                            x: 12 * page.uiScale
                            y: 12 * page.uiScale
                            spacing: 10 * page.uiScale

                            Section {
                                label: "FIRMWARE FILE"
                                width: parent.width
                                scale: page.uiScale

                                Row {
                                    width: parent.width
                                    spacing: 6 * page.uiScale

                                    Rectangle {
                                        width: parent.width - browseBtn.width - 6 * page.uiScale
                                        height: 28 * page.uiScale
                                        color: "#0a0b0e"
                                        border.color: page.colorBorder
                                        border.width: 1
                                        radius: 2

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 8 * page.uiScale
                                            anchors.right: parent.right
                                            anchors.rightMargin: 8 * page.uiScale
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: page.filePath || "No file selected..."
                                            color: page.filePath ? page.colorText : page.colorMuted
                                            font.pixelSize: 11 * page.uiScale
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Rectangle {
                                        id: browseBtn
                                        width: browseText.width + 16 * page.uiScale
                                        height: 28 * page.uiScale
                                        color: "transparent"
                                        border.color: page.colorBorder
                                        border.width: 1
                                        radius: 2

                                        Text {
                                            id: browseText
                                            anchors.centerIn: parent
                                            text: "BROWSE..."
                                            color: page.colorText
                                            font.pixelSize: 10 * page.uiScale
                                            font.bold: true
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: pageStack.push(filePickerPage)
                                        }
                                    }
                                }
                            }

                            Section {
                                label: "UPLOAD PROGRESS"
                                width: parent.width
                                scale: page.uiScale

                                Rectangle {
                                    id: progressTrack
                                    width: parent.width
                                    height: 6 * page.uiScale
                                    color: page.colorSurface
                                    border.color: page.colorBorder
                                    border.width: 1
                                    radius: 1

                                    Rectangle {
                                        width: progressTrack.width * (backend.uploadProgress / 100.0)
                                        height: progressTrack.height - 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: 1
                                        color: page.colorAmber
                                    }
                                }

                                Item { width: parent.width; height: 8 * page.uiScale }

                                Row {
                                    width: parent.width
                                    height: 16 * page.uiScale

                                    Text {
                                        width: parent.width * 0.6
                                        height: parent.height
                                        text: page.uploadStatus
                                        color: page.colorLogText
                                        font.pixelSize: 10 * page.uiScale
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    Text {
                                        width: parent.width * 0.4
                                        height: parent.height
                                        text: backend.uploadProgress + "%"
                                        color: backend.uploadProgress === 100 ? page.colorGreen : page.colorMuted
                                        font.pixelSize: 10 * page.uiScale
                                        font.bold: true
                                        horizontalAlignment: Text.AlignRight
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }

                            Rectangle {
                                width: uploadBtnText.width + 40 * page.uiScale
                                height: 36 * page.uiScale
                                color: backend.isConnected ? page.colorAmber : page.colorSurface
                                border.color: backend.isConnected ? page.colorAmber : page.colorBorder
                                border.width: 1
                                radius: 2

                                Text {
                                    id: uploadBtnText
                                    anchors.centerIn: parent
                                    text: "▶  UPLOAD FIRMWARE"
                                    color: backend.isConnected ? "#0c0d10" : page.colorMuted
                                    font.pixelSize: 11 * page.uiScale
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (backend.isConnected && page.filePath !== "") {
                                            page.uploadStatus = "Sending..."
                                            backend.uploadFirmware(page.filePath)
                                        }
                                    }
                                }
                            }

                            Section {
                                label: "UPLOAD LOG"
                                width: parent.width
                                scale: page.uiScale

                                Rectangle {
                                    width: parent.width
                                    height: 180 * page.uiScale
                                    color: page.colorLogBg
                                    border.color: page.colorBorder
                                    border.width: 1
                                    clip: true

                                    Flickable {
                                        anchors.fill: parent
                                        anchors.margins: 8 * page.uiScale
                                        contentWidth: width
                                        contentHeight: uploadLogText.implicitHeight
                                        clip: true
                                        flickableDirection: Flickable.VerticalFlick

                                        Text {
                                            id: uploadLogText
                                            width: parent.width
                                            text: backend.logText.length === 0 ? "-- awaiting events --" : backend.logText
                                            color: backend.logText.length === 0 ? "#3a3f52" : page.colorLogText
                                            font.pixelSize: 10 * page.uiScale
                                            font.family: "monospace"
                                            wrapMode: Text.Wrap
                                        }

                                        onContentHeightChanged: {
                                            if (contentHeight > height) contentY = contentHeight - height;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // --- ВКЛАДКА 2: TERMINAL ---
                Item {
                    x: pager.width
                    width: pager.width
                    height: pager.height

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12 * page.uiScale
                        spacing: 10 * page.uiScale

                        Row {
                            width: parent.width
                            spacing: 6 * page.uiScale

                            Rectangle {
                                width: parent.width - sendBtn.width - 6 * page.uiScale
                                height: 34 * page.uiScale
                                color: "#0a0b0e"
                                border.color: page.colorBorder
                                border.width: 1
                                radius: 2

                                TextInput {
                                    id: commandField
                                    anchors.fill: parent
                                    anchors.leftMargin: 10 * page.uiScale
                                    anchors.rightMargin: 10 * page.uiScale
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: page.colorText
                                    font.pixelSize: 12 * page.uiScale
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
                                        font.pixelSize: 12 * page.uiScale
                                        visible: commandField.text.length === 0
                                    }
                                }
                            }

                            Rectangle {
                                id: sendBtn
                                width: sendText.width + 20 * page.uiScale
                                height: 34 * page.uiScale
                                color: (backend.isConnected && page.commandInput.length > 0) ? page.colorAmber : "transparent"
                                border.color: (backend.isConnected && page.commandInput.length > 0) ? page.colorAmber : page.colorBorder
                                border.width: 1
                                radius: 2

                                Text {
                                    id: sendText
                                    anchors.centerIn: parent
                                    text: "SEND  ↵"
                                    color: (backend.isConnected && page.commandInput.length > 0) ? "#0c0d10" : page.colorMuted
                                    font.pixelSize: 10 * page.uiScale
                                    font.bold: true
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
                            height: 20 * page.uiScale

                            Text {
                                text: "TERMINAL OUTPUT"
                                color: page.colorMuted
                                font.pixelSize: 9 * page.uiScale
                                font.bold: true
                                width: parent.width - clrBtn.width
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                            }

                            Rectangle {
                                id: clrBtn
                                width: clrText.width + 16 * page.uiScale
                                height: 20 * page.uiScale
                                color: "transparent"
                                border.color: page.colorBorder
                                border.width: 1
                                radius: 2

                                Text {
                                    id: clrText
                                    anchors.centerIn: parent
                                    text: "CLR"
                                    color: page.colorMuted
                                    font.pixelSize: 9 * page.uiScale
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: backend.clearLog()
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: parent.height - (34 + 10 + 20 + 10 + 10) * page.uiScale
                            color: page.colorTerminalBg
                            border.color: page.colorBorder
                            border.width: 1
                            clip: true

                            Flickable {
                                anchors.fill: parent
                                anchors.margins: 10 * page.uiScale
                                contentWidth: width
                                contentHeight: termText.implicitHeight
                                clip: true
                                flickableDirection: Flickable.VerticalFlick

                                Text {
                                    id: termText
                                    width: parent.width
                                    text: backend.logText.length === 0 ? "> waiting for connection..." : backend.logText
                                    color: backend.logText.length === 0 ? "#1a3a1a" : page.colorTerminalText
                                    font.pixelSize: 11 * page.uiScale
                                    font.family: "monospace"
                                    wrapMode: Text.Wrap
                                }

                                onContentHeightChanged: {
                                    if (contentHeight > height) contentY = contentHeight - height;
                                }
                            }
                        }
                    }
                }

                // --- ВКЛАДКА 3: HISTORY ---
                Item {
                    id: historyPage
                    x: pager.width * 2
                    width: pager.width
                    height: pager.height

                    function refreshHistory() {
                        historyModel.clear();
                        var data = loadHistoryFromDB();
                        for (var i = 0; i < data.length; i++) {
                            historyModel.append(data[i]);
                        }
                    }

                    Component.onCompleted: refreshHistory()

                    Connections {
                        target: page
                        onCurrentTabChanged:{
                            if (page.currentTab === "history") {
                                historyPage.refreshHistory();
                            }
                        }
                    }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12 * page.uiScale
                        spacing: 10 * page.uiScale

                        Row {
                            width: parent.width
                            Text {
                                text: "UPLOAD HISTORY"
                                color: page.colorMuted
                                font.pixelSize: 10 * page.uiScale
                                font.bold: true
                                width: parent.width - clrHistoryBtn.width
                                verticalAlignment: Text.AlignVCenter
                            }
                            Rectangle {
                                id: clrHistoryBtn
                                width: 60 * page.uiScale
                                height: 22 * page.uiScale
                                color: "transparent"
                                border.color: page.colorBorder
                                Text {
                                    anchors.centerIn: parent
                                    text: "CLEAR"
                                    color: page.colorRed
                                    font.pixelSize: 9 * page.uiScale
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: clearHistoryDB()
                                }
                            }
                        }

                        ListView {
                            id: historyList
                            width: parent.width
                            height: parent.height - 30 * page.uiScale
                            clip: true
                            spacing: 4 * page.uiScale

                            model: ListModel { id: historyModel }

                            delegate: Rectangle {
                                width: historyList.width
                                height: 45 * page.uiScale
                                color: page.colorSurface
                                border.color: page.colorBorder

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 6 * page.uiScale
                                    Text {
                                        text: model.file + " (" + model.size + " b)"
                                        color: page.colorText
                                        font.pixelSize: 12 * page.uiScale
                                    }
                                    Text {
                                        text: model.time + " | STM32" // Убрали model.device, так как в LocalStorage его нет
                                        color: page.colorMuted
                                        font.pixelSize: 9 * page.uiScale
                                    }
                                }

                                Text {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.rightMargin: 8 * page.uiScale
                                    text: model.status
                                    color: model.status === "SUCCESS" ? page.colorGreen : page.colorRed
                                    font.pixelSize: 10 * page.uiScale
                                    font.bold: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
