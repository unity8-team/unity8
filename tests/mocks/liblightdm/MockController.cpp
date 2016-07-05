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

#include "MockController.h"

static QLightDM::MockController *m_instance = nullptr;

namespace QLightDM
{

MockController::MockController(QObject *parent)
  : QObject(parent)
{
    m_userMode = qgetenv("LIBLIGHTDM_MOCK_MODE");
    if (m_userMode.isEmpty()) {
        m_userMode = "full";
    }
    m_sessionMode = "full";
}

MockController::~MockController()
{
}

MockController *MockController::instance()
{
    if (!m_instance) {
        m_instance = new MockController;
    }
    return m_instance;
}

QString MockController::selectUserHint() const
{
    return m_selectUserHint;
}

void MockController::setSelectUserHint(const QString &selectUserHint)
{
    if (m_selectUserHint != selectUserHint) {
        m_selectUserHint = selectUserHint;
        Q_EMIT selectUserHintChanged();
    }
}

QString MockController::userMode() const
{
    return m_userMode;
}

void MockController::setUserMode(const QString &userMode)
{
    if (m_userMode != userMode) {
        m_userMode = userMode;
        Q_EMIT userModeChanged();
    }
}

QString MockController::sessionMode() const
{
    return m_sessionMode;
}

void MockController::setSessionMode(const QString &sessionMode)
{
    if (m_sessionMode != sessionMode) {
        m_sessionMode = sessionMode;
        Q_EMIT sessionModeChanged();
    }
}

}
