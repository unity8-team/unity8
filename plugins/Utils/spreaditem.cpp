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

#include "spreaditem.h"
#include "contentnode.h"
#include "shadownode.h"
#include <QtQuick/QQuickWindow>

#if defined(HAS_TEXTURED_SHADOW)
#include "spreaditemtexture.h"

const int maxShadowTextures = 16;

static struct { QOpenGLContext* openglContext; quint32 textureId; }
    shadowTextures[maxShadowTextures];

static int getShadowTexturesIndex(const QOpenGLContext* openglContext);
#endif

SpreadItem::SpreadItem(QQuickItem* parent)
    : QQuickItem(parent)
    , m_content(NULL)
    , m_contentTextureProvider(NULL)
    , m_contentTransform(1.0f, 1.0f, 0.0f, 0.0f)
    , m_contentAntialiasing(1.0f)
    , m_shadowSize(32.0f)
    , m_shadowOpacity(127)
    , m_flags(Opaque)
{
    setFlag(ItemHasContents);
}

void SpreadItem::setContent(const QVariant& content)
{
    QQuickItem* newContent = qobject_cast<QQuickItem*>(qvariant_cast<QObject*>(content));
    if (m_content != newContent) {
        if (newContent) {
            if (!newContent->parentItem()) {
                // Inlined images need a parent and must not be visible.
                newContent->setParentItem(this);
                newContent->setVisible(false);
            }
            m_flags |= DirtyContentTransform;
        }
        m_content = newContent;
        update();
        Q_EMIT contentChanged();
    }
}

void SpreadItem::setOpaqueContent(bool opaqueContent)
{
    if (!!(m_flags & Opaque) != opaqueContent) {
        m_flags ^= Opaque;
        update();
        Q_EMIT opaqueContentChanged();
    }
}

void SpreadItem::setStretchContent(bool stretchContent)
{
    if (!!(m_flags & Stretched) != stretchContent) {
        m_flags ^= Stretched;
        m_flags |= DirtyContentTransform;
        update();
        Q_EMIT stretchContentChanged();
    }
}

void SpreadItem::setHideContent(bool hideContent)
{
    if (!!(m_flags & ContentHidden) != hideContent) {
        m_flags ^= ContentHidden;
        m_flags |= DirtyContentHidden;
        update();
        Q_EMIT hideContentChanged();
    }
}

void SpreadItem::setContentAntialiasing(qreal contentAntialiasing)
{
    const float newContentAntialiasing =
        qBound(0.0f, static_cast<float>(contentAntialiasing), 1.5f);
    if (m_contentAntialiasing != newContentAntialiasing) {
        m_contentAntialiasing = newContentAntialiasing;
        update();
        Q_EMIT contentAntialiasingChanged();
    }
}

void SpreadItem::setShadowSize(qreal shadowSize)
{
    const float newShadowSize = qMax(0.0f, static_cast<float>(shadowSize));
    if (m_shadowSize != newShadowSize) {
        m_shadowSize = newShadowSize;
        update();
        Q_EMIT shadowSizeChanged();
    }
}

void SpreadItem::setShadowOpacity(qreal shadowOpacity)
{
    const quint8 newShadowOpacity = static_cast<quint8>(qBound(0.0, shadowOpacity * 255.0, 255.0));
    if (m_shadowOpacity != newShadowOpacity) {
        m_shadowOpacity = newShadowOpacity;
        update();
        Q_EMIT shadowOpacityChanged();
    }
}

#if defined(HAS_TEXTURED_SHADOW)
void SpreadItem::_q_openglContextDestroyed()
{
    // Delete the shadow textures that are stored per context and shared by all the SpreadItems.
    const int index = getShadowTexturesIndex(qobject_cast<QOpenGLContext*>(sender()));
    Q_ASSERT(index >= 0);
    shadowTextures[index].openglContext = NULL;
    glDeleteTextures(1, &shadowTextures[index].textureId);
}
#endif

void SpreadItem::_q_providerDestroyed(QObject* object)
{
    Q_UNUSED(object);
    m_contentTextureProvider = NULL;
}

void SpreadItem::_q_textureChanged()
{
    m_flags |= DirtyContentTransform;
    update();
}

void SpreadItem::geometryChanged(const QRectF& newGeometry, const QRectF& oldGeometry)
{
    QQuickItem::geometryChanged(newGeometry, oldGeometry);
    m_flags |= DirtyContentTransform;
}

