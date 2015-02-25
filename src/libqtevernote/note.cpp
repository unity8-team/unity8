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

Note::Note(const QString &guid, quint32 updateSequenceNumber, QObject *parent) :
    QObject(parent),
    m_isSearchResult(false),
    m_deleted(false),
    m_updateSequenceNumber(updateSequenceNumber),
    m_loading(false),
    m_loaded(false),
    m_syncError(false),
    m_conflicting(false)
{
    setGuid(guid);
    m_cacheFile.setFileName(NotesStore::instance()->storageLocation() + "note-" + guid + ".enml");

    QSettings infoFile(m_infoFile, QSettings::IniFormat);
    m_created = infoFile.value("created").toDateTime();
    m_title = infoFile.value("title").toString();
    m_updated = infoFile.value("updated").toDateTime();
    m_notebookGuid = infoFile.value("notebookGuid").toString();
    m_tagGuids = infoFile.value("tagGuids").toStringList();
    m_reminderOrder = infoFile.value("reminderOrder").toULongLong();
    m_reminderTime = infoFile.value("reminderTime").toDateTime();
    m_reminderDoneTime = infoFile.value("reminderDoneTime").toDateTime();
    m_deleted = infoFile.value("deleted").toBool();
    m_tagline = infoFile.value("tagline").toString();
    m_lastSyncedSequenceNumber = infoFile.value("lastSyncedSequenceNumber", 0).toUInt();
    m_synced = m_lastSyncedSequenceNumber == m_updateSequenceNumber;

    infoFile.beginGroup("resources");
    foreach (const QString &hash, infoFile.childGroups()) {
        if (Resource::isCached(hash)) {
            infoFile.beginGroup(hash);
            // Assuming the resource is already cached...
            addResource(QByteArray(), hash, infoFile.value("fileName").toString(), infoFile.value("type").toString());
            infoFile.endGroup();
        } else {
            // uh oh... have a resource description without file... reset sequence number to indicate we need a sync
            qWarning() << "Have a resource description but no resource file for it";
        }
    }
    infoFile.endGroup();

    connect(NotesStore::instance(), &NotesStore::notebookGuidChanged, this, &Note::slotNotebookGuidChanged);
    connect(NotesStore::instance(), &NotesStore::tagGuidChanged, this, &Note::slotTagGuidChanged);

    qDebug() << "Note created:" << m_guid << m_title << m_tagline << m_content.enml();
}

Note::~Note()
{
    qDeleteAll(m_resources.values());
}

bool Note::loading() const
{
    return m_loading;
}

bool Note::synced() const
{
    return m_synced;
}

bool Note::syncError() const
{
    return m_syncError;
}

QString Note::guid() const
{
    return m_guid;
}

