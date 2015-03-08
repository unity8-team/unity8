#include "resourceimageprovider.h"
#include "logging.h"

#include <notesstore.h>
#include <note.h>

#include <QUrlQuery>
#include <QFileInfo>

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
    bool isLoaded = arguments.queryItemValue("loaded") == "true";
    Note *note = NotesStore::instance()->note(noteGuid);
    if (!note) {
        qCWarning(dcNotesStore) << "Unable to find note for resource:" << id;
        return QImage();
    }

    QImage image;
    if (mediaType.startsWith("image")) {
        if (isLoaded) {
            QSize tmpSize = requestedSize;
            if (!requestedSize.isValid() || requestedSize.width() > 1024 || requestedSize.height() > 1024) {
                tmpSize = QSize(1024, 1024);
            }
            image = QImage::fromData(NotesStore::instance()->note(noteGuid)->resource(resourceHash)->imageData(tmpSize));
        } else {
            image = loadIcon("image-x-generic-symbolic", requestedSize);
        }
    } else if (mediaType.startsWith("audio")) {
        image = loadIcon("audio-x-generic-symbolic", requestedSize);
    } else if (mediaType == "application/pdf") {
        image = loadIcon("application-pdf-symbolic", requestedSize);
    } else {
        image = loadIcon("empty-symbolic", requestedSize);
    }

    *size = image.size();
    return image;
}

QImage ResourceImageProvider::loadIcon(const QString &name, const QSize &size)
{
    QString path = QString("/home/phablet/.cache/com.ubuntu.reminders/%1_%2x%3.png").arg(name).arg(size.width()).arg(size.height());
    QFileInfo fi(path);
    if (fi.exists()) {
        QImage image;
        image.load(path);
        return image;
    }

    QString svgPath = "/usr/share/icons/suru/mimetypes/scalable/" + name + ".svg";
    QImage image;
    image.load(svgPath);
    if (size.height() > 0 && size.width() > 0) {
        image = image.scaled(size, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    } else if (size.height() > 0) {
        image = image.scaledToHeight(size.height(), Qt::SmoothTransformation);
    } else if (size.width() > 0) {
        image = image.scaledToWidth(size.width(), Qt::SmoothTransformation);
    }
    image.save(path);
    return image;
}
