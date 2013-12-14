/*
 * Copyright: 2013 Canonical, Ltd
 *
 * This file is part of reminders-app
 *
 * reminders-app is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * reminders-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Michael Zanetti <michael.zanetti@canonical.com>
 */

#include "note.h"

#include "notesstore.h"

#include <QDateTime>
#include <QUrl>
#include <QUrlQuery>
#include <QDebug>

Note::Note(const QString &guid, const QDateTime &created, QObject *parent) :
    QObject(parent),
    m_guid(guid),
    m_created(created),
    m_isSearchResult(false)
{
}

QString Note::guid() const
{
    return m_guid;
}

QString Note::notebookGuid() const
{
    return m_notebookGuid;
}

void Note::setNotebookGuid(const QString &notebookGuid)
{
    if (m_notebookGuid != notebookGuid) {
        m_notebookGuid = notebookGuid;
        emit notebookGuidChanged();
    }
}

QDateTime Note::created() const
{
    return m_created;
}

QString Note::title() const
{
    return m_title;
}

void Note::setTitle(const QString &title)
{
    if (m_title != title) {
        m_title = title;
        emit titleChanged();
    }
}

QString Note::enmlContent() const
{
    return m_content.enml();
}

void Note::setEnmlContent(const QString &enmlContent)
{
    if (m_content.enml() != enmlContent) {
        m_content.setEnml(enmlContent);
        emit contentChanged();
    }
}

QString Note::htmlContent() const
{
    return m_content.html(m_guid);
}

void Note::setHtmlContent(const QString &htmlContent)
{
    if (m_content.html(m_guid) != htmlContent) {
        m_content.setHtml(htmlContent);
        emit contentChanged();
    }
}

QString Note::plaintextContent() const
{
    return m_content.plaintext();
}

bool Note::reminder() const
{
    return m_reminderOrder > 0;
}

void Note::setReminder(bool reminder)
{
    if (reminder && m_reminderOrder == 0) {
        m_reminderOrder = QDateTime::currentMSecsSinceEpoch();
        emit reminderChanged();
    } else if (!reminder && m_reminderOrder > 0) {
        m_reminderOrder = 0;
        emit reminderChanged();
    }
}

qint64 Note::reminderOrder() const
{
    return m_reminderOrder;
}

void Note::setReminderOrder(qint64 reminderOrder)
{
    if (m_reminderOrder != reminderOrder) {
        m_reminderOrder = reminderOrder;
        emit reminderChanged();
    }
}

QDateTime Note::reminderTime() const
{
    return m_reminderTime;
}

void Note::setReminderTime(const QDateTime &reminderTime)
{
    if (m_reminderTime != reminderTime) {
        m_reminderTime = reminderTime;
        emit reminderTimeChanged();
    }
}

bool Note::reminderDone() const
{
    return !m_reminderDoneTime.isNull();
}

void Note::setReminderDone(bool reminderDone)
{
    if (reminderDone && m_reminderDoneTime.isNull()) {
        m_reminderDoneTime = QDateTime::currentDateTime();
        emit reminderDoneChanged();
    }
}

QDateTime Note::reminderDoneTime() const
{
    return m_reminderDoneTime;
}

void Note::setReminderDoneTime(const QDateTime &reminderDoneTime)
{
    if (m_reminderDoneTime != reminderDoneTime) {
        m_reminderDoneTime = reminderDoneTime;
        emit reminderDoneChanged();
    }
}

bool Note::isSearchResult() const
{
    return m_isSearchResult;
}

void Note::setIsSearchResult(bool isSearchResult)
{
    if (m_isSearchResult != isSearchResult) {
        m_isSearchResult = isSearchResult;
        emit isSearchResultChanged();
    }
}

QStringList Note::resources() const
{
    QList<QString> ret;
    foreach (const QString &hash, m_resources.keys()) {
        QUrl url("image://resource/" + m_resourceTypes.value(hash));
        QUrlQuery arguments;
        arguments.addQueryItem("noteGuid", m_guid);
        arguments.addQueryItem("hash", hash.toLocal8Bit().toHex());
        url.setQuery(arguments);
        ret << url.toString();
    }
    return ret;
}

QImage Note::resource(const QString &hash)
{
    return m_resources.value(hash);
}

void Note::addResource(const QString &hash, const QImage &image, const QString &type)
{
    m_resources.insert(hash, image);
    m_resourceTypes.insert(hash, type);
}

Note *Note::clone()
{
    Note *note = new Note(m_guid, m_created);
    note->setNotebookGuid(m_notebookGuid);
    note->setTitle(m_title);
    note->setEnmlContent(m_content.enml());
    note->setReminderOrder(m_reminderOrder);
    note->setReminderTime(m_reminderTime);
    note->setReminderDoneTime(m_reminderDoneTime);
    note->setIsSearchResult(m_isSearchResult);
    return note;
}

void Note::save()
{
    NotesStore::instance()->saveNote(m_guid);
}

void Note::remove()
{
    NotesStore::instance()->deleteNote(m_guid);
}
