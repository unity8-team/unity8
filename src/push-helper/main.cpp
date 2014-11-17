#include <QCoreApplication>

#include <QFile>
#include <QStandardPaths>

#include <QDebug>

int main(int argc, char* argv[])
{
    QCoreApplication a(argc, argv);

    QFile f("/home/phablet/.cache/com.ubuntu.reminders/push-helper-test-file.txt");

    qDebug() << "writing to file:" << f.fileName();
    f.open(QFile::WriteOnly);

    QByteArray data;
    data = QString("push-helper called with args %1").arg(a.arguments().join(", ")).toUtf8();
    f.write(data);
}
