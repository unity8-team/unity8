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

#include "desktopfilehandler.h"

#include <QStringList>
#include <QStandardPaths>
#include <QDir>
#include <QLocale>
#include <QDebug>

#include <libintl.h>

DesktopFileHandler::DesktopFileHandler(const QString &appId, QObject *parent):
    QObject(parent),
    m_appId(appId)
{
    m_keyFile = g_key_file_new();
    load();
}

DesktopFileHandler::~DesktopFileHandler()
{
    g_key_file_free(m_keyFile);
}

QString DesktopFileHandler::appId() const
{
    return m_appId;
}

void DesktopFileHandler::setAppId(const QString &appId)
{
    if (m_appId != appId) {
        m_appId = appId;
        load();
    }
}

QString DesktopFileHandler::filename() const
{
    return m_filename;
}

bool DesktopFileHandler::isValid() const
{
    return !m_filename.isEmpty();
}

void DesktopFileHandler::load()
{
    m_filename.clear();
    if (!m_keyFile) {
        g_key_file_free(m_keyFile);
        m_keyFile = nullptr;
    }
    m_actions.clear();

    if (m_appId.isEmpty()) {
        return;
    }

    int dashPos = -1;
    QString helper = m_appId;

    QStringList searchDirs = QStandardPaths::standardLocations(QStandardPaths::ApplicationsLocation);
#ifdef LAUNCHER_TESTING
    searchDirs.prepend(QStringLiteral("."));
#endif

    QString path;
    do {
        if (dashPos != -1) {
            helper.replace(dashPos, 1, '/');
        }

        if (helper.contains('/')) {
            path += helper.split('/').at(0) + '/';
            helper.remove(QRegExp("^" + path));
        }

        Q_FOREACH(const QString &searchDirName, searchDirs) {
            QDir searchDir(searchDirName + "/" + path);
            const QString desktop = QStringLiteral("*.desktop");
            Q_FOREACH(const QString &desktopFile, searchDir.entryList(QStringList() << desktop)) {
                if (desktopFile.startsWith(helper)) {
                    QFileInfo fileInfo(searchDir, desktopFile);
                    m_filename = fileInfo.absoluteFilePath();
                    g_key_file_load_from_file(m_keyFile, QFile::encodeName(m_filename), G_KEY_FILE_NONE, nullptr);
                    readActionList();
                    return;
                }
            }
        }

        dashPos = helper.indexOf('-');
    } while (dashPos != -1);
}

void DesktopFileHandler::readActionList()
{
    m_actions.clear();
    if (!isValid()) {
        return;
    }

    QString tmp;
    if (hasKey(G_KEY_FILE_DESKTOP_KEY_ACTIONS)) {
        tmp = readString(G_KEY_FILE_DESKTOP_KEY_ACTIONS);
    } else if (hasKey("X-Ayatana-Desktop-Shortcuts")) { // fallback for an old standard
        m_usingFallbackActions = true;
        tmp = readString("X-Ayatana-Desktop-Shortcuts");
    }
    if (!tmp.isEmpty()) {
        m_actions = tmp.split(';', QString::SkipEmptyParts);
    }
}

QList<QuickListEntry> DesktopFileHandler::actions() const
{
    if (!isValid() || m_actions.isEmpty()) {
        return {};
    }

    const QString groupTemplate = m_usingFallbackActions ? QStringLiteral("%1 Shortcut Group") : QStringLiteral("Desktop Action %1");

    QList<QuickListEntry> result;

    Q_FOREACH(const QString &action, m_actions) {
        QuickListEntry entry;
        const char * groupName = qstrdup(groupTemplate.arg(action).toUtf8().constData());

        entry.setActionId(QStringLiteral("exec_%1").arg(action));
        entry.setText(readTranslatedString(G_KEY_FILE_DESKTOP_KEY_NAME, groupName));
        entry.setIcon(readString(G_KEY_FILE_DESKTOP_KEY_ICON, groupName));
        entry.setExec(readString(G_KEY_FILE_DESKTOP_KEY_EXEC, groupName));
        result.append(entry);
        delete [] groupName;
    }

    return result;
}

QString DesktopFileHandler::readTranslatedString(const char * key, const char * groupname) const
{
    Q_ASSERT(m_keyFile);
    const QString original = readString(key, groupname);
    const QString translated = g_key_file_get_locale_string(m_keyFile, groupname, key, nullptr, nullptr);

    if (!translated.isEmpty() && original != translated) {
        return translated;
    } else if (hasKey("X-Ubuntu-Gettext-Domain")) {
        // No translation found in desktop file. Get the untranslated one and have a go with gettext.
        return QString::fromUtf8(dgettext(qPrintable(readString("X-Ubuntu-Gettext-Domain")), qPrintable(original)));
    }

    return original;
}

QString DesktopFileHandler::readString(const char *key, const char *groupname) const
{
    Q_ASSERT(m_keyFile);
    return QString::fromUtf8(g_key_file_get_string(m_keyFile, groupname, key, nullptr));
}

bool DesktopFileHandler::hasKey(const char *key, const char *groupname) const
{
    Q_ASSERT(m_keyFile);
    return g_key_file_has_key(m_keyFile, groupname, key, nullptr);
}

QString DesktopFileHandler::displayName() const
{
    return readTranslatedString(G_KEY_FILE_DESKTOP_KEY_NAME);
}

QString DesktopFileHandler::icon() const
{
    if (!isValid()) {
        return QString();
    }

    const QString iconString = readString(G_KEY_FILE_DESKTOP_KEY_ICON);
    const QString pathString = readString(G_KEY_FILE_DESKTOP_KEY_PATH);

    if (QFileInfo::exists(iconString)) {
        return QFileInfo(iconString).absoluteFilePath();
    } else if (QFileInfo::exists(pathString + '/' + iconString)) {
        return pathString + '/' + iconString;
    }
    return "image://theme/" + iconString;
}
