/*
 * Copyright 2013 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "fake_gsettings.h"

#include <QList>

GSettingsControllerQml* GSettingsControllerQml::s_controllerInstance = 0;

GSettingsControllerQml::GSettingsControllerQml()
    : m_fingerprintNames()
{
}

GSettingsControllerQml::~GSettingsControllerQml() {
    s_controllerInstance = 0;
}

GSettingsControllerQml* GSettingsControllerQml::instance()  {
    if (!s_controllerInstance) {
        s_controllerInstance = new GSettingsControllerQml();
    }
    return s_controllerInstance;
}

QVariantMap GSettingsControllerQml::fingerprintNames() const
{
    return m_fingerprintNames;
}

void GSettingsControllerQml::setFingerprintNames(QVariantMap map)
{
    if (map != m_fingerprintNames) {
        m_fingerprintNames = map;
        Q_EMIT fingerprintNamesChanged();
    }
}

GSettingsSchemaQml::GSettingsSchemaQml(QObject *parent): QObject(parent) {
}

QByteArray GSettingsSchemaQml::id() const {
    return m_id;
}

void GSettingsSchemaQml::setId(const QByteArray &id) {
    if (!m_id.isEmpty()) {
        qWarning("GSettings.schema.id may only be set on construction");
        return;
    }

    m_id = id;
}

QByteArray GSettingsSchemaQml::path() const {
    return m_path;
}

void GSettingsSchemaQml::setPath(const QByteArray &path) {
    if (!m_path.isEmpty()) {
        qWarning("GSettings.schema.path may only be set on construction");
        return;
    }

    m_path = path;
}

GSettingsQml::GSettingsQml(QObject *parent)
    : QObject(parent),
      m_valid(false)
{
    m_schema = new GSettingsSchemaQml(this);
}

void GSettingsQml::classBegin()
{
}

void GSettingsQml::componentComplete()
{
    // Emulate what the real GSettings module does, and only return undefined
    // values until we are completed loading.
    m_valid = true;

    // FIXME: We should make this dynamic, instead of hard-coding all possible
    // properties in one object.  We should create properties based on the schema.
    connect(GSettingsControllerQml::instance(), &GSettingsControllerQml::fingerprintNamesChanged,
            this, &GSettingsQml::fingerprintNamesChanged);

    Q_EMIT fingerprintNamesChanged();
}

GSettingsSchemaQml * GSettingsQml::schema() const {
    return m_schema;
}

QVariantMap GSettingsQml::fingerprintNames() const
{
    if (m_valid && m_schema->id() == "com.ubuntu.touch.system") {
        return GSettingsControllerQml::instance()->fingerprintNames();
    } else {
        return QVariantMap();
    }
}

void GSettingsQml::setFingerprintNames(const QVariantMap &map)
{
    if (m_valid && m_schema->id() == "com.ubuntu.touch.system") {
        GSettingsControllerQml::instance()->setFingerprintNames(map);
    }
}
