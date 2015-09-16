// Copyright © 2015 Canonical Ltd.
//
// This program is free software; you can redistribute it and/or modify it under the terms of the
// GNU Lesser General Public License as published by the Free Software Foundation; version 3.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
// even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License along with this program.
// If not, see <http://www.gnu.org/licenses/>.
//
// Author: Loïc Molinari <loic.molinari@canonical.com>

#ifndef SPREADITEM_H
#define SPREADITEM_H

#include <QtQuick/QQuickItem>
#include <QtGui/QVector4D>

class SpreadItem : public QQuickItem
{
    Q_OBJECT
    Q_PROPERTY(QVariant content READ content WRITE setContent NOTIFY contentChanged)
    Q_PROPERTY(bool opaqueContent READ opaqueContent WRITE setOpaqueContent
               NOTIFY opaqueContentChanged)
    Q_PROPERTY(bool stretchContent READ stretchContent WRITE setStretchContent
               NOTIFY stretchContentChanged)
    Q_PROPERTY(bool __hideContentNode READ hideContent WRITE setHideContent
               NOTIFY hideContentChanged)
    Q_PROPERTY(qreal contentAntialiasing READ contentAntialiasing WRITE setContentAntialiasing
               NOTIFY contentAntialiasingChanged)
    Q_PROPERTY(qreal shadowSize READ shadowSize WRITE setShadowSize NOTIFY shadowSizeChanged)
    Q_PROPERTY(qreal shadowOpacity READ shadowOpacity WRITE setShadowOpacity
               NOTIFY shadowOpacityChanged)

public:
    SpreadItem(QQuickItem* parent=0);
    QVariant content() const { return QVariant::fromValue(m_content); }
    void setContent(const QVariant& content);
    bool opaqueContent() const { return m_flags & Opaque; }
    void setOpaqueContent(bool opaqueContent);
    bool stretchContent() const { return m_flags & Stretched; }
    void setStretchContent(bool stretchContent);
    bool hideContent() const { return m_flags & ContentHidden; }
    void setHideContent(bool hideContent);
    qreal contentAntialiasing() const { return static_cast<qreal>(m_contentAntialiasing); }
    void setContentAntialiasing(qreal contentAntialiasing);
    qreal shadowSize() const { return static_cast<qreal>(m_shadowSize); }
    void setShadowSize(qreal shadowSize);
    qreal shadowOpacity() const { return m_shadowOpacity / 255.0; }
    void setShadowOpacity(qreal shadowOpacity);

Q_SIGNALS:
    void contentChanged();
    void opaqueContentChanged();
    void stretchContentChanged();
    void hideContentChanged();
    void contentAntialiasingChanged();
    void shadowSizeChanged();
    void shadowOpacityChanged();

protected:
    virtual QSGNode* updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* data);
    virtual void geometryChanged(const QRectF& newGeometry, const QRectF& oldGeometry);

    void updateContentNode(QSGNode* node, const QSizeF& itemSize, bool textured);
    void updateShadowNode(
#if defined(HAS_TEXTURED_SHADOW)
        QSGNode* node, const QSizeF& itemSize, quint32 shadowTextureId, bool textured);
#else
        QSGNode* node, const QSizeF& itemSize, bool textured);
#endif

private Q_SLOTS:
#if defined(HAS_TEXTURED_SHADOW)
    void _q_openglContextDestroyed();
#endif
    void _q_providerDestroyed(QObject* object=0);
    void _q_textureChanged();

private:
    enum {
        DirtyContentTransform = (1 << 0),
        Stretched             = (1 << 1),
        Opaque                = (1 << 2),
        ContentBlendingOn     = (1 << 3),
        ContentHidden         = (1 << 4),
        DirtyContentHidden    = (1 << 5)
    };

    QQuickItem* m_content;
    QSGTextureProvider* m_contentTextureProvider;
    QVector4D m_contentTransform;
    QVector2D m_contentCoordUnit;
    float m_contentAntialiasing;
    float m_shadowSize;
    quint8 m_shadowOpacity;
    quint8 m_flags;

    Q_DISABLE_COPY(SpreadItem)
};

QML_DECLARE_TYPE(SpreadItem)

#endif  // SPREADITEM_H
