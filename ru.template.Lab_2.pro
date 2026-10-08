TARGET = ru.template.Lab_2

CONFIG += \
    auroraapp

PKGCONFIG += \

SOURCES += \
    src/main.cpp \

HEADERS += \

DISTFILES += \
    qml/Lab_2.qml \
    qml/pages/MainPage.qml \
    qml/cover/DefaultCoverPage.qml \
    qml/components/DeviceIndicator.qml \
    qml/components/Section.qml \
    qml/components/TabButton.qml \
    rpm/ru.template.Lab_2.spec \

AURORAAPP_ICONS = 86x86 108x108 128x128 172x172

CONFIG += auroraapp_i18n

TRANSLATIONS += \
    translations/ru.template.Lab_2.ts \
    translations/ru.template.Lab_2-ru.ts \

QT += qml quick
QT += svg
RESOURCES += resources.qrc
