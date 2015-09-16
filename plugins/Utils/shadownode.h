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

#ifndef SHADOWNODE_H
#define SHADOWNODE_H

#include <QtQuick/QSGNode>
#include <QtQuick/QSGTextureProvider>
#include <QtQuick/qsgmaterial.h>
#include <QtGui/QOpenGLFunctions>

class ShadowShader : public QSGMaterialShader
{
public:
    ShadowShader();
    virtual char const* const* attributeNames() const;
    virtual void initialize();
    virtual void updateState(
        const RenderState& state, QSGMaterial* newEffect, QSGMaterial* oldEffect);

private:
#if defined(HAS_TEXTURED_SHADOW)
    QOpenGLFunctions* m_functions;
#endif
    int m_shadowOpacityId;
    int m_opacityId;
    int m_matrixId;
    int m_texturedId;
};

class ShadowMaterial : public QSGMaterial
{
public:
    struct Data {
        enum {
            Textured = (1 << 0)
        };
        QSGTextureProvider* contentTextureProvider;
#if defined(HAS_TEXTURED_SHADOW)
        quint32 shadowTextureId;
#endif
        quint8 shadowOpacity;
        quint8 flags;
    };

    ShadowMaterial();
    virtual QSGMaterialType* type() const;
    virtual QSGMaterialShader* createShader() const;
    virtual int compare(const QSGMaterial* other) const;
    const Data* constData() const { return &m_data; }
    Data* data() { return &m_data; }

private:
    Data m_data;
};

class ShadowNode : public QSGGeometryNode
{
public:
    struct Vertex {
        float position[2];
        float shadowCoordinate[2];
        float contentCoordinate[2];
        float contentFactor;
    };

    static const unsigned short* indices();
    static const QSGGeometry::AttributeSet& attributeSet();

    ShadowNode();
    ShadowMaterial* material() { return &m_material; }
    QSGGeometry* geometry() { return &m_geometry; }

private:
    ShadowMaterial m_material;
    QSGGeometry m_geometry;
};

#endif  // SHADOWNODE_H
