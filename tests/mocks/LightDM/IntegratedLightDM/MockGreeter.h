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
 *
 */

// The real, production, Greeter
#include <Greeter.h>

#ifndef MOCK_UNITY_GREETER_H
#define MOCK_UNITY_GREETER_H

class MockGreeter : public Greeter {
    Q_OBJECT

    Q_PROPERTY(QString mockMode READ mockMode WRITE setMockMode NOTIFY mockModeChanged)
    Q_PROPERTY(QString selectUser READ selectUserHint WRITE setSelectUserHint NOTIFY selectUserHintChanged)
    Q_PROPERTY(bool hasGuestAccount READ hasGuestAccount WRITE setHasGuestAccount NOTIFY hasGuestAccountChanged)

public:
    QString mockMode() const;
    void setMockMode(QString mockMode);

    QString selectUserHint() const;
    void setSelectUserHint(const QString &selectUserHint);

    bool hasGuestAccount() const;
    void setHasGuestAccount(bool hasGuestAccount);

Q_SIGNALS:
    void mockModeChanged(QString mode);
    void selectUserHintChanged();
    void hasGuestAccountChanged();
};

#endif // MOCK_UNITY_GREETER_H
