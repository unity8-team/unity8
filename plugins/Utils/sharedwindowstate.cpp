#include "sharedwindowstate.h"

#include <QQmlEngine>
#include <QDebug>

WindowData::WindowData(QObject *parent)
    : QObject(parent)
    , m_valid(false)
    , m_state(Normal)
    , m_stage(ApplicationInfoInterface::MainStage)
    , m_geometry(0, 0, 0, 0)
    , m_stateSource(0)
    , m_opacity(1.0)
    , m_scale(1.0)
{
}

WindowState::WindowState(QObject *parent)
    : QObject(parent)
    , m_geometry(new WindowStateGeometry(this))
    , m_created(false)
    , m_completed(false)
{
}

WindowState::~WindowState()
{
}

bool WindowState::valid() const
{
    if (!m_data) return false;
    return m_data->m_valid;
}


void WindowState::setWindowId(const QString &windowId)
{
    if (m_windowId == windowId) {
        return;
    }

    if (!m_windowId.isEmpty()) {
        if (!m_data.isNull()) {
            disconnect(m_data.data(), 0, m_geometry, 0);
            disconnect(m_data.data(), 0, this, 0);
            m_data.clear();
            Q_EMIT validChanged(false);
        }
    }

    m_windowId = windowId;
    Q_EMIT windowIdChanged(windowId);

    if (!m_windowId.isEmpty()) {
        m_created = false;
        m_data = SharedStateStorage::instance()->windowData(windowId, m_created);

        connect(m_data.data(), &WindowData::validChanged, this, &WindowState::validChanged);
        connect(m_data.data(), &WindowData::stateChanged, this, &WindowState::stateChanged);
        connect(m_data.data(), &WindowData::stageChanged, this, &WindowState::stageChanged);
        connect(m_data.data(), &WindowData::scaleChanged, this, &WindowState::scaleChanged);
        connect(m_data.data(), &WindowData::opacityChanged, this, &WindowState::opacityChanged);

        connect(m_data.data(), &WindowData::xChanged, m_geometry, &WindowStateGeometry::xChanged);
        connect(m_data.data(), &WindowData::yChanged, m_geometry, &WindowStateGeometry::yChanged);
        connect(m_data.data(), &WindowData::widthChanged, m_geometry, &WindowStateGeometry::widthChanged);
        connect(m_data.data(), &WindowData::heightChanged, m_geometry, &WindowStateGeometry::heightChanged);

        initialize();
    }
}

WindowStateGeometry* WindowState::geometry() const
{
    return m_geometry;
}

WindowData::State WindowState::state() const
{
    if (!m_data)
        return WindowData::Normal;
    return m_data->m_state;
}

void WindowState::setState(WindowData::State state)
{
    if (!m_data) return;
    if (m_data->m_state == state) {
        return;
    }
    m_data->m_stateSource = (qintptr)this;
    m_data->m_state = state;
    Q_EMIT m_data->stateChanged(state);

}

ApplicationInfoInterface::Stage WindowState::stage() const
{
    if (!m_data)
        return ApplicationInfoInterface::MainStage;
    return m_data->m_stage;
}

void WindowState::setStage(ApplicationInfoInterface::Stage stage)
{
    if (!m_data) return;
    if (m_data->m_stage == stage) {
        return;
    }
    m_data->m_stage = stage;
    Q_EMIT m_data->stageChanged(stage);
}

qreal WindowState::opacity() const
{
    return m_data ? m_data->m_opacity : 1.0;
}

void WindowState::setOpacity(qreal opacity)
{
    if (!m_data) return;
    if (m_data->m_opacity == opacity) {
        return;
    }
    m_data->m_opacity = opacity;
    Q_EMIT m_data->opacityChanged(opacity);
}

qreal WindowState::scale() const
{
    return m_data ? m_data->m_scale : 1.0;
}

void WindowState::setScale(qreal scale)
{
    if (!m_data) return;
    if (m_data->m_scale == scale) {
        return;
    }
    m_data->m_scale = scale;
    Q_EMIT m_data->scaleChanged(scale);
}

bool WindowState::stateSource() const
{
    if (!m_data) return false;
    return m_data->m_stateSource == (qintptr)this;
}

void WindowState::componentComplete()
{
    m_completed = true;
    initialize();
}

void WindowState::initialize()
{
    if (!m_completed) return;

    if (m_created) {
        Q_EMIT initialized();
    } else if (m_data) {
        Q_EMIT stateChanged(m_data->m_state);
        Q_EMIT stageChanged(m_data->m_stage);
        Q_EMIT m_geometry->xChanged(m_data->m_geometry.x());
        Q_EMIT m_geometry->yChanged(m_data->m_geometry.y());
        Q_EMIT m_geometry->widthChanged(m_data->m_geometry.x());
        Q_EMIT m_geometry->heightChanged(m_data->m_geometry.height());
    }

    if (m_data) {
        if (!m_data->m_valid) {
            // tell all the instances of the update
            m_data->m_valid = true;
            Q_EMIT m_data->validChanged(true);
        } else {
            // only tell this instnace.
            Q_EMIT validChanged(true);
        }
    }
}

SharedStateStorage *SharedStateStorage::instance()
{
    static SharedStateStorage storage;
    return &storage;
}

SharedStateStorage::SharedStateStorage(QObject *parent)
    : QObject(parent)
{
}

SharedStateStorage::~SharedStateStorage()
{
}

QSharedPointer<WindowData> SharedStateStorage::windowData(const QString &wid, bool& created)
{
    auto ptr = m_states.value(wid, QWeakPointer<WindowData>());
    QSharedPointer<WindowData> state = ptr.toStrongRef();
    if (state.isNull()) {
        state.reset(new WindowData(this));
        m_states[wid] = state.toWeakRef();
        created = true;
    }
    return state;
}

WindowStateGeometry::WindowStateGeometry(WindowState *windowState)
    : QObject(windowState)
    , m_state(windowState)
{
}

int WindowStateGeometry::x() const
{
    if (!m_state->m_data) return 0;
    return m_state->m_data->m_geometry.x();
}

void WindowStateGeometry::setX(int x)
{
    if (!m_state->m_data || m_state->m_data->m_geometry.x() == x) return;
    m_state->m_data->m_geometry.moveLeft(x);
    Q_EMIT m_state->m_data->xChanged(x);
}

int WindowStateGeometry::y() const
{
    if (!m_state->m_data) return 0;
    return m_state->m_data->m_geometry.y();
}

void WindowStateGeometry::setY(int y)
{
    if (!m_state->m_data || m_state->m_data->m_geometry.y() == y) return;
    m_state->m_data->m_geometry.moveTop(y);
    Q_EMIT m_state->m_data->yChanged(y);
}

int WindowStateGeometry::width() const
{
    if (!m_state->m_data) return 0;
    return m_state->m_data->m_geometry.width();
}

void WindowStateGeometry::setWidth(int width)
{
    if (!m_state->m_data || m_state->m_data->m_geometry.width() == width) return;
    m_state->m_data->m_geometry.setWidth(width);
    Q_EMIT m_state->m_data->widthChanged(width);
}

int WindowStateGeometry::height() const
{
    if (!m_state->m_data) return 0;
    return m_state->m_data->m_geometry.height();
}

void WindowStateGeometry::setHeight(int height)
{
    if (!m_state->m_data || m_state->m_data->m_geometry.height() == height) return;
    m_state->m_data->m_geometry.setHeight(height);
    Q_EMIT m_state->m_data->heightChanged(height);
}