#if defined(HAS_TEXTURED_SHADOW)
// Gets the shadowTextures' slot used by the given context, or -1 if not stored.
static int getShadowTexturesIndex(const QOpenGLContext* openglContext)
{
    int index = 0;
    while (shadowTextures[index].openglContext != openglContext) {
        index++;
        if (index == maxShadowTextures) {
            return -1;
        }
    }
    return index;
}

// Gets an empty shadowTextures' slot.
static int getEmptyShadowTexturesIndex()
{
    int index = 0;
    while (shadowTextures[index].openglContext) {
        index++;
        if (index == maxShadowTextures) {
            // Don't bother with a dynamic array, let's just set a high enough maxShadowTextures and
            // increase the static array size if ever needed.
            qFatal("reached maximum number of OpenGL contexts supported by SpreadItem");
        }
    }
    return index;
}
#endif

QSGNode* SpreadItem::updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* data)
{
    Q_UNUSED(data);

    const QSizeF itemSize(width(), height());
    if (itemSize.isEmpty()) {
        delete oldNode;
        return NULL;
    }

    // Create the node made of a parent with content and shadow children nodes.
    QSGNode* node;
    if (oldNode) {
        node = oldNode;
    } else {
        node = new QSGNode;
        if (!(m_flags & ContentHidden)) {
            node->appendChildNode(new ContentNode);
        }
        node->appendChildNode(new ShadowNode);
        m_flags &= ~DirtyContentHidden;
    }

    // Add or remove the content node as requested.
    if (m_flags & DirtyContentHidden) {
        if (m_flags & ContentHidden) {
            QSGNode* contentNode = node->firstChild();
            node->removeChildNode(contentNode);
            delete contentNode;
        } else {
            node->prependChildNode(new ContentNode);
        }
        m_flags &= ~DirtyContentHidden;
    }

#if defined(HAS_TEXTURED_SHADOW)
    // Get or create the shadow texture that's stored per context and shared by all the SpreadItems.
    Q_ASSERT(window());
    QOpenGLContext* openglContext = window()->openglContext();
    Q_ASSERT(openglContext);
    int index = getShadowTexturesIndex(openglContext);
    if (index < 0) {
        index = getEmptyShadowTexturesIndex();
        shadowTextures[index].openglContext = openglContext;
        glGenTextures(1, &shadowTextures[index].textureId);
        glBindTexture(GL_TEXTURE_2D, shadowTextures[index].textureId);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, shadowTextureSize, shadowTextureSize, 0,
                     GL_LUMINANCE, GL_UNSIGNED_BYTE, shadowTextureData);
        QObject::connect(openglContext, SIGNAL(aboutToBeDestroyed()), this,
                         SLOT(_q_openglContextDestroyed()), Qt::DirectConnection);
    }
    const quint32 shadowTextureId = shadowTextures[index].textureId;
