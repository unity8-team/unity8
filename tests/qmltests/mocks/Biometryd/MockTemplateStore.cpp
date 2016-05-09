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

#include "MockTemplateStore.h"

MockTemplateStore::MockTemplateStore(QObject *parent)
{
}

MockSizeQuery* MockTemplateStore::size(MockUser* user)
{
    return new MockSizeQuery(this);
}

MockEnrollment* MockTemplateStore::enroll(MockUser* user)
{
    return new MockEnrollment(this);
}

MockClearance* MockTemplateStore::clear(MockUser* user)
{
    return new MockClearance(this);
}

#include "MockTemplateStore.moc"
