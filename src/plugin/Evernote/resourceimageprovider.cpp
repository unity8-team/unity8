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
    QUrlQuery arguments(id.split('?').last());
    QString noteGuid = arguments.queryItemValue("noteGuid");
    QString resourceHash = arguments.queryItemValue("hash");
    Note *note = NotesStore::instance()->note(noteGuid);
    if (!note) {
        qWarning() << "Unable to find note for resource:" << id;
        return QImage();
    }

    QImage image = NotesStore::instance()->note(noteGuid)->resource(resourceHash);
    *size = image.size();

    if (requestedSize.isValid()) {
        if (requestedSize.height() > 0 && requestedSize.width() > 0) {
            image = image.scaled(requestedSize);
        } else if (requestedSize.height() > 0) {
            image = image.scaledToHeight(requestedSize.height());
        } else {
            image = image.scaledToWidth(requestedSize.width());
        }
        *size = requestedSize;
    }
    return image;
}
