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
    Q_PROPERTY(QString guid READ guid CONSTANT)
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(int noteCount READ noteCount NOTIFY noteCountChanged)
    // Don't forget to update clone() if you add new properties

public:
    explicit Tag(const QString &guid, quint32 updateSequenceNumber, QObject *parent = 0);
    ~Tag();

    QString guid() const;

    quint32 updateSequenceNumber() const;
    void setUpdateSequenceNumber(quint32 updateSuequenceNumber);

    QString name() const;
    void setName(const QString &guid);

    int noteCount() const;

    Tag *clone();

signals:
    void nameChanged();
    void noteCountChanged();

private slots:
    void noteAdded(const QString &noteGuid, const QString &notebookGuid);
    void noteRemoved(const QString &noteGuid, const QString &notebookGuid);
    void noteChanged(const QString &noteGuid, const QString &notebookGuid);

private:
    void syncToInfoFile();

private:
    quint32 m_updateSequenceNumber;
    QString m_guid;
    QString m_name;

    QList<QString> m_notesList;

    QSettings m_infoFile;

    friend class NotesStore;
};

#endif // TAG_H
