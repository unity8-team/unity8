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

#ifndef CONTENTNODE_H
#define CONTENTNODE_H

#include <QtQuick/QSGNode>
#include <QtQuick/QSGTextureProvider>
#include <QtQuick/qsgmaterial.h>

class ContentShader : public QSGMaterialShader
{
public:
    ContentShader();
    virtual char const* const* attributeNames() const;
    virtual void initialize();
    virtual void updateState(
        const RenderState& state, QSGMaterial* newEffect, QSGMaterial* oldEffect);

private:
    int m_opacityId;
    int m_matrixId;
    int m_texturedId;
};

class ContentMaterial : public QSGMaterial
{
public:
    struct Data {
        enum {
            Textured = (1 << 0)
        };
        QSGTextureProvider* contentTextureProvider;
        quint8 flags;
    };

    ContentMaterial();
    virtual QSGMaterialType* type() const;
    virtual QSGMaterialShader* createShader() const;
    virtual int compare(const QSGMaterial* other) const;
    virtual void updateTextures();
    const Data* constData() const { return &m_data; }
    Data* data() { return &m_data; }

private:
    Data m_data;
};

class ContentNode : public QSGGeometryNode
{
public:
    struct Vertex {
        float position[2];
        float contentCoordinate[2];
    };

    static const unsigned short* indices();
    static const QSGGeometry::AttributeSet& attributeSet();

    ContentNode();
    ContentMaterial* material() { return &m_material; }
    QSGGeometry* geometry() { return &m_geometry; }
    void preprocess() { m_material.updateTextures(); }

private:
    ContentMaterial m_material;
    QSGGeometry m_geometry;
};

#endif  // CONTENTNODE_H