#endif

    // Update the content transform if dirty.
    QSGTextureProvider* provider = m_content ? m_content->textureProvider() : NULL;
    QSGTexture* contentTexture = provider ? provider->texture() : NULL;
    if (contentTexture && (m_flags & DirtyContentTransform)) {
        const QSizeF textureSize = contentTexture->textureSize();
        float fillSx, fillSy;
        if (!(m_flags & Stretched)) {
            if (itemSize.width() <= textureSize.width()
                && itemSize.height() <= textureSize.height()) {
                // Padding with top left alignment.
              fillSx = itemSize.width() / textureSize.width();
              fillSy = itemSize.height() / textureSize.height();
            } else {
                // Preserve aspect cropping with top left alignment.
                const float textureRatio = textureSize.width() / textureSize.height();
                const float itemRatio = itemSize.width() / itemSize.height();
                fillSx = (textureRatio < itemRatio) ? 1.0f : (itemRatio / textureRatio);
                fillSy = (textureRatio < itemRatio) ? (textureRatio / itemRatio) : 1.0f;
            }
        } else {
            fillSx = 1.0f;
            fillSy = 1.0f;
        }
        const QRectF contentTextureRect = contentTexture->normalizedTextureSubRect();
        m_contentTransform = QVector4D(
            fillSx * contentTextureRect.width(), fillSy * contentTextureRect.height(),
            contentTextureRect.x(), contentTextureRect.y());
        m_contentCoordUnit = QVector2D(
            contentTextureRect.width() / textureSize.width(),
            contentTextureRect.height() / textureSize.height());
        m_flags &= ~DirtyContentTransform;
    }

    // Ensure the item is updated whenever the content item's texture changes.
    if (provider != m_contentTextureProvider) {
        if (m_contentTextureProvider) {
            QObject::disconnect(m_contentTextureProvider, SIGNAL(textureChanged()),
                                this, SLOT(_q_textureChanged()));
            QObject::disconnect(m_contentTextureProvider, SIGNAL(destroyed()),
                                this, SLOT(_q_providerDestroyed()));
        }
        if (provider) {
            QObject::connect(provider, SIGNAL(textureChanged()), this, SLOT(_q_textureChanged()));
            QObject::connect(provider, SIGNAL(destroyed()), this, SLOT(_q_providerDestroyed()));
        }
        m_contentTextureProvider = provider;
    }

    if (!(m_flags & ContentHidden)) {
        updateContentNode(node->firstChild(), itemSize, contentTexture != NULL);
#if defined(HAS_TEXTURED_SHADOW)
        updateShadowNode(node->lastChild(), itemSize, shadowTextureId, contentTexture != NULL);
#else
        updateShadowNode(node->lastChild(), itemSize, contentTexture != NULL);
#endif
    } else {
#if defined(HAS_TEXTURED_SHADOW)
        updateShadowNode(node->firstChild(), itemSize, shadowTextureId, contentTexture != NULL);
#else
        updateShadowNode(node->firstChild(), itemSize, contentTexture != NULL);
#endif
    }

    return node;
}

void SpreadItem::updateContentNode(QSGNode* node, const QSizeF& itemSize, bool textured)
{
    ContentMaterial* material = static_cast<ContentNode*>(node)->material();

    // Update material blending flag if needed.
    const bool needsBlendingOn = (opacity() < 1.0) || !(m_flags & Opaque);
    if (needsBlendingOn != !!(m_flags & ContentBlendingOn)) {
        material->setFlag(QSGMaterial::Blending, needsBlendingOn);
        node->markDirty(QSGNode::DirtyMaterial);
        m_flags ^= ContentBlendingOn;
    }

    // Update material data.
    ContentMaterial::Data* materialData = material->data();
    if (textured) {
        materialData->contentTextureProvider = m_contentTextureProvider;
        materialData->flags = ContentMaterial::Data::Textured;
    } else {
        materialData->contentTextureProvider = NULL;
        materialData->flags = 0;
    }

    // Update geometry. The shadow node takes care of rendering the 1 pixel border of the content
    // geometry with antialiasing and blending enabled so the position of the content node needs to
    // be adapted to not render that border.
    ContentNode::Vertex* v = reinterpret_cast<ContentNode::Vertex*>(
        static_cast<ContentNode*>(node)->geometry()->vertexData());
    v[0].position[0] = 1.0f;
    v[0].position[1] = 1.0f;
    v[0].contentCoordinate[0] = m_contentTransform.z() + m_contentCoordUnit.x();
    v[0].contentCoordinate[1] = m_contentTransform.w() + m_contentCoordUnit.y();
    v[1].position[0] = itemSize.width() - 1.0f;
    v[1].position[1] = 1.0f;
    v[1].contentCoordinate[0] =
        m_contentTransform.x() + m_contentTransform.z() - m_contentCoordUnit.x();
    v[1].contentCoordinate[1] = m_contentTransform.w() + m_contentCoordUnit.y();
    v[2].position[0] = 1.0f;
    v[2].position[1] = itemSize.height() - 1.0f;
    v[2].contentCoordinate[0] = m_contentTransform.z() + m_contentCoordUnit.x();
    v[2].contentCoordinate[1] =
        m_contentTransform.y() + m_contentTransform.w() - m_contentCoordUnit.y();
    v[3].position[0] = itemSize.width() - 1.0f;
    v[3].position[1] = itemSize.height() - 1.0f;
    v[3].contentCoordinate[0] =
        m_contentTransform.x() + m_contentTransform.z() - m_contentCoordUnit.x();
    v[3].contentCoordinate[1] =
         m_contentTransform.y() + m_contentTransform.w() - m_contentCoordUnit.x();
    node->markDirty(QSGNode::DirtyGeometry);
}

