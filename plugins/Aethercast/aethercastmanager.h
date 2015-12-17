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

#ifndef AETHERCAST_MANAGER_H
#define AETHERCAST_MANAGER_H

#include <QtCore/QObject>
#include <QtGui/QColor>

class ManagerInterface;
class InputProvider;

class AethercastManager: public QObject
{
    Q_OBJECT
    Q_PROPERTY(int cursorX READ cursorX WRITE setCursorX NOTIFY cursorXChanged)
    Q_PROPERTY(int cursorY READ cursorY WRITE setCursorY NOTIFY cursorYChanged)
    Q_PROPERTY(QString cursor READ cursor WRITE setCursor NOTIFY cursorChanged)

public:
    explicit AethercastManager(QObject *parent = 0);
    ~AethercastManager();

    int cursorX() const;
    void setCursorX(int cursorX);

    int cursorY() const;
    void setCursorY(int cursorY);

    QString cursor() const;
    void setCursor(const QString &cursor);

public Q_SLOTS:
    void sendMousePosition(int x, int y);

Q_SIGNALS:
    void cursorChanged();

private:
    ManagerInterface *m_manager;
    InputProvider *m_inputProvider;
};

#endif
