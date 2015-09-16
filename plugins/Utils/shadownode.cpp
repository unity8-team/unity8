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

#include "shadownode.h"

ShadowShader::ShadowShader()
{
    setShaderSourceFile(QOpenGLShader::Vertex, QStringLiteral(":/glsl/shadow.vert"));
#if defined(HAS_TEXTURED_SHADOW)
    setShaderSourceFile(QOpenGLShader::Fragment, QStringLiteral(":/glsl/shadowtexture.frag"));
#else
    setShaderSourceFile(QOpenGLShader::Fragment, QStringLiteral(":/glsl/shadow.frag"));
#endif
}

char const* const* ShadowShader::attributeNames() const
{
    static char const* const attributes[] = {
      "positionAttrib", "shadowCoordAttrib", "contentCoordAttrib", "contentFactorAttrib", 0
    };
    return attributes;
}

void ShadowShader::initialize()
{
    QSGMaterialShader::initialize();

#if defined(HAS_TEXTURED_SHADOW)
    program()->bind();
    program()->setUniformValue("shadowTexture", 0);
    program()->setUniformValue("contentTexture", 1);
    m_functions = QOpenGLContext::currentContext()->functions();
#endif

    m_opacityId = program()->uniformLocation("opacity");
    m_matrixId = program()->uniformLocation("matrix");
    m_texturedId = program()->uniformLocation("textured");
    m_shadowOpacityId = program()->uniformLocation("shadowOpacity");
}

void ShadowShader::updateState(
    const RenderState& state, QSGMaterial* newEffect, QSGMaterial* oldEffect)
{
    Q_UNUSED(oldEffect);

    const ShadowMaterial::Data* data = static_cast<ShadowMaterial*>(newEffect)->constData();
#if defined(HAS_TEXTURED_SHADOW)
    glBindTexture(GL_TEXTURE_2D, data->shadowTextureId);
#endif
    bool textured = false;
    if (data->flags & ShadowMaterial::Data::Textured) {
        const QSGTextureProvider* provider = data->contentTextureProvider;
        QSGTexture* contentTexture = provider ? provider->texture() : NULL;
        if (contentTexture) {
#if defined(HAS_TEXTURED_SHADOW)
            m_functions->glActiveTexture(GL_TEXTURE1);
            contentTexture->bind();
            m_functions->glActiveTexture(GL_TEXTURE0);
#else
            contentTexture->bind();
#endif
            textured = true;
        }
    }
    program()->setUniformValue(m_texturedId, textured);
    program()->setUniformValue(m_shadowOpacityId, data->shadowOpacity / 255.0f);

    if (state.isOpacityDirty()) {
        program()->setUniformValue(m_opacityId, state.opacity());
    }
    if (state.isMatrixDirty()) {
        program()->setUniformValue(m_matrixId, state.combinedMatrix());
    }
}

ShadowMaterial::ShadowMaterial()
{
    memset(&m_data, 0, sizeof(Data));
    setFlag(Blending, true);
}

QSGMaterialType* ShadowMaterial::type() const
{
    static QSGMaterialType type;
    return &type;
}

QSGMaterialShader* ShadowMaterial::createShader() const
{
    return new ShadowShader;
}

int ShadowMaterial::compare(const QSGMaterial* other) const
{
    const ShadowMaterial::Data* otherData = static_cast<const ShadowMaterial*>(other)->constData();
    return memcmp(&m_data, otherData, sizeof(m_data));
}

ShadowNode::ShadowNode()
    : QSGGeometryNode()
    , m_material()
    , m_geometry(attributeSet(), 16, 30, GL_UNSIGNED_SHORT)
{
    memcpy(m_geometry.indexData(), indices(), 30 * sizeof(unsigned short));
    m_geometry.setDrawingMode(GL_TRIANGLE_STRIP);
    m_geometry.setIndexDataPattern(QSGGeometry::StaticPattern);
    m_geometry.setVertexDataPattern(QSGGeometry::AlwaysUploadPattern);
    setMaterial(&m_material);
    setGeometry(&m_geometry);
#ifdef QSG_RUNTIME_DESCRIPTION
    qsgnode_set_description(this, QLatin1String("spreadshadow"));
#endif
}

// static
const unsigned short* ShadowNode::indices()
{
    // The geometry is made of 16 vertices indexed with a triangle strip mode.
    //     0 - 1 - 2 - 3
    //     | / | / | \ |
    //     4 - 5 - 6 - 7
    //     | \ |   | \ |
    //     8 - 9 -10 -11
    //     | \ | / | / |
    //     12- 13-14 -15
    static const unsigned short indices[] = {
        0, 4, 1, 5, 2, 6,
        6, 3,  // Degenerate triangles.
        3, 2, 7, 6, 11, 10,
        10, 15,  // Degenerate triangles.
        15, 11, 14, 10, 13, 9,
        9, 12,  // Degenerate triangles.
        12, 13, 8, 9, 4, 5

        // 0, 5, 1, 6, 2, 3,
        // 3, 3,  // Degenerate triangles.
        // 3, 6, 7, 10, 11, 15,
        // 15, 15,  // Degenerate triangles.
        // 15, 10, 14, 9, 13, 12,
        // 12, 12,  // Degenerate triangles.
        // 12, 9, 8, 5, 4, 0

        // 0, 5, 3, 6, 15, 10, 12, 9, 0, 5
    };
    return indices;
}

// static
const QSGGeometry::AttributeSet& ShadowNode::attributeSet()
{
    static const QSGGeometry::Attribute attributes[] = {
        QSGGeometry::Attribute::create(0, 2, GL_FLOAT, true),
        QSGGeometry::Attribute::create(1, 2, GL_FLOAT),
        QSGGeometry::Attribute::create(2, 2, GL_FLOAT),
        QSGGeometry::Attribute::create(3, 1, GL_FLOAT)
    };
    static const QSGGeometry::AttributeSet attributeSet = {
        4, sizeof(Vertex), attributes
    };
    return attributeSet;
}
