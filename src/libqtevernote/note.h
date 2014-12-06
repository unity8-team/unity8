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

#ifndef NOTE_H
#define NOTE_H

#include "utils/enmldocument.h"
#include "resource.h"
#include "utils/textformat.h"

#include <QObject>
#include <QDateTime>
#include <QStringList>
#include <QImage>
#include <QFile>
#include <QSettings>

class Note : public QObject
{
    Q_OBJECT

    // Don't forget to update clone() if you add properties!
    Q_PROPERTY(QString guid READ guid CONSTANT)
    Q_PROPERTY(QString notebookGuid READ notebookGuid WRITE setNotebookGuid NOTIFY notebookGuidChanged)
    Q_PROPERTY(QDateTime created READ created CONSTANT)
    Q_PROPERTY(QString createdString READ createdString CONSTANT)
    Q_PROPERTY(QDateTime updated READ updated WRITE setUpdated NOTIFY updatedChanged)
    Q_PROPERTY(QString updatedString READ updatedString)
    Q_PROPERTY(QString title READ title WRITE setTitle NOTIFY titleChanged)
    Q_PROPERTY(QStringList tagGuids READ tagGuids WRITE setTagGuids NOTIFY tagGuidsChanged)
    Q_PROPERTY(QString htmlContent READ htmlContent NOTIFY contentChanged)
    Q_PROPERTY(QString richTextContent READ richTextContent WRITE setRichTextContent NOTIFY contentChanged)
    Q_PROPERTY(QString enmlContent READ enmlContent WRITE setEnmlContent NOTIFY contentChanged)
    Q_PROPERTY(QString plaintextContent READ plaintextContent NOTIFY contentChanged)
    Q_PROPERTY(QString tagline READ tagline NOTIFY contentChanged)
    Q_PROPERTY(QStringList resourceUrls READ resourceUrls NOTIFY resourcesChanged)
    Q_PROPERTY(bool reminder READ reminder WRITE setReminder NOTIFY reminderChanged)
    Q_PROPERTY(bool hasReminderTime READ hasReminderTime WRITE setHasReminderTime NOTIFY reminderTimeChanged)
    Q_PROPERTY(QDateTime reminderTime READ reminderTime WRITE setReminderTime NOTIFY reminderTimeChanged)
    Q_PROPERTY(QString reminderTimeString READ reminderTimeString NOTIFY reminderTimeChanged)
    Q_PROPERTY(bool reminderDone READ reminderDone WRITE setReminderDone NOTIFY reminderDoneChanged)
    Q_PROPERTY(QDateTime reminderDoneTime READ reminderDoneTime WRITE setReminderDoneTime NOTIFY reminderDoneChanged)
    Q_PROPERTY(bool isSearchResult READ isSearchResult NOTIFY isSearchResultChanged)
    Q_PROPERTY(quint32 updateSequenceNumber READ updateSequenceNumber NOTIFY updateSequenceNumberChanged)
//    Q_PROPERTY(bool loaded READ loaded NOTIFY loadedChanged)
    // Don't forget to update clone() if you add properties!

    // Don't clone() "loading" property as results of any current loading operation won't affect the clone.
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)

public:
    explicit Note(const QString &guid, const QDateTime &created, quint32 updateSequenceNumber, QObject *parent = 0);
    ~Note();
    Note* clone();

    QString guid() const;

    QString notebookGuid() const;
    void setNotebookGuid(const QString &notebookGuid);

    QDateTime created() const;
    QString createdString() const;

    QDateTime updated() const;
    void setUpdated(const QDateTime &updated);
    QString updatedString() const;

    QString title() const;
    void setTitle(const QString &title);

    QStringList tagGuids() const;
    void setTagGuids(const QStringList &tagGuids);

    QString enmlContent() const;
    void setEnmlContent(const QString &enmlContent);

    QString htmlContent() const;

    QString richTextContent() const;
    void setRichTextContent(const QString &richTextContent);

    QString plaintextContent() const;

    QString tagline() const;

    // setting reminder to false will reset the reminderOrder to 0, setting it to true will
    // create a new timestamp for it.
    bool reminder() const;
    void setReminder(bool reminder);

    qint64 reminderOrder() const;
    void setReminderOrder(qint64 reminderOrder);

    // setting hasReminderTime to false will reset reminderTime to 0, setting it to true will
    // create a new timestamp for it.
    bool hasReminderTime() const;
    void setHasReminderTime(bool hasReminderTime);

    QDateTime reminderTime() const;
    void setReminderTime(const QDateTime &reminderTime);

    // This is the QML representation as we don't want to deal with timestamps there.
    // setting it to false will reset reminderDoneTime to 0, setting it to true will
    // create a new timestamp for it.
    bool reminderDone() const;
    void setReminderDone(bool reminderDone);

    QString reminderTimeString() const;

    QDateTime reminderDoneTime() const;
    void setReminderDoneTime(const QDateTime &reminderDoneTime);

    bool isSearchResult() const;
    void setIsSearchResult(bool isSearchResult);

    quint32 updateSequenceNumber() const;
    void setUpdateSequenceNumber(quint32 updateSequenceNumber);

    bool isCached() const;
    bool loading() const;

    QStringList resourceUrls() const;
    Resource* resource(const QString &hash);
    QList<Resource*> resources() const;
    Resource *addResource(const QByteArray &data, const QString &hash, const QString &fileName, const QString &type);

    Q_INVOKABLE void markTodo(const QString &todoId, bool checked);
    Q_INVOKABLE void attachFile(int position, const QUrl &fileName);
    Q_INVOKABLE void format(int startPos, int endPos, TextFormat::Format format);
    Q_INVOKABLE void addTag(const QString &tagGuid);
    Q_INVOKABLE void removeTag(const QString &tagGuid);

public slots:
    void save();
    void remove();

signals:
    void titleChanged();
    void updatedChanged();
    void notebookGuidChanged();
    void tagGuidsChanged();
    void contentChanged();
    void resourcesChanged();
    void reminderChanged();
    void reminderTimeChanged();
    void reminderDoneChanged();
    void isSearchResultChanged();
    void updateSequenceNumberChanged();
    void loadedChanged();

    void loadingChanged();

private:
    void setLoading(bool loading);

    void syncToCacheFile();

    // const because we want to load on demand in getters. Keep this private!
    void load() const;
    void loadFromCacheFile() const;

private:
    QString m_guid;
    QString m_notebookGuid;
    QDateTime m_created;
    QDateTime m_updated;
    QString m_title;
    QStringList m_tagGuids;
    mutable EnmlDocument m_content; // loaded from cache on demand in const methods
    mutable QString m_tagline; // loaded from cache on demand in const methods
    qint64 m_reminderOrder;
    QDateTime m_reminderTime;
    QDateTime m_reminderDoneTime;
    bool m_isSearchResult;
    QHash<QString, Resource*> m_resources;
    quint32 m_updateSequenceNumber;
    mutable QFile m_cacheFile;
    QSettings m_infoFile;

    bool m_loading;
    mutable bool m_loaded;

    // Needed to be able to call private setLoading (we don't want to have that set by anyone except the NotesStore)
    friend class NotesStore;
};

#endif // NOTE_H
