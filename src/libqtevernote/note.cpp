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

#include "note.h"

#include "notesstore.h"

#include <libintl.h>

#include <QDateTime>
#include <QUrl>
#include <QUrlQuery>
#include <QStandardPaths>
#include <QDebug>
#include <QCryptographicHash>
#include <QFile>

Note::Note(const QString &guid, const QDateTime &created, quint64 updateSequenceNumber, QObject *parent) :
    QObject(parent),
    m_guid(guid),
    m_created(created),
    m_isSearchResult(false),
    m_updateSequenceNumber(updateSequenceNumber),
    m_infoFile(QStandardPaths::standardLocations(QStandardPaths::CacheLocation).first() + "/" + guid + "_" + QString::number(updateSequenceNumber) + ".info", QSettings::IniFormat),
    m_loading(false),
    m_isLoaded(false)
{
    m_cacheFile.setFileName(QStandardPaths::standardLocations(QStandardPaths::CacheLocation).first() + "/" + guid + "_" + QString::number(updateSequenceNumber) + ".enml");

    m_infoFile.beginGroup("resources");
    foreach (const QString &hash, m_infoFile.childGroups()) {
        if (Resource::isCached(hash)) {
            m_infoFile.beginGroup(hash);
            // Assuming the resource is already cached...
            addResource(QByteArray(), hash, m_infoFile.value("fileName").toString(), m_infoFile.value("type").toString());
            m_infoFile.endGroup();
        } else {
            // uh oh... have a resource description without file... reset sequence number to indicate we need a sync
            qWarning() << "Have a resource description but no resource file for it";
            m_updateSequenceNumber = 0;
        }
    }
    m_infoFile.endGroup();
}

Note::~Note()
{
    qDeleteAll(m_resources.values());
}

