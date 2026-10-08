#include <QtQuick>
#include <auroraapp.h>

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> application(Aurora::Application::application(argc, argv));
    application->setOrganizationName(QStringLiteral("ru.template"));
    application->setApplicationName(QStringLiteral("Lab_2"));

    QScopedPointer<QQuickView> view(Aurora::Application::createView());
    view->setSource(QUrl("qrc:/qml/Lab_2.qml"));
    view->show();

    return application->exec();
}
