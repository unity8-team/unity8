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
        QSize tmpSize = requestedSize;
        if (!requestedSize.isValid() || requestedSize.width() > 1024 || requestedSize.height() > 1024) {
            tmpSize = QSize(1024, 1024);
        }
        image = QImage::fromData(NotesStore::instance()->note(noteGuid)->resource(resourceHash)->imageData(tmpSize));
    } else if (mediaType.startsWith("audio")) {
        image.load("/usr/share/icons/ubuntu-mobile/actions/scalable/media-playback-start.svg");
    } else {
        image.load("/usr/share/icons/ubuntu-mobile/actions/scalable/help.svg");
    }
    *size = image.size();
    return image;
}
