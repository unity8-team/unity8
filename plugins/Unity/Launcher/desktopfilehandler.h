/*
 * Copyright 2014-2015 Canonical Ltd.
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
 *
 */

#ifndef DESKTOPFILEHANDLER_H
#define DESKTOPFILEHANDLER_H

#include <QObject>
#include <QStringList>

#include <glib.h>

#include "quicklistentry.h"

/**
 * When an object of this class is created or whenever setAppId(appId) is called,
 * this will search for a .desktop file matching the given appId. If a file is
 * found, isValid() will return true and the other methods return the contents
 * of the .desktop file.
 *
 * Note that this class will consider the user's locale and do a best effort
 * to return localized values.
 */

class DesktopFileHandler: public QObject
{
    Q_OBJECT

public:
    DesktopFileHandler(const QString &appId = QString(), QObject *parent = nullptr);
    ~DesktopFileHandler();

    QString appId() const;
    void setAppId(const QString &appId);

    bool isValid() const;
    QString filename() const;
    QString displayName() const;
    QString icon() const;
    QList<QuickListEntry> actions() const;

private:
    void load();
    void readActionList();
    QString readTranslatedString(const char * key, const char * groupname = G_KEY_FILE_DESKTOP_GROUP) const;
    QString readString(const char * key, const char * groupname = G_KEY_FILE_DESKTOP_GROUP) const;
    bool hasKey(const char * key, const char * groupname = G_KEY_FILE_DESKTOP_GROUP) const;

    QString m_appId;
    QString m_filename;
    QStringList m_actions;
    bool m_usingFallbackActions = false;
    GKeyFile * m_keyFile = nullptr;
};

#endif
