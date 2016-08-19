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

#include "unityobject.h"

UnityObject::UnityObject(QObject *parent) : QObject(parent)
{
}

QQmlListProperty<QObject> UnityObject::children()
{
    return QQmlListProperty<QObject>(this, 0,
                                      UnityObject::append,
                                      UnityObject::count,
                                      UnityObject::at,
                                      UnityObject::clear);
}

void UnityObject::append(QQmlListProperty<QObject> *list, QObject *object)
{
    UnityObject *uobject = qobject_cast<UnityObject*>(list->object);
    if (uobject) {
        uobject->m_children.append(object);
    }
}

void UnityObject::clear(QQmlListProperty<QObject> *list)
{
    UnityObject *uobject = qobject_cast<UnityObject*>(list->object);
    if (uobject) {
        uobject->m_children.clear();
    }
}

QObject *UnityObject::at(QQmlListProperty<QObject> *list, int index)
{
    UnityObject *uobject = qobject_cast<UnityObject*>(list->object);
    if (uobject) {
        return uobject->m_children.value(index, nullptr);
    }
    return nullptr;
}

int UnityObject::count(QQmlListProperty<QObject> *list)
{
    UnityObject *uobject = qobject_cast<UnityObject*>(list->object);
    if (uobject) {
        return uobject->m_children.count();
    }
    return 0;
}
