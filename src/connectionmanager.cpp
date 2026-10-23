#include <QFile>
#include <QDir>
#include <QStandardPaths>
#include <QDateTime>
#include <QTextStream>
#include "connectionmanager.h"

ConnectionManager::ConnectionManager(QObject *parent) : QObject(parent) {

    connect(&m_socket, &QTcpSocket::connected, this, &ConnectionManager::onConnected);
    connect(&m_socket, &QTcpSocket::disconnected, this, &ConnectionManager::onDisconnected);
    connect(&m_socket, &QTcpSocket::readyRead, this, &ConnectionManager::onReadyRead);
    connect(&m_socket, static_cast<void (QAbstractSocket::*)(QAbstractSocket::SocketError)>(&QAbstractSocket::error),
            this, &ConnectionManager::onError);
    connect(&m_socket, &QTcpSocket::bytesWritten, this, [this](qint64 bytes) {
        if (m_totalBytesToSend > 0) {
            m_bytesSent += bytes;
            int percent = int((m_bytesSent * 100) / m_totalBytesToSend);
            if (percent > 100) percent = 100;
            emit progressChanged(percent);
        }
    });
    connect(&m_socket, &QTcpSocket::bytesWritten, this, &ConnectionManager::onBytesWritten);
}

void ConnectionManager::toggleConnection() {
    if (m_isConnected) {
        m_socket.disconnectFromHost();
    } else {
        appendLog("Попытка подключения к эмулятору (10.0.2.2)...");
        m_socket.connectToHost("10.0.2.2", 5555);
    }
}

void ConnectionManager::onConnected() {
    m_isConnected = true;
    emit isConnectedChanged();
    appendLog("SUCCESS: Connected to device.");
}

void ConnectionManager::onDisconnected() {
    m_isConnected = false;
    emit isConnectedChanged();
    appendLog("Connection closed.");

    if (m_targetConnected) {
        m_targetConnected = false;
        emit targetConnectedChanged();
    }

}

void ConnectionManager::onReadyRead() {
    QByteArray data = m_socket.readAll();
    QString text = QString::fromUtf8(data);

    appendLog(text.trimmed());

    if (text.contains("Bootloader sync OK") || text.contains("Target started")) {
        if (!m_targetConnected) {
            m_targetConnected = true;
            emit targetConnectedChanged();
            appendLog("[SYS] Target MCU detected and connected!");
        }
    }

    if (text.contains("Bootloader sync FAILED")) {
        if (m_targetConnected) {
            m_targetConnected = false;
            emit targetConnectedChanged();
            appendLog("[SYS] Target MCU disconnected!");
        }
    }
}

void ConnectionManager::onError(QAbstractSocket::SocketError) {
    m_isConnected = false;
    emit isConnectedChanged();
    appendLog("ERROR: " + m_socket.errorString());
}

void ConnectionManager::appendLog(const QString &msg) {
    m_logText += msg + "\n";
    emit logTextChanged();

    QString logDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(logDir);

    QFile file(logDir + "/app.log");
    if (file.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        QTextStream out(&file);
        QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss");
        out << "[" << timestamp << "] " << msg << "\n";
        file.close();
    }
}

void ConnectionManager::uploadFirmware(const QString &filePath) {
    if (!m_isConnected) {
        appendLog("ERROR: Device not connected.");
        return;
    }

    QString localPath = filePath;
    if (localPath.startsWith("file://")) {
        localPath = localPath.remove("file://");
    }


    QFile file(localPath);
    if (!file.open(QIODevice::ReadOnly)) {
        appendLog("ERROR: Cannot open file: " + filePath);
        return;
    }

    QByteArray fileData = file.readAll();
    file.close();

    if (fileData.size() > 14000) {
        appendLog("ERROR: File too big (max 14000 bytes). Current: " + QString::number(fileData.size()));
        return;
    }

    appendLog("Preparing to send: " + filePath);
    appendLog("File size: " + QString::number(fileData.size()) + " bytes");

    m_bytesSent = 0;
    m_uploadProgress = 0;
    emit uploadProgressChanged();

    m_totalBytesToSend = 4 + fileData.size();

    quint32 size = fileData.size();
    QByteArray header(4, 0);
    header[0] = char(size & 0xFF);
    header[1] = char((size >> 8) & 0xFF);
    header[2] = char((size >> 16) & 0xFF);
    header[3] = char((size >> 24) & 0xFF);

    m_socket.write(header);
    m_socket.write(fileData);

    appendLog("Firmware data sent successfully.");
}

void ConnectionManager::onBytesWritten(qint64 bytes) {
    if (m_totalBytesToSend > 0) {
        m_bytesSent += bytes;

        int percent = int((m_bytesSent * 100) / m_totalBytesToSend);
        if (percent > 100) percent = 100;

        if (percent != m_uploadProgress) {
            m_uploadProgress = percent;
            emit uploadProgressChanged();
        }
    }
}

void ConnectionManager::clearLog() {
    m_logText.clear();
    emit logTextChanged();
}
