#include "core.h"

#include <QCoreApplication>
#include <QFile>
#include <QStandardPaths>
#include <QDebug>

int main(int argc, char* argv[])
{
    qDebug() << "Starting reminders app push helper aa";
    QCoreApplication a(argc, argv);
    QCoreApplication::setApplicationName("com.ubuntu.reminders");
    qDebug() << "bb";

    QFile inputFile(a.arguments().at(1));
    inputFile.open(QFile::ReadOnly);

    qDebug() << "cc";

    QByteArray data = inputFile.readAll();

    qDebug() << "dd";

    Core core;
    QObject::connect(&core, &Core::finished, &a, &QCoreApplication::exit);
    core.process(data);

    a.exec();

    qDebug() << "exiting...";
    // Do we want to fire a notification? Here's the place, by writing to the file at args[2]
}
