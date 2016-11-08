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

#ifndef MOCK_WINDOW_H
#define MOCK_WINDOW_H

// unity-api
#include <unity/shell/application/WindowInterface.h>

class MirSurface;

class Window : public unity::shell::application::WindowInterface
{
    Q_OBJECT

public:
    Window(int id);
    virtual ~Window();
    QPoint position() const override;
    QPoint requestedPosition() const override;
    void setRequestedPosition(const QPoint &) override;
    Mir::State state() const override;
    bool focused() const override;
    bool confinesMousePointer() const override;
    int id() const override;
    unity::shell::application::MirSurfaceInterface* surface() const override;

    void setSurface(MirSurface *surface);
    void setFocused(bool value);
    void setState(Mir::State state);

    QString toString() const;

Q_SIGNALS:
    void stateRequested(Mir::State);
    void closeRequested();

public Q_SLOTS:
    void requestState(Mir::State state) override;
    void requestFocus() override;
    void close() override;

private:
    void updatePosition();
    void updateState();
    void updateFocused();

    QPoint m_position;
    QPoint m_requestedPosition;
    bool m_focused{false};
    int m_id;
    Mir::State m_state{Mir::RestoredState};
    MirSurface *m_surface{nullptr};
};

#endif // MOCK_WINDOW_H
