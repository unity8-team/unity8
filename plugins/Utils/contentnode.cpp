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

#include "contentnode.h"
#include <QtQuick/private/qsgadaptationlayer_p.h>

ContentShader::ContentShader()
{
    setShaderSourceFile(QOpenGLShader::Vertex, QStringLiteral(":/glsl/content.vert"));
    setShaderSourceFile(QOpenGLShader::Fragment, QStringLiteral(":/glsl/content.frag"));
}

char const* const* ContentShader::attributeNames() const
{
    static char const* const attributes[] = { "positionAttrib", "contentCoordAttrib", 0 };
    return attributes;
}

void ContentShader::initialize()
{
    QSGMaterialShader::initialize();
    m_opacityId = program()->uniformLocation("opacity");
    m_matrixId = program()->uniformLocation("matrix");
    m_texturedId = program()->uniformLocation("textured");
}

void ContentShader::updateState(
    const RenderState& state, QSGMaterial* newEffect, QSGMaterial* oldEffect)
{
    Q_UNUSED(oldEffect);

    const ContentMaterial::Data* data = static_cast<ContentMaterial*>(newEffect)->constData();
    bool textured = false;
    if (data->flags & ContentMaterial::Data::Textured) {
        const QSGTextureProvider* provider = data->contentTextureProvider;
        QSGTexture* contentTexture = provider ? provider->texture() : NULL;
        if (contentTexture) {
            contentTexture->bind();
            textured = true;
        }
    }
    program()->setUniformValue(m_texturedId, textured);

    if (state.isOpacityDirty()) {
        program()->setUniformValue(m_opacityId, state.opacity());
    }
    if (state.isMatrixDirty()) {
        program()->setUniformValue(m_matrixId, state.combinedMatrix());
    }
}

ContentMaterial::ContentMaterial()
{
    memset(&m_data, 0, sizeof(Data));
    setFlag(Blending, false);
}

QSGMaterialType* ContentMaterial::type() const
{
    static QSGMaterialType type;
    return &type;
}

QSGMaterialShader* ContentMaterial::createShader() const
{
    return new ContentShader;
}

int ContentMaterial::compare(const QSGMaterial* other) const
{
    const ContentMaterial::Data* otherData =
        static_cast<const ContentMaterial*>(other)->constData();
    return memcmp(&m_data, otherData, sizeof(m_data));
}

void ContentMaterial::updateTextures()
{
    if (m_data.flags & ContentMaterial::Data::Textured && m_data.contentTextureProvider) {
        if (QSGLayer* texture = qobject_cast<QSGLayer*>(m_data.contentTextureProvider->texture())) {
            texture->updateTexture();
        }
    }
}

ContentNode::ContentNode()
    : QSGGeometryNode()
    , m_material()
    , m_geometry(attributeSet(), 4, 4, GL_UNSIGNED_SHORT)
{
    QSGNode::setFlag(UsePreprocess, true);
    memcpy(m_geometry.indexData(), indices(), 4 * sizeof(unsigned short));
    m_geometry.setDrawingMode(GL_TRIANGLE_STRIP);
    m_geometry.setIndexDataPattern(QSGGeometry::StaticPattern);
    m_geometry.setVertexDataPattern(QSGGeometry::AlwaysUploadPattern);
    setMaterial(&m_material);
    setGeometry(&m_geometry);
#ifdef QSG_RUNTIME_DESCRIPTION
    qsgnode_set_description(this, QLatin1String("spreadcontent"));
#endif
}

// static
const unsigned short* ContentNode::indices()
{
    static const unsigned short indices[] = { 0, 2, 1, 3 };
    return indices;
}

// static
const QSGGeometry::AttributeSet& ContentNode::attributeSet()
{
    static const QSGGeometry::Attribute attributes[] = {
        QSGGeometry::Attribute::create(0, 2, GL_FLOAT, true),
        QSGGeometry::Attribute::create(1, 2, GL_FLOAT)
    };
    static const QSGGeometry::AttributeSet attributeSet = {
        2, sizeof(Vertex), attributes
    };
    return attributeSet;
}
