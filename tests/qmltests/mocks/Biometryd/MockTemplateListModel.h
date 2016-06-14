/*
 * Copyright (C) 2016 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef MOCK_TEMPLATELISTMODEL_H
#define MOCK_TEMPLATELISTMODEL_H

#include <QAbstractListModel>
#include "MockTemplateStore.h"

class MockTemplateListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int uid
               READ uid
               WRITE setUid
               NOTIFY uidChanged)
    Q_PROPERTY(MockTemplateStore* templateStore
               READ templateStore
               WRITE setTemplateStore
               NOTIFY templateStoreChanged)
public:
    explicit MockTemplateListModel(QObject *parent = 0);
    ~MockTemplateListModel() {};

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;
    int rowCount(const QModelIndex &parent = QModelIndex()) const;

    int uid() const;
    void setUid(const int &uid);

    MockTemplateStore* templateStore() const;
    void setTemplateStore(const MockTemplateStore* templateStore);

    void add();
    void remove(const QString &id);

    Q_INVOKABLE void mockAddFingerprint(const QString &id); // mock only
    Q_INVOKABLE void mockRemoveFingerprint(const QString &id); // mock only

signals:
    void uidChanged();
    void templateStoreChanged();

private:
    int m_uid;
    MockTemplateStore* m_ts;
    QList<QString> m_templates;
};

#endif // MOCK_TEMPLATELISTMODEL_H