void SpreadItem::updateShadowNode(
#if defined(HAS_TEXTURED_SHADOW)
    QSGNode* node, const QSizeF& itemSize, quint32 shadowTextureId, bool textured)
#else
    QSGNode* node, const QSizeF& itemSize, bool textured)
#endif
{
    ShadowMaterial* material = static_cast<ShadowNode*>(node)->material();

    // Update material data.
    ShadowMaterial::Data* materialData = material->data();
    if (textured) {
        materialData->contentTextureProvider = m_contentTextureProvider;
        materialData->flags = ShadowMaterial::Data::Textured;
    } else {
        materialData->contentTextureProvider = NULL;
        materialData->flags = 0;
    }
#if defined(HAS_TEXTURED_SHADOW)
    materialData->shadowTextureId = shadowTextureId;
#endif
    materialData->shadowOpacity = m_shadowOpacity;

    // Update geometry. The shadow node takes care of rendering the 1 pixel border of the content
    // geometry with antialiasing and blending enabled so its position needs to be adapted to render
    // that border.
    ShadowNode::Vertex* v = reinterpret_cast<ShadowNode::Vertex*>(
        static_cast<ShadowNode*>(node)->geometry()->vertexData());
    const float contentFactorIn = 1.0f;
    const float contentFactorOut = -m_shadowSize / m_contentAntialiasing;
    // 1st row of 4 vertices.
    v[0].position[0] = -m_shadowSize;
    v[0].position[1] = -m_shadowSize;
    v[0].shadowCoordinate[0] = 0.0f;
    v[0].shadowCoordinate[1] = 0.0f;
    v[0].contentCoordinate[0] = m_contentTransform.z();
    v[0].contentCoordinate[1] = m_contentTransform.w();
    v[0].contentFactor = contentFactorOut;
    v[1].position[0] = 1.0f;
    v[1].position[1] = -m_shadowSize;
    v[1].shadowCoordinate[0] = 1.0f;
    v[1].shadowCoordinate[1] = 0.0f;
    v[1].contentCoordinate[0] = m_contentTransform.z();
    v[1].contentCoordinate[1] = m_contentTransform.w();
    v[1].contentFactor = contentFactorOut;
    v[2].position[0] = itemSize.width() - 1.0f;
    v[2].position[1] = -m_shadowSize;
    v[2].shadowCoordinate[0] = 1.0f;
    v[2].shadowCoordinate[1] = 0.0f;
    v[2].contentCoordinate[0] = m_contentTransform.x() + m_contentTransform.z();
    v[2].contentCoordinate[1] = m_contentTransform.w();
    v[2].contentFactor = contentFactorOut;
    v[3].position[0] = itemSize.width() + m_shadowSize;
    v[3].position[1] = -m_shadowSize;
    v[3].shadowCoordinate[0] = 0.0f;
    v[3].shadowCoordinate[1] = 0.0f;
    v[3].contentCoordinate[0] = m_contentTransform.x() + m_contentTransform.z();
    v[3].contentCoordinate[1] = m_contentTransform.w();
    v[3].contentFactor = contentFactorOut;
    // 2nd row of 4 vertices.
    v[4].position[0] = -m_shadowSize;
    v[4].position[1] = 1.0f;
    v[4].shadowCoordinate[0] = 0.0f;
    v[4].shadowCoordinate[1] = 1.0f;
    v[4].contentCoordinate[0] = m_contentTransform.z();
    v[4].contentCoordinate[1] = m_contentTransform.w();
    v[4].contentFactor = contentFactorOut;
    v[5].position[0] = 1.0f;
    v[5].position[1] = 1.0f;
    v[5].shadowCoordinate[0] = 1.0f;
    v[5].shadowCoordinate[1] = 1.0f;
    v[5].contentCoordinate[0] = m_contentTransform.z();
    v[5].contentCoordinate[1] = m_contentTransform.w();
    v[5].contentFactor = contentFactorIn;
    v[6].position[0] = itemSize.width() - 1.0f;
    v[6].position[1] = 1.0f;
    v[6].shadowCoordinate[0] = 1.0f;
    v[6].shadowCoordinate[1] = 1.0f;
    v[6].contentCoordinate[0] = m_contentTransform.x() + m_contentTransform.z();
    v[6].contentCoordinate[1] = m_contentTransform.w();
    v[6].contentFactor = contentFactorIn;
    v[7].position[0] = itemSize.width() + m_shadowSize;
    v[7].position[1] = 1.0f;
    v[7].shadowCoordinate[0] = 0.0f;
    v[7].shadowCoordinate[1] = 1.0f;
    v[7].contentCoordinate[0] = m_contentTransform.x() + m_contentTransform.z();
    v[7].contentCoordinate[1] = m_contentTransform.w();
    v[7].contentFactor = contentFactorOut;
    // 3rd row of 4 vertices.
    v[8].position[0] = -m_shadowSize;
    v[8].position[1] = itemSize.height() - 1.0f;
    v[8].shadowCoordinate[0] = 0.0f;
    v[8].shadowCoordinate[1] = 1.0f;
    v[8].contentCoordinate[0] = m_contentTransform.z();
    v[8].contentCoordinate[1] = m_contentTransform.y() + m_contentTransform.w();
    v[8].contentFactor = contentFactorOut;
    v[9].position[0] = 1.0f;
    v[9].position[1] = itemSize.height() - 1.0f;
    v[9].shadowCoordinate[0] = 1.0f;
    v[9].shadowCoordinate[1] = 1.0f;
    v[9].contentCoordinate[0] = m_contentTransform.z();
    v[9].contentCoordinate[1] = m_contentTransform.y() + m_contentTransform.w();
    v[9].contentFactor = contentFactorIn;
    v[10].position[0] = itemSize.width() - 1.0f;
    v[10].position[1] = itemSize.height() - 1.0f;
    v[10].shadowCoordinate[0] = 1.0f;
    v[10].shadowCoordinate[1] = 1.0f;
    v[10].contentCoordinate[0] = m_contentTransform.x() + m_contentTransform.z();
    v[10].contentCoordinate[1] = m_contentTransform.y() + m_contentTransform.w();
    v[10].contentFactor = contentFactorIn;
    v[11].position[0] = itemSize.width() + m_shadowSize;
    v[11].position[1] = itemSize.height() - 1.0f;
    v[11].shadowCoordinate[0] = 0.0f;
    v[11].shadowCoordinate[1] = 1.0f;
    v[11].contentCoordinate[0] = m_contentTransform.x() + m_contentTransform.z();
    v[11].contentCoordinate[1] = m_contentTransform.y() + m_contentTransform.w();
    v[11].contentFactor = contentFactorOut;
    // 4th row of 4 vertices.
    v[12].position[0] = -m_shadowSize;
    v[12].position[1] = itemSize.height() + m_shadowSize;
    v[12].shadowCoordinate[0] = 0.0f;
    v[12].shadowCoordinate[1] = 0.0f;
    v[12].contentCoordinate[0] = m_contentTransform.z();
    v[12].contentCoordinate[1] = m_contentTransform.y() + m_contentTransform.w();
    v[12].contentFactor = contentFactorOut;
    v[13].position[0] = 1.0f;
    v[13].position[1] = itemSize.height() + m_shadowSize;
    v[13].shadowCoordinate[0] = 1.0f;
    v[13].shadowCoordinate[1] = 0.0f;
    v[13].contentCoordinate[0] = m_contentTransform.z();
    v[13].contentCoordinate[1] = m_contentTransform.y() + m_contentTransform.w();
    v[13].contentFactor = contentFactorOut;
    v[14].position[0] = itemSize.width() - 1.0f;
    v[14].position[1] = itemSize.height() + m_shadowSize;
    v[14].shadowCoordinate[0] = 1.0f;
    v[14].shadowCoordinate[1] = 0.0f;
    v[14].contentCoordinate[0] = m_contentTransform.x() + m_contentTransform.z();
    v[14].contentCoordinate[1] = m_contentTransform.y() + m_contentTransform.w();
    v[14].contentFactor = contentFactorOut;
    v[15].position[0] = itemSize.width() + m_shadowSize;
    v[15].position[1] = itemSize.height() + m_shadowSize;
    v[15].shadowCoordinate[0] = 0.0f;
    v[15].shadowCoordinate[1] = 0.0f;
    v[15].contentCoordinate[0] = m_contentTransform.x() + m_contentTransform.z();
    v[15].contentCoordinate[1] = m_contentTransform.y() + m_contentTransform.w();
    v[15].contentFactor = contentFactorOut;
    node->markDirty(QSGNode::DirtyGeometry);
}
