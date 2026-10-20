#pragma once
#include <QObject>
#include <QString>
#include <QTcpSocket>

class ConnectionManager : public QObject {
    Q_OBJECT
    // Свойства, которые QML будет читать и на которые будет реагировать
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY isConnectedChanged)
    Q_PROPERTY(QString logText READ logText NOTIFY logTextChanged)

public:
    explicit ConnectionManager(QObject *parent = nullptr);

    bool isConnected() const { return m_isConnected; }
    QString logText() const { return m_logText; }

    // Методы, которые будут вызываться из QML
    Q_INVOKABLE void toggleConnection();

signals:
    void isConnectedChanged();
    void logTextChanged();

private slots:
    void onConnected();
    void onDisconnected();
    void onReadyRead();
    void onError(QAbstractSocket::SocketError socketError);

private:
    void appendLog(const QString &msg);

    QTcpSocket m_socket;
    bool m_isConnected = false;
    QString m_logText;
};
