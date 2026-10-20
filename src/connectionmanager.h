#pragma once
#include <QObject>
#include <QString>
#include <QTcpSocket>

class ConnectionManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY isConnectedChanged)
    Q_PROPERTY(QString logText READ logText NOTIFY logTextChanged)
    Q_PROPERTY(int uploadProgress READ uploadProgress NOTIFY uploadProgressChanged)

public:
    explicit ConnectionManager(QObject *parent = nullptr);

    bool isConnected() const { return m_isConnected; }
    QString logText() const { return m_logText; }
    int uploadProgress() const { return m_uploadProgress; }

    Q_INVOKABLE void toggleConnection();
    Q_INVOKABLE void uploadFirmware(const QString &filePath);

signals:
    void isConnectedChanged();
    void logTextChanged();
    void progressChanged(int percent);
    void uploadProgressChanged();

private slots:
    void onConnected();
    void onDisconnected();
    void onReadyRead();
    void onError(QAbstractSocket::SocketError socketError);
    void onBytesWritten(qint64 bytes);

private:
    void appendLog(const QString &msg);
    qint64 m_totalBytesToSend = 0;
    qint64 m_bytesSent = 0;
    int m_uploadProgress = 0;

    QTcpSocket m_socket;
    bool m_isConnected = false;
    QString m_logText;
};
