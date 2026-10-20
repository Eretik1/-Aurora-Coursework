#include <QtQuick>
#include <auroraapp.h>
#include "connectionmanager.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> application(Aurora::Application::application(argc, argv));
    application->setOrganizationName(QStringLiteral("ru.template"));
    application->setApplicationName(QStringLiteral("Lab_2"));

    ConnectionManager backend;

    QScopedPointer<QQuickView> view(Aurora::Application::createView());

    view->rootContext()->setContextProperty("backend", &backend);

    view->setSource(QUrl("qrc:/qml/Lab_2.qml"));
    view->show();

    return application->exec();
}