bool Note::loading() const
{
    return m_loading;
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

QString Note::createdString() const
{
    QDate createdDate = m_created.date();
    QDate today = QDate::currentDate();
    if (createdDate == today) {
        return gettext("Today");
    }
    if (createdDate == today.addDays(-1)) {
        return gettext("Yesterday");
    }
    if (createdDate >= today.addDays(-7)) {
        return gettext("Last week");
    }
    if (createdDate >= today.addDays(-14)) {
        return gettext("Two weeks ago");
    }

    // TRANSLATORS: the first argument refers to a month name and the second to a year
    return QString(gettext("%1 %2")).arg(QLocale::system().standaloneMonthName(createdDate.month())).arg(createdDate.year());
}

QDateTime Note::updated() const
{
    return m_updated;
}

void Note::setUpdated(const QDateTime &updated)
{
    if (m_updated!= updated) {
        m_updated = updated;
        emit updatedChanged();
    }
}

QString Note::updatedString() const
{
    QDate updatedDate = m_updated.date();
    QDate today = QDate::currentDate();
    if (updatedDate == today) {
        return gettext("Today");
    }
    if (updatedDate == today.addDays(-1)) {
        return gettext("Yesterday");
    }
    if (updatedDate >= today.addDays(-7)) {
        return gettext("Last week");
    }
    if (updatedDate >= today.addDays(-14)) {
        return gettext("Two weeks ago");
    }

    // TRANSLATORS: the first argument refers to a month name and the second to a year
    return QString(gettext("%1 %2")).arg(QLocale::system().standaloneMonthName(updatedDate.month())).arg(updatedDate.year());
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

QStringList Note::tagGuids() const
{
    return m_tagGuids;
}

void Note::setTagGuids(const QStringList &tagGuids)
{
    if (m_tagGuids != tagGuids) {
        m_tagGuids = tagGuids;
        emit tagGuidsChanged();
    }
}

QString Note::enmlContent() const
{
    if (!m_isLoaded && isCached()) {
        loadFromCacheFile();
    }
    return m_content.enml();
}

void Note::setEnmlContent(const QString &enmlContent)
{
    if (m_content.enml() != enmlContent) {
        m_content.setEnml(enmlContent);
        m_tagline = m_content.toPlaintext().left(100);
        emit contentChanged();
        syncToCacheFile();
    }
}

QString Note::htmlContent() const
{
    if (!m_isLoaded && isCached()) {
        loadFromCacheFile();
    }
    return m_content.toHtml(m_guid);
}

QString Note::richTextContent() const
{
    if (!m_isLoaded && isCached()) {
        loadFromCacheFile();
    }
    return m_content.toRichText(m_guid);
}

void Note::setRichTextContent(const QString &richTextContent)
{
    if (m_content.toRichText(m_guid) != richTextContent) {
        m_content.setRichText(richTextContent);
        m_tagline = m_content.toPlaintext().left(100);
        emit contentChanged();
        syncToCacheFile();
    }
}

QString Note::plaintextContent() const
{
    if (!m_isLoaded && isCached()) {
        loadFromCacheFile();
    }
    return m_content.toPlaintext().trimmed();
}

QString Note::tagline() const
{
    if (!m_isLoaded && isCached()) {
        loadFromCacheFile();
    }
    return m_tagline;
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

bool Note::hasReminderTime() const
{
    return !m_reminderTime.isNull();
}

void Note::setHasReminderTime(bool hasReminderTime)
{
    if (hasReminderTime && m_reminderTime.isNull()) {
        m_reminderTime = QDateTime::currentDateTime();
        emit reminderTimeChanged();
    } else if (!hasReminderTime && !m_reminderTime.isNull()) {
        m_reminderTime = QDateTime();
        emit reminderTimeChanged();
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
    } else if (!reminderDone && !m_reminderDoneTime.isNull()) {
        m_reminderDoneTime = QDateTime();
        emit reminderDoneChanged();
    }
}

QString Note::reminderTimeString() const
{
    if (m_reminderOrder == 0) {
        return QString();
    }

    if (reminderDone()) {
        return gettext("Done");
    }

    QDate reminderDate = m_reminderTime.date();
    QDate today = QDate::currentDate();
    if (m_reminderTime.isNull()) {
        return gettext("No date");
    }
    if (reminderDate < today) {
        return gettext("Overdue");
    }
    if (reminderDate == today) {
        return gettext("Today");
    }
    if (reminderDate == today.addDays(1)) {
        return gettext("Tomorrow");
    }
    if (reminderDate <= today.addDays(7)) {
        return gettext("Next week");
    }
    if (reminderDate <= today.addDays(14)) {
        return gettext("In two weeks");
    }
    return gettext("Later");
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

quint32 Note::updateSequenceNumber() const
{
    return m_updateSequenceNumber;
}

void Note::setUpdateSequenceNumber(quint32 updateSequenceNumber)
{
    if (m_updateSequenceNumber != updateSequenceNumber) {
        m_updateSequenceNumber = updateSequenceNumber;

        // If there is an old cache file, drop it
        if (m_cacheFile.exists()) {
            m_cacheFile.remove();
        }

        // Write new cache file
        m_cacheFile.setFileName(QStandardPaths::standardLocations(QStandardPaths::CacheLocation).first() + "/" + m_guid + "_" + QString::number(updateSequenceNumber) + ".enml");
        syncToCacheFile();
    }
}

QList<Resource*> Note::resources() const
{
    return m_resources.values();
}

QStringList Note::resourceUrls() const
{
    QList<QString> ret;
    foreach (const QString &hash, m_resources.keys()) {
        QUrl url("image://resource/" + m_resources.value(hash)->type());
        QUrlQuery arguments;
        arguments.addQueryItem("noteGuid", m_guid);
        arguments.addQueryItem("hash", hash);
        url.setQuery(arguments);
        ret << url.toString();
    }
    return ret;
}

Resource* Note::resource(const QString &hash)
{
    return m_resources.value(hash);
}


Resource* Note::addResource(const QByteArray &data, const QString &hash, const QString &fileName, const QString &type)
{
    if (m_resources.contains(hash)) {
        return m_resources.value(hash);
    }

    Resource *resource = new Resource(data, hash, fileName, type, this);
    m_resources.insert(hash, resource);
    emit resourcesChanged();

    m_infoFile.beginGroup("resources");
    m_infoFile.beginGroup(hash);
    m_infoFile.setValue("fileName", fileName);
    m_infoFile.setValue("type", type);
    m_infoFile.endGroup();
    m_infoFile.endGroup();

    return resource;
}

void Note::markTodo(const QString &todoId, bool checked)
{
    m_content.markTodo(todoId, checked);
}

void Note::attachFile(int position, const QUrl &fileName)
{
    QFile importedFile(fileName.path());
    if (!importedFile.exists()) {
        qWarning() << "File doesn't exist. Cannot attach.";
        return;
    }

    Resource *resource = new Resource(fileName.path());
    m_resources.insert(resource->hash(), resource);
    m_content.attachFile(position, resource->hash(), resource->type());
    emit resourcesChanged();
    emit contentChanged();
    syncToCacheFile();

    // Cleanup imported file.
    // TODO: If the app should be extended to allow attaching other files, and we somehow
    // can browse to unconfined files, this needs to be made conditional to not delete those files!
    importedFile.remove();
}

void Note::format(int startPos, int endPos, TextFormat::Format format)
{
    qDebug() << "Should format from" << startPos << "to" << endPos << "with format:" << format;
}

void Note::addTag(const QString &tagGuid)
{
    NotesStore::instance()->tagNote(m_guid, tagGuid);
}

void Note::removeTag(const QString &tagGuid)
{
    NotesStore::instance()->untagNote(m_guid, tagGuid);
}

Note *Note::clone()
{
    Note *note = new Note(m_guid, m_created, m_updateSequenceNumber);
    note->setNotebookGuid(m_notebookGuid);
    note->setTitle(m_title);
    note->setUpdated(m_updated);
    note->setEnmlContent(m_content.enml());
    note->setReminderOrder(m_reminderOrder);
    note->setReminderTime(m_reminderTime);
    note->setReminderDoneTime(m_reminderDoneTime);
    note->setIsSearchResult(m_isSearchResult);
    note->setUpdateSequenceNumber(m_updateSequenceNumber);
    foreach (Resource *resource, m_resources) {
        note->addResource(resource->data(), resource->hash(), resource->fileName(), resource->type());
    }

    return note;
}

bool Note::isCached() const
{
    return m_cacheFile.exists();
}

void Note::save()
{
    NotesStore::instance()->saveNote(m_guid);
}

void Note::remove()
{
    NotesStore::instance()->deleteNote(m_guid);
}

void Note::setLoading(bool loading)
{
    if (m_loading != loading) {
        m_loading = loading;
        emit loadingChanged();
    }
}

void Note::syncToCacheFile()
{
    if (m_cacheFile.open(QFile::WriteOnly | QFile::Truncate)) {
        m_cacheFile.write(m_content.enml().toUtf8());
        m_cacheFile.close();
    }
    m_isLoaded = true;
}

void Note::loadFromCacheFile() const
{
    if (m_cacheFile.exists() && m_cacheFile.open(QFile::ReadOnly)) {
        m_content.setEnml(QString::fromUtf8(m_cacheFile.readAll()));
        m_tagline = m_content.toPlaintext().left(100);
        m_cacheFile.close();
    }
    m_isLoaded = true;
}
