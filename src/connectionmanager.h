#pragma once
#include <QObject>
#include <QString>
#include <QTcpSocket>

class ConnectionManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY isConnectedChanged)
    Q_PROPERTY(QString logText READ logText NOTIFY logTextChanged)
    Q_PROPERTY(int uploadProgress READ uploadProgress NOTIFY uploadProgressChanged)
    Q_PROPERTY(bool targetConnected READ targetConnected NOTIFY targetConnectedChanged)

public:
    explicit ConnectionManager(QObject *parent = nullptr);

    bool isConnected() const { return m_isConnected; }
    QString logText() const { return m_logText; }
    int uploadProgress() const { return m_uploadProgress; }
    bool targetConnected() const { return m_targetConnected; }

    Q_INVOKABLE void toggleConnection();
    Q_INVOKABLE void uploadFirmware(const QString &filePath);
    Q_INVOKABLE void clearLog();

signals:
    void isConnectedChanged();
    void logTextChanged();
    void progressChanged(int percent);
    void uploadProgressChanged();
    void targetConnectedChanged();

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
    bool m_targetConnected = false;

    QTcpSocket m_socket;
    bool m_isConnected = false;
    QString m_logText;
};
