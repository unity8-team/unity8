#include "resourceimageprovider.h"

#include <notesstore.h>
#include <note.h>

#include <QUrlQuery>
#include <QDebug>

ResourceImageProvider::ResourceImageProvider():
    QQuickImageProvider(QQuickImageProvider::Image)
{

}

QImage ResourceImageProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    QString mediaType = id.split("?").first();
    QUrlQuery arguments(id.split('?').last());
    QString noteGuid = arguments.queryItemValue("noteGuid");
    QString resourceHash = arguments.queryItemValue("hash");
    Note *note = NotesStore::instance()->note(noteGuid);
    if (!note) {
        qWarning() << "Unable to find note for resource:" << id;
        return QImage();
    }

    QImage image;
    if (mediaType.startsWith("image")) {
        qDebug() << "image requested" << NotesStore::instance()->note(noteGuid)->resource(resourceHash);
        image = QImage::fromData(NotesStore::instance()->note(noteGuid)->resource(resourceHash)->imageData(requestedSize));
        qDebug() << "done...";
    } else if (mediaType.startsWith("audio")) {
        image.load("/usr/share/icons/suru/mimetypes/scalable/audio-x-generic-symbolic.svg");
    } else if (mediaType == "application/pdf") {
        image.load("/usr/share/icons/suru/mimetypes/scalable/application-pdf-symbolic.svg");
    } else {
        image.load("/usr/share/icons/suru/mimetypes/scalable/empty-symbolic.svg");
    }

    *size = image.size();
    return image;
}
