#include "connectionmanager.h"

ConnectionManager::ConnectionManager(QObject *parent) : QObject(parent) {

    connect(&m_socket, &QTcpSocket::connected, this, &ConnectionManager::onConnected);
    connect(&m_socket, &QTcpSocket::disconnected, this, &ConnectionManager::onDisconnected);
    connect(&m_socket, &QTcpSocket::readyRead, this, &ConnectionManager::onReadyRead);
    connect(&m_socket, static_cast<void (QAbstractSocket::*)(QAbstractSocket::SocketError)>(&QAbstractSocket::error),
            this, &ConnectionManager::onError);
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
    appendLog("УСПЕХ: Подключено к устройству.");
}

void ConnectionManager::onDisconnected() {
    m_isConnected = false;
    emit isConnectedChanged();
    appendLog("Соединение разорвано.");
}

void ConnectionManager::onReadyRead() {

    QByteArray data = m_socket.readAll();
    appendLog(QString::fromUtf8(data).trimmed());
}

void ConnectionManager::onError(QAbstractSocket::SocketError) {
    m_isConnected = false;
    emit isConnectedChanged();
    appendLog("ОШИБКА: " + m_socket.errorString());
}

void ConnectionManager::appendLog(const QString &msg) {
    m_logText += msg + "\n";
    emit logTextChanged();
}