void Note::setGuid(const QString &guid)
{
    if (m_guid != guid) {

        bool syncToFile = false;
        if (!m_infoFile.isEmpty()) {
            QFile ifile(m_infoFile);
            ifile.remove();

            syncToFile = true;
        }

        m_guid = guid;
        QString newCacheFileName = NotesStore::instance()->storageLocation() + "note-" + guid + ".enml";
        if (m_cacheFile.exists()) {
            qDebug() << "renaming cachefile from" << m_cacheFile.fileName() << "to" << newCacheFileName;
            m_cacheFile.rename(newCacheFileName);
        } else {
            m_cacheFile.setFileName(newCacheFileName);
        }
        m_infoFile = NotesStore::instance()->storageLocation() + "note-" + guid + ".info";

        if (syncToFile) {
            syncToInfoFile();
            syncToCacheFile();
        }
        emit guidChanged();
    }
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

void Note::setCreated(const QDateTime &created)
{
    if (m_created != created) {
        m_created = created;
        emit createdChanged();
    }
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
    load();
    return m_content.enml();
}

void Note::setEnmlContent(const QString &enmlContent)
{
    if (m_content.enml() != enmlContent) {
        m_content.setEnml(enmlContent);
        m_tagline = m_content.toPlaintext().left(100);
        emit contentChanged();
    }
    m_loaded = true;
}

QString Note::htmlContent() const
{
    qDebug() << "html content asked;";
    load();
    qDebug() << "returning" << m_content.toHtml(m_guid);
    return m_content.toHtml(m_guid);
}

QString Note::richTextContent() const
{
    load();
    return m_content.toRichText(m_guid);
}

void Note::setRichTextContent(const QString &richTextContent)
{
    if (m_content.toRichText(m_guid) != richTextContent) {
        m_content.setRichText(richTextContent);
        m_tagline = m_content.toPlaintext().left(100);
        emit contentChanged();
    }
}

QString Note::plaintextContent() const
{
    load();
    return m_content.toPlaintext().trimmed();
}

QString Note::tagline() const
{
    if (m_tagline.isEmpty()) {
        load();
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

bool Note::deleted() const
{
    return m_deleted;
}

void Note::setDeleted(bool deleted)
{
    qDebug() << "note" << this << "isDelted:" << m_deleted << "setting to" << deleted;
    if (m_deleted != deleted) {
        qDebug() << "setting m_deleted to to" << deleted;
        m_deleted = deleted;
        emit deletedChanged();
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

        m_synced = m_updateSequenceNumber == m_lastSyncedSequenceNumber;
        emit syncedChanged();
    }
}

quint32 Note::lastSyncedSequenceNumber() const
{
    return m_lastSyncedSequenceNumber;
}

void Note::setLastSyncedSequenceNumber(quint32 lastSyncedSequenceNumber)
{
    if (m_lastSyncedSequenceNumber != lastSyncedSequenceNumber) {
        m_lastSyncedSequenceNumber = lastSyncedSequenceNumber;

        m_synced = m_updateSequenceNumber == m_lastSyncedSequenceNumber;
        emit syncedChanged();
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

    qDebug() << "adding resource" << fileName << type;
    Resource *resource = new Resource(data, hash, fileName, type, this);
    m_resources.insert(hash, resource);
    emit resourcesChanged();
    emit contentChanged();

    QSettings infoFile(m_infoFile, QSettings::IniFormat);
    infoFile.beginGroup("resources");
    infoFile.beginGroup(hash);
    infoFile.setValue("fileName", fileName);
    infoFile.setValue("type", type);
    infoFile.endGroup();
    infoFile.endGroup();

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
    Note *note = new Note(m_guid, m_updateSequenceNumber);
    note->setCreated(m_created);
    note->setNotebookGuid(m_notebookGuid);
    note->setTitle(m_title);
    note->setUpdated(m_updated);
    note->setEnmlContent(m_content.enml());
    note->setReminderOrder(m_reminderOrder);
    note->setReminderTime(m_reminderTime);
    note->setReminderDoneTime(m_reminderDoneTime);
    note->setIsSearchResult(m_isSearchResult);
    note->setTagGuids(m_tagGuids);
    note->setUpdateSequenceNumber(m_updateSequenceNumber);
    note->setDeleted(m_deleted);
    foreach (Resource *resource, m_resources) {
        note->addResource(resource->data(), resource->hash(), resource->fileName(), resource->type());
    }

    return note;
}

bool Note::isCached() const
{
    return m_cacheFile.exists();
}

bool Note::loaded() const
{
    return m_loaded;
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

void Note::setSyncError(bool syncError)
{
    if (m_syncError != syncError) {
        m_syncError = syncError;
        emit syncErrorChanged();
    }
}

void Note::syncToInfoFile()
{
    QSettings infoFile(m_infoFile, QSettings::IniFormat);
    infoFile.setValue("created", m_created);
    infoFile.setValue("title", m_title);
    infoFile.setValue("updated", m_updated);

    infoFile.setValue("notebookGuid", m_notebookGuid);
    infoFile.setValue("tagGuids", m_tagGuids);
    infoFile.setValue("reminderOrder", m_reminderOrder);
    infoFile.setValue("reminderTime", m_reminderTime);
    infoFile.setValue("reminderDoneTime", m_reminderDoneTime);
    infoFile.setValue("deleted", m_deleted);
    infoFile.setValue("lastSyncedSequenceNumber", m_lastSyncedSequenceNumber);
}

void Note::syncToCacheFile()
{
    QSettings infoFile(m_infoFile, QSettings::IniFormat);
    infoFile.setValue("tagline", m_tagline);

    if (m_cacheFile.open(QFile::WriteOnly | QFile::Truncate)) {
        m_cacheFile.write(m_content.enml().toUtf8());
        m_cacheFile.close();
    }
}

void Note::load() const
{
    if (!m_loaded && isCached()) {
        loadFromCacheFile();
    } else if (!m_loaded && !m_loading) {
        NotesStore::instance()->refreshNoteContent(m_guid);
    }
}

void Note::loadFromCacheFile() const
{
    qDebug() << "Loading from cacheFile:" << m_guid;
    if (m_cacheFile.exists() && m_cacheFile.open(QFile::ReadOnly)) {
        m_content.setEnml(QString::fromUtf8(m_cacheFile.readAll()).trimmed());
        m_tagline = m_content.toPlaintext().left(100);
        m_cacheFile.close();
        qDebug() << "cache file opened" << m_tagline;
    }
    m_loaded = true;
}

void Note::deleteFromCache()
{
    if (m_cacheFile.exists()) {
        m_cacheFile.remove();
    }
    QFile f(m_infoFile);
    if (f.exists()) {
        f.remove();
    }
}

void Note::slotNotebookGuidChanged(const QString &oldGuid, const QString &newGuid)
{
    if (m_notebookGuid == oldGuid) {
        m_notebookGuid = newGuid;
        emit notebookGuidChanged();
    }
}

void Note::slotTagGuidChanged(const QString &oldGuid, const QString &newGuid)
{
    int idx = m_tagGuids.indexOf(oldGuid);
    if (idx != -1) {
        m_tagGuids.replace(idx, newGuid);
        emit tagGuidsChanged();
    }
}

bool Note::conflicting() const
{
    return m_conflicting;
}

void Note::setConflicting(bool conflicting)
{
    if (m_conflicting != conflicting) {
        m_conflicting = conflicting;
        emit conflictingChanged();
    }
}
