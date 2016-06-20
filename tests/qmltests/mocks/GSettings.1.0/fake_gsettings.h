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

#ifndef FAKE_GSETTINGS_H
#define FAKE_GSETTINGS_H

#include <QList>
#include <QObject>
#include <QQmlParserStatus>
#include <QStringList>
#include <QVariant>

class GSettingsSchemaQml: public QObject
{
    Q_OBJECT

    Q_PROPERTY(QByteArray id READ id WRITE setId)
public:
    GSettingsSchemaQml(QObject *parent = nullptr);

    QByteArray id() const;
    void setId(const QByteArray &id);

    QByteArray path() const;
    void setPath(const QByteArray &path);

private:
    QByteArray m_id;
    QByteArray m_path;
};

class GSettingsQml: public QObject, public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)

    Q_PROPERTY(GSettingsSchemaQml* schema READ schema NOTIFY schemaChanged)
    Q_PROPERTY(QVariantMap fingerprintNames
               READ fingerprintNames
               WRITE setFingerprintNames
               NOTIFY fingerprintNamesChanged)

public:
    GSettingsQml(QObject *parent = nullptr);

    void classBegin() override;
    void componentComplete() override;

    GSettingsSchemaQml * schema() const;

    QVariantMap fingerprintNames() const;
    void setFingerprintNames(const QVariantMap &map);

Q_SIGNALS:
    void fingerprintNamesChanged();
    void schemaChanged();

private:
    GSettingsSchemaQml* m_schema;
    bool m_valid;

    friend class GSettingsSchemaQml;
};

class GSettingsControllerQml: public QObject
{
    Q_OBJECT

public:
    static GSettingsControllerQml* instance();
    ~GSettingsControllerQml();

    Q_INVOKABLE QVariantMap fingerprintNames() const;
    Q_INVOKABLE void setFingerprintNames(QVariantMap map);

Q_SIGNALS:
    void fingerprintNamesChanged();

private:
    GSettingsControllerQml();

    QVariantMap m_fingerprintNames;

    static GSettingsControllerQml* s_controllerInstance;
    QList<GSettingsQml *> m_registeredGSettings;
};

#endif // FAKE_GSETTINGS_H
