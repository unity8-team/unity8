/*
 * Copyright (C) 2013 Canonical, Ltd.
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
 *
 * Author: Nick Dedekind <nick.dedekind@canonical.com>
 */

#ifndef UNITY_OBJECT_H
#define UNITY_OBJECT_H

#include <QQmlListProperty>
#include <QObject>

class UnityObject : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<QObject> children READ children)
    Q_CLASSINFO("DefaultProperty", "children")
public:
    explicit UnityObject(QObject *parent = 0);

    QQmlListProperty<QObject> children();

private:
    QList<QObject*> m_children;

    static void append(QQmlListProperty<QObject> *list, QObject *object);
    static void clear(QQmlListProperty<QObject> *list);
    static QObject *at(QQmlListProperty<QObject> *list, int index);
    static int count(QQmlListProperty<QObject> *list);
};

#endif // UNITY_OBJECT_H
