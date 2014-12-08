/*
 * Copyright: 2013 Canonical, Ltd
 *
 * This file is part of reminders
 *
 * reminders is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * reminders is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Michael Zanetti <michael.zanetti@canonical.com>
 */

#include "notebook.h"
#include "notesstore.h"
#include "note.h"

#include <libintl.h>

#include <QDebug>
#include <QStandardPaths>

Notebook::Notebook(QString guid, quint32 updateSequenceNumber, QObject *parent) :
    QObject(parent),
    m_updateSequenceNumber(updateSequenceNumber),
    m_guid(guid),
    m_noteCount(0),
    m_published(false),
    m_infoFile(QStandardPaths::standardLocations(QStandardPaths::CacheLocation).first() + "/" + NotesStore::instance()->username() + "/notebook-" + guid + ".info", QSettings::IniFormat)
{

    m_name = m_infoFile.value("name").toString();
    m_published = m_infoFile.value("published").toBool();
    m_lastUpdated = m_infoFile.value("lastUpdated").toDateTime();

    foreach (Note *note, NotesStore::instance()->notes()) {
        if (note->notebookGuid() == m_guid) {
            m_noteCount++;
        }
    }
    connect(NotesStore::instance(), &NotesStore::noteAdded, this, &Notebook::noteAdded);
    connect(NotesStore::instance(), &NotesStore::noteRemoved, this, &Notebook::noteRemoved);
}

quint32 Notebook::updateSequenceNumber() const
{
    return m_updateSequenceNumber;
}

void Notebook::setUpdateSequenceNumber(quint32 updateSequenceNumber)
{
    if (updateSequenceNumber != m_updateSequenceNumber) {
        m_updateSequenceNumber = updateSequenceNumber;
    }
}

QString Notebook::guid() const
{
    return m_guid;
}

QString Notebook::name() const
{
    return m_name;
}

void Notebook::setName(const QString &name)
{
    if (m_name != name) {
        m_name = name;
        emit nameChanged();
    }
}

int Notebook::noteCount() const
{
    return m_noteCount;
}

bool Notebook::published() const
{
    return m_published;
}

void Notebook::setPublished(bool published)
{
    if (m_published != published) {
        m_published = published;
        emit publishedChanged();
    }
}

QDateTime Notebook::lastUpdated() const
{
    return m_lastUpdated;
}

void Notebook::setLastUpdated(const QDateTime &lastUpdated)
{
    if (m_lastUpdated != lastUpdated) {
        m_lastUpdated = lastUpdated;
        emit lastUpdatedChanged();
    }
}

QString Notebook::lastUpdatedString() const
{
    QDate updateDate = m_lastUpdated.date();
    QDate today = QDate::currentDate();

    if (updateDate == today || updateDate.isNull()) {
        // TRANSLATORS: this is part of a longer string - "Last updated: today"
        return gettext("today");
    }
    if (updateDate == today.addDays(-1)) {
        // TRANSLATORS: this is part of a longer string - "Last updated: yesterday"
        return gettext("yesterday");
    }
    if (updateDate <= today.addDays(-7)) {
        // TRANSLATORS: this is part of a longer string - "Last updated: last week"
        return gettext("last week");
    }
    if (updateDate <= today.addDays(-14)) {
        // TRANSLATORS: this is part of a longer string - "Last updated: two weeks ago"
        return gettext("two weeks ago");
    }
    // TRANSLATORS: this is used in the notes list to group notes created on the same month
    // the first parameter refers to a month name and the second to a year
    return QString(gettext("on %1 %2")).arg(QLocale::system().standaloneMonthName(updateDate.month())).arg(updateDate.year());
}

Notebook *Notebook::clone()
{
    Notebook *notebook = new Notebook(m_guid, m_updateSequenceNumber);
    notebook->setName(m_name);
    notebook->setLastUpdated(m_lastUpdated);
    notebook->setPublished(m_published);

    return notebook;
}

void Notebook::save()
{
    NotesStore::instance()->saveNotebook(m_guid);
}

void Notebook::noteAdded(const QString &noteGuid, const QString &notebookGuid)
{
    Q_UNUSED(noteGuid)
    if (notebookGuid == m_guid) {
        m_noteCount++;
        emit noteCountChanged();
    }
}

void Notebook::noteRemoved(const QString &noteGuid, const QString &notebookGuid)
{
    Q_UNUSED(noteGuid)
    if (notebookGuid == m_guid) {
        m_noteCount--;
        emit noteCountChanged();
    }
}

void Notebook::syncToInfoFile()
{
    m_infoFile.setValue("name", m_name);
    m_infoFile.setValue("published", m_published);
    m_infoFile.value("lastUpdated", m_lastUpdated);
}
