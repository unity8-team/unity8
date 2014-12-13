/*
 * Copyright: 2014 Canonical, Ltd
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

#ifndef TAG_H
#define TAG_H

#include "utils/enmldocument.h"
#include "resource.h"
#include "utils/textformat.h"

#include <QObject>
#include <QDateTime>
#include <QStringList>
#include <QImage>
#include <QSettings>

class Tag: public QObject
{
    Q_OBJECT

    // Don't forget to update clone() if you add new properties
    Q_PROPERTY(QString guid READ guid NOTIFY guidChanged)
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(int noteCount READ noteCount NOTIFY noteCountChanged)
    // Don't forget to update clone() if you add new properties

    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(bool synced READ synced NOTIFY syncedChanged)
    Q_PROPERTY(bool syncError READ syncError NOTIFY syncErrorChanged)

public:
    explicit Tag(const QString &guid, quint32 updateSequenceNumber, QObject *parent = 0);
    ~Tag();

    QString guid() const;
    void setGuid(const QString &guid);

    quint32 updateSequenceNumber() const;
    void setUpdateSequenceNumber(quint32 updateSequenceNumber);

    quint32 lastSyncedSequenceNumber() const;

    QString name() const;
    void setName(const QString &guid);

    int noteCount() const;

    bool loading() const;
    bool synced() const;
    bool syncError() const;

    Tag *clone();

signals:
    void guidChanged();
    void nameChanged();
    void noteCountChanged();
    void loadingChanged();
    void syncedChanged();
    void syncErrorChanged();

private slots:
    void noteAdded(const QString &noteGuid, const QString &notebookGuid);
    void noteRemoved(const QString &noteGuid, const QString &notebookGuid);
    void noteChanged(const QString &noteGuid, const QString &notebookGuid);
    void noteGuidChanged(const QString &oldGuid, const QString &newGuid);

private:
    void syncToInfoFile();
    void deleteInfoFile();
    void setLastSyncedSequenceNumber(quint32 lastSyncedSequenceNumber);
    void setLoading(bool loading);
    void setSyncError(bool syncError);

private:
    quint32 m_updateSequenceNumber;
    quint32 m_lastSyncedSequenceNumber;
    QString m_guid;
    QString m_name;

    QList<QString> m_notesList;

    QString m_infoFile;

    bool m_loading;
    bool m_synced;
    bool m_syncError;

    friend class NotesStore;
};

#endif // TAG_H
