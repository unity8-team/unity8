#ifndef RESOURCEIMAGEPROVIDER_H
#define RESOURCEIMAGEPROVIDER_H

#include <QQuickImageProvider>

class ResourceImageProvider : public QQuickImageProvider
{
public:
    explicit ResourceImageProvider();

    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize);

    void scale(QImage &image, const QSize &size);
    QImage loadIcon(const QString &name, const QSize &size);
};

#endif // RESOURCEIMAGEPROVIDER_H
