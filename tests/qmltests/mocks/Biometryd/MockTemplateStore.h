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

#ifndef MOCK_TEMPLATESTORE_H
#define MOCK_TEMPLATESTORE_H

#include <QObject>
#include "MockOperation.h"

class MockUser;

class MockSizeQuery : public MockOperation
{
    Q_OBJECT
public:
    MockSizeQuery(QObject *parent) :  MockOperation(parent)
    {
    }
};

class MockEnrollment : public MockOperation
{
    Q_OBJECT
public:
    MockEnrollment(QObject *parent) :  MockOperation(parent)
    {
    }
};

class MockClearance : public MockOperation
{
    Q_OBJECT
public:
    MockClearance(QObject *parent) :  MockOperation(parent)
    {
    }
};

class MockRemoval : public MockOperation
{
    Q_OBJECT
public:
    MockRemoval(QObject *parent) :  MockOperation(parent)
    {
    }
};

class MockList : public MockOperation
{
    Q_OBJECT
public:
    MockList(QObject *parent) :  MockOperation(parent)
    {
    }
};

class MockTemplateStore : public QObject
{
    Q_OBJECT
    Q_DISABLE_COPY(MockTemplateStore)

public:
    explicit MockTemplateStore(QObject *parent = 0);

    Q_INVOKABLE MockSizeQuery* size(MockUser* user);
    Q_INVOKABLE MockEnrollment* enroll(MockUser* user);
    Q_INVOKABLE MockClearance* clear(MockUser* user);
    Q_INVOKABLE MockRemoval* remove(MockUser* user,
                                    const QString &templateId);
    Q_INVOKABLE MockList* list(MockUser* user);
};

#endif // MOCK_TEMPLATESTORE_H
