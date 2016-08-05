/*
 * Copyright (C) 2015 Canonical, Ltd.
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

#include "SessionsModel.h"

#include <QModelIndex>
#include <QString>
#include <QtTest>

class GreeterSessionsModelTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:

    void init()
    {
        model = new SessionsModel();
        QVERIFY(model);
        mock = model->mock();
        QVERIFY(mock);
    }

    void cleanup()
    {
        delete model;
        // mock will be a singleton, doesn't need to be cleaned
    }

    static QModelIndex findByKey(QAbstractItemModel *model, const QString& key)
    {
        for (int i = 0; i < model->rowCount(QModelIndex()); i++) {
            if (model->data(model->index(i, 0), QLightDM::SessionsModel::KeyRole).toString() == key)
                return model->index(i, 0);
        }

        return QModelIndex();
    }

    void testIconDirectoriesAreValid()
    {
        Q_FOREACH(const QUrl& searchDirectory, model->iconSearchDirectories())
        {
            QVERIFY(searchDirectory.isValid());
        }
    }

    void testMultipleSessionsCountIsCorrect()
    {
        mock->setProperty("sessionMode", "full");
        QVERIFY(model->rowCount(QModelIndex()) > 1);
    }

    void testNoSessionsCountIsCorrect()
    {
        mock->setProperty("sessionMode", "none");
        QVERIFY(model->rowCount(QModelIndex()) == 0);
    }

    void testSingleSessionCountIsCorrect()
    {
        mock->setProperty("sessionMode", "single");
        QVERIFY(model->rowCount(QModelIndex()) == 1);
    }

    void testSessionNameIsCorrect()
    {
        // This is testing the lookup, not the correctness of the strings,
        // so one test should be sufficient
        mock->setProperty("sessionMode", "full");
        QVERIFY(model->data(findByKey(model, "ubuntu"),
                Qt::DisplayRole).toString() == "Ubuntu");
    }

private:
    SessionsModel *model;
    QObject *mock;
};

QTEST_MAIN(GreeterSessionsModelTest)

#include "sessionsmodel.moc"
