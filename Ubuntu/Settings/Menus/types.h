/*
 * Copyright (C) 2014 Canonical, Ltd.
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

#ifndef UBUNTUSETTINGSMENUSTYPES_H
#define UBUNTUSETTINGSMENUSTYPES_H

#include "pluginglobal.h"

#include <QObject>

class UBUNTUSETTINGSCOMPONENTS_EXPORT TransferState : public QObject
{
    Q_OBJECT
public:
    Q_ENUMS(TransferStates)
    enum TransferStates {
        QUEUED,
        RUNNING,
        PAUSED,
        CANCELED,
        HASHING,
        PROCESSING,
        FINISHED,
        ERROR
    };

    TransferState(QObject*parent=0):QObject(parent) {}
};

#endif // UBUNTUSETTINGSMENUSTYPES_H
