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
    Q_PROPERTY(int mouseX READ mouseX WRITE setMouseX NOTIFY mouseXChanged)
    Q_PROPERTY(int mouseY READ mouseY WRITE setMouseY NOTIFY mouseYChanged)
    Q_PROPERTY(QString cursor READ cursor WRITE setCursor NOTIFY cursorChanged)

public:
    explicit AethercastManager(QObject *parent = 0);
    ~AethercastManager();

    int mouseX() const;
    void setMouseX(int mouseX);

    int mouseY() const;
    void setMouseY(int mouseY);

    QString cursor() const;
    void setCursor(const QString &cursor);

public Q_SLOTS:
    void disconnectAll();

//public Q_SLOTS:
//    void sendMousePosition(int x, int y);

Q_SIGNALS:
    void cursorChanged();
    void mouseXChanged();
    void mouseYChanged();

private:
    ManagerInterface *m_manager;
    InputProvider *m_inputProvider;
};

#endif
