/*
 * Copyright (C) 2015 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "dropshadow.h"
#include "dropshadowtexture.h"
#include <QtQuick/QQuickWindow>
#include <QtQuick/QSGNode>
#include <QtQuick/QSGMaterial>
#include <QtGui/QOpenGLContext>
#include <QtGui/QOpenGLFunctions>

const float maxSize = 512.0f;
const float maxDistance = 512.0f;
const int maxTextures = 16;

static struct { QOpenGLContext* openglContext; quint32 textureId; } textures[maxTextures];

class DropShadowMaterial : public QSGMaterial
{
public:
    struct Data {
        // To be kept in sync with QuickPlusDropShadow flags.
        enum { FilterDirty = (1 << 0) };

        quint32 textureId;
        GLint filter;
        quint8 flags;
    };

    DropShadowMaterial();
    virtual QSGMaterialType* type() const;
    virtual QSGMaterialShader* createShader() const;
    virtual int compare(const QSGMaterial* other) const;
    const Data* constData() const { return &m_data; }
    Data* data() { return &m_data; }

private:
    Data m_data;
};

// --- Shader ---

class DropShadowShader : public QSGMaterialShader
{
public:
    DropShadowShader();
    virtual char const* const* attributeNames() const;
    virtual void initialize();
    virtual void updateState(
        const RenderState& state, QSGMaterial* newEffect, QSGMaterial* oldEffect);

private:
    int m_matrixId;
    int m_opacityId;
};

DropShadowShader::DropShadowShader()
{
    setShaderSourceFile(QOpenGLShader::Vertex, QStringLiteral(":/shaders/dropshadow.vert"));
    setShaderSourceFile(QOpenGLShader::Fragment, QStringLiteral(":/shaders/dropshadow.frag"));
}

char const* const* DropShadowShader::attributeNames() const
{
    static char const* const attributes[] = {
        "positionAttrib", "shadowCoordAttrib", "colorAttrib", 0
    };
    return attributes;
}

void DropShadowShader::initialize()
{
    QSGMaterialShader::initialize();
    program()->bind();
    program()->setUniformValue("texture", 0);
    m_matrixId = program()->uniformLocation("matrix");
    m_opacityId = program()->uniformLocation("opacity");
}

void DropShadowShader::updateState(
    const RenderState& state, QSGMaterial* newEffect, QSGMaterial* oldEffect)
{
    Q_UNUSED(oldEffect);

    QOpenGLFunctions* funcs = QOpenGLContext::currentContext()->functions();
    const DropShadowMaterial::Data* data = static_cast<DropShadowMaterial*>(newEffect)->constData();
    funcs->glBindTexture(GL_TEXTURE_2D, data->textureId);
    if (data->flags & DropShadowMaterial::Data::FilterDirty) {
        funcs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, data->filter);
        funcs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, data->filter);
    }

    if (state.isMatrixDirty()) {
        program()->setUniformValue(m_matrixId, state.combinedMatrix());
    }
    if (state.isOpacityDirty()) {
        program()->setUniformValue(m_opacityId, state.opacity());
    }
}

// --- Material ---

DropShadowMaterial::DropShadowMaterial()
{
    memset(&m_data, 0, sizeof(Data));
    setFlag(Blending, true);
}

QSGMaterialType* DropShadowMaterial::type() const
{
    static QSGMaterialType type;
    return &type;
}

QSGMaterialShader* DropShadowMaterial::createShader() const
{
    return new DropShadowShader;
}

int DropShadowMaterial::compare(const QSGMaterial* other) const
{
    const DropShadowMaterial::Data* otherData =
        static_cast<const DropShadowMaterial*>(other)->constData();
    return memcmp(&m_data, otherData, sizeof(m_data));
}

// --- Node ---

class DropShadowNode : public QSGGeometryNode
{
public:
    struct Vertex {
        float position[2];
        float shadowCoordinate[2];
        quint32 color;
    };

    static const unsigned short* indices();
    static const QSGGeometry::AttributeSet& attributeSet();

    DropShadowNode();
    DropShadowMaterial* material() { return &m_material; }
    QSGGeometry* geometry() { return &m_geometry; }

private:
    DropShadowMaterial m_material;
    QSGGeometry m_geometry;
};

DropShadowNode::DropShadowNode()
    : QSGGeometryNode()
    , m_material()
    , m_geometry(attributeSet(), 16, 18, GL_UNSIGNED_SHORT)
{
    memcpy(m_geometry.indexData(), indices(), 18 * sizeof(unsigned short));
    m_geometry.setDrawingMode(GL_TRIANGLE_STRIP);
    m_geometry.setIndexDataPattern(QSGGeometry::StaticPattern);
    m_geometry.setVertexDataPattern(QSGGeometry::AlwaysUploadPattern);
    setMaterial(&m_material);
    setGeometry(&m_geometry);
#ifdef QSG_RUNTIME_DESCRIPTION
    qsgnode_set_description(this, QLatin1String("dropshadow"));
#endif
}

// static
const unsigned short* DropShadowNode::indices()
{
    // The geometry is made of 16 vertices indexed with a triangle strip mode.
    //     0 ---- 1 ---- 2
    //     |  3 - 4 - 5  |
    //     |  |       |  |
    //     6  7       8  9
    //     |  |       |  |
    //     | 10 -11 - 12 |
    //     13----14 ----15
    static const unsigned short indices[] = {
        0, 3, 1, 4, 2, 5, 9, 8, 15, 12, 14, 11, 13, 10, 6, 7, 0, 3
    };
    return indices;
}

// static
const QSGGeometry::AttributeSet& DropShadowNode::attributeSet()
{
    static const QSGGeometry::Attribute attributes[] = {
        QSGGeometry::Attribute::create(0, 2, GL_FLOAT, true),
        QSGGeometry::Attribute::create(1, 2, GL_FLOAT),
        QSGGeometry::Attribute::create(2, 4, GL_UNSIGNED_BYTE)
    };
    static const QSGGeometry::AttributeSet attributeSet = {
        3, sizeof(Vertex), attributes
    };
    return attributeSet;
}

// --- Item ---

static quint16 quantizeToU16(float value, float higherBound)
{
    const float u16Max = static_cast<float>(std::numeric_limits<quint16>::max());
    Q_ASSERT(higherBound >= 0.0f || higherBound <= u16Max);
    Q_ASSERT(value >= 0.0f || value <= u16Max);
    return static_cast<quint16>((value * (u16Max / higherBound)) + 0.5f);
}

static float unquantizeFromU16(quint16 value, float higherBound)
{
    const float u16Max = static_cast<float>(std::numeric_limits<quint16>::max());
    Q_ASSERT(higherBound >= 0.0f || higherBound <= u16Max);
    return static_cast<float>(value) * (higherBound / u16Max);
}

QuickPlusDropShadow::QuickPlusDropShadow(QQuickItem* parent)
    : QQuickItem(parent)
    , m_color(qRgba(0, 0, 0, 255))
    , m_size(quantizeToU16(30, maxSize))
    , m_angle(0)
    , m_distance(0)
    , m_quality(Low)
    , m_flags(FilterDirty)
{
    setOpacity(0.5);
    setFlag(ItemHasContents);
}

qreal QuickPlusDropShadow::size() const
{
    return unquantizeFromU16(m_size, maxSize);
}

void QuickPlusDropShadow::setSize(qreal size)
{
    const quint16 quantizedSize =
        quantizeToU16(qBound(0.0f, static_cast<float>(size), maxSize), maxSize);
    if (m_size != quantizedSize) {
        m_size = quantizedSize;
        update();
        Q_EMIT sizeChanged();
    }
}

qreal QuickPlusDropShadow::angle() const
{
    return unquantizeFromU16(m_angle, 360.0f);
}

void QuickPlusDropShadow::setAngle(qreal angle)
{
    const quint16 quantizedAngle =
        quantizeToU16(qBound(0.0f, static_cast<float>(angle), 360.0f), 360.0f);
    if (m_angle != quantizedAngle) {
        m_angle = quantizedAngle;
        update();
        Q_EMIT angleChanged();
    }
}

qreal QuickPlusDropShadow::distance() const
{
    return unquantizeFromU16(m_distance, maxDistance);
}

void QuickPlusDropShadow::setDistance(qreal distance)
{
    const quint16 quantizedDistance =
        quantizeToU16(qBound(0.0f, static_cast<float>(distance), maxDistance), maxDistance);
    if (m_distance != quantizedDistance) {
        m_distance = quantizedDistance;
        update();
        Q_EMIT distanceChanged();
    }
}

QColor QuickPlusDropShadow::color() const
{
    return QColor(qRed(m_color), qGreen(m_color), qBlue(m_color), qAlpha(m_color));
}

void QuickPlusDropShadow::setColor(const QColor& color)
{
    const QRgb rgbColor = qRgba(color.red(), color.green(), color.blue(), color.alpha());
    if (m_color != rgbColor) {
        m_color = rgbColor;
        update();
        Q_EMIT colorChanged();
    }
}

QuickPlusDropShadow::Quality QuickPlusDropShadow::quality() const
{
    return static_cast<Quality>(m_quality);
}

void QuickPlusDropShadow::setQuality(Quality quality)
{
    if (m_quality != quality) {
        m_quality = quality;
        m_flags |= FilterDirty;
        update();
        Q_EMIT qualityChanged();
    }
}

// Gets the textures' slot used by the given context, or -1 if not stored.
static int getTexturesIndex(const QOpenGLContext* openglContext)
{
    int index = 0;
    while (textures[index].openglContext != openglContext) {
        index++;
        if (index == maxTextures) {
            return -1;
        }
    }
    return index;
}

// Gets an empty textures' slot.
static int getEmptyTexturesIndex()
{
    int index = 0;
    while (textures[index].openglContext) {
        index++;
        if (index == maxTextures) {
            // Don't bother with a dynamic array, let's just set a high enough
            // maxTextures and increase the static array size if ever needed.
            qFatal("reached maximum number of OpenGL contexts supported by QuickPlusDropShadow");
        }
    }
    return index;
}

// Pack a color in a premultiplied 32-bit ABGR value.
static quint32 packColor(QRgb color)
{
    const quint32 a = qAlpha(color);
    const quint32 b = ((qBlue(color) * a) + 0xff) >> 8;
    const quint32 g = ((qGreen(color) * a) + 0xff) >> 8;
    const quint32 r = ((qRed(color) * a) + 0xff) >> 8;
    return (a << 24) | ((b & 0xff) << 16) | ((g & 0xff) << 8) | (r & 0xff);
}

QSGNode* QuickPlusDropShadow::updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* data)
{
    Q_UNUSED(data);

    const QSizeF itemSize(width(), height());
    if (itemSize.isEmpty()) {
        delete oldNode;
        return NULL;
    }

    // Get the texture stored per context and shared by all the drop shadows.
    Q_ASSERT(window());
    QOpenGLContext* openglContext = window()->openglContext();
    Q_ASSERT(openglContext);
    int index = getTexturesIndex(openglContext);
    if (index < 0) {
        QOpenGLFunctions* funcs = openglContext->functions();
        index = getEmptyTexturesIndex();
        textures[index].openglContext = openglContext;
        funcs->glGenTextures(1, &textures[index].textureId);
        funcs->glBindTexture(GL_TEXTURE_2D, textures[index].textureId);
        funcs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        funcs->glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        for (int i = 0; i < dropShadowMipmapCount; i++) {
            funcs->glTexImage2D(GL_TEXTURE_2D, i, GL_LUMINANCE, dropShadowBaseLevelSize >> i,
                                dropShadowBaseLevelSize >> i, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE,
                                &dropShadowData[dropShadowOffsets[i]]);
        }
        connect(
            openglContext, &QOpenGLContext::aboutToBeDestroyed, [index] {
                QOpenGLFunctions* funcs = textures[index].openglContext->functions();
                funcs->glDeleteTextures(1, &textures[index].textureId);
                textures[index].openglContext = NULL;
            });
    }

    QSGNode* node = oldNode ? oldNode : new DropShadowNode;

    // Update node's material.
    const int filters[2] = { GL_LINEAR, GL_LINEAR_MIPMAP_LINEAR };
    DropShadowMaterial::Data* materialData = static_cast<DropShadowNode*>(node)->material()->data();
    materialData->textureId = textures[index].textureId;
    materialData->filter = filters[m_quality];
    materialData->flags = (m_flags & FilterDirty);
    m_flags = 0;

    // Update node's geometry.
    DropShadowNode::Vertex* v = reinterpret_cast<DropShadowNode::Vertex*>(
        static_cast<DropShadowNode*>(node)->geometry()->vertexData());
    const float halfWidth = itemSize.width() * 0.5f;
    const float halfHeight = itemSize.height() * 0.5f;
    const float size = qMin(qMin(halfWidth, halfHeight), unquantizeFromU16(m_size, maxSize));
    const float shadowMiddleS = (halfWidth + size) / (2.0f * size);
    const float shadowMiddleT = (halfHeight + size) / (2.0f * size);
    const quint32 color = packColor(m_color);
    // 1st row
    v[0].position[0] = -size;
    v[0].position[1] = -size;
    v[0].shadowCoordinate[0] = 0.0f;
    v[0].shadowCoordinate[1] = 0.0f;
    v[0].color = color;
    v[1].position[0] = halfWidth;
    v[1].position[1] = -size;
    v[1].shadowCoordinate[0] = shadowMiddleS;
    v[1].shadowCoordinate[1] = 0.0f;
    v[1].color = color;
    v[2].position[0] = itemSize.width() + size;
    v[2].position[1] = -size;
    v[2].shadowCoordinate[0] = 0.0f;
    v[2].shadowCoordinate[1] = 0.0f;
    v[2].color = color;
    // 2nd row
    v[3].position[0] = 0.0f;
    v[3].position[1] = 0.0f;
    v[3].shadowCoordinate[0] = 0.5f;
    v[3].shadowCoordinate[1] = 0.5f;
    v[3].color = color;
    v[4].position[0] = halfWidth;
    v[4].position[1] = 0.0f;
    v[4].shadowCoordinate[0] = shadowMiddleS;
    v[4].shadowCoordinate[1] = 0.5f;
    v[4].color = color;
    v[5].position[0] = itemSize.width();
    v[5].position[1] = 0.0f;
    v[5].shadowCoordinate[0] = 0.5f;
    v[5].shadowCoordinate[1] = 0.5f;
    v[5].color = color;
    // 3rd row
    v[6].position[0] = -size;
    v[6].position[1] = halfHeight;
    v[6].shadowCoordinate[0] = 0.0f;
    v[6].shadowCoordinate[1] = shadowMiddleT;
    v[6].color = color;
    v[7].position[0] = 0.0f;
    v[7].position[1] = halfHeight;
    v[7].shadowCoordinate[0] = 0.5f;
    v[7].shadowCoordinate[1] = shadowMiddleT;
    v[7].color = color;
    v[8].position[0] = itemSize.width();
    v[8].position[1] = halfHeight;
    v[8].shadowCoordinate[0] = 0.5f;
    v[8].shadowCoordinate[1] = shadowMiddleT;
    v[8].color = color;
    v[9].position[0] = itemSize.width() + size;
    v[9].position[1] = halfHeight;
    v[9].shadowCoordinate[0] = 0.0f;
    v[9].shadowCoordinate[1] = shadowMiddleT;
    v[9].color = color;
    // 4th row
    v[10].position[0] = 0.0f;
    v[10].position[1] = itemSize.height();
    v[10].shadowCoordinate[0] = 0.5f;
    v[10].shadowCoordinate[1] = 0.5f;
    v[10].color = color;
    v[11].position[0] = halfWidth;
    v[11].position[1] = itemSize.height();
    v[11].shadowCoordinate[0] = shadowMiddleS;
    v[11].shadowCoordinate[1] = 0.5f;
    v[11].color = color;
    v[12].position[0] = itemSize.width();
    v[12].position[1] = itemSize.height();
    v[12].shadowCoordinate[0] = 0.5f;
    v[12].shadowCoordinate[1] = 0.5f;
    v[12].color = color;
    // 5th row
    v[13].position[0] = -size;
    v[13].position[1] = itemSize.height() + size;
    v[13].shadowCoordinate[0] = 0.0f;
    v[13].shadowCoordinate[1] = 0.0f;
    v[13].color = color;
    v[14].position[0] = halfWidth;
    v[14].position[1] = itemSize.height() + size;
    v[14].shadowCoordinate[0] = shadowMiddleS;
    v[14].shadowCoordinate[1] = 0.0f;
    v[14].color = color;
    v[15].position[0] = itemSize.width() + size;
    v[15].position[1] = itemSize.height() + size;
    v[15].shadowCoordinate[0] = 0.0f;
    v[15].shadowCoordinate[1] = 0.0f;
    v[15].color = color;
    node->markDirty(QSGNode::DirtyGeometry);

    return node;
}
