#include "sharedwindowstate.h"

#include <QQmlEngine>
#include <QDebug>

WindowData::WindowData(QObject *parent)
    : QObject(parent)
    , m_valid(false)
    , m_state(Normal)
    , m_stage(ApplicationInfoInterface::MainStage)
    , m_spread(false)
    , m_stateSource(0)
    , m_opacity(1.0)
    , m_scale(1.0)
    , m_geometry(new WindowStateGeometry(this))
    , m_windowedGeometry(new WindowStateGeometry(this))
{
}

WindowState::WindowState(QObject *parent)
    : QObject(parent)
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
        connect(m_data.data(), &WindowData::spreadChanged, this, &WindowState::spreadChanged);
        connect(m_data.data(), &WindowData::scaleChanged, this, &WindowState::scaleChanged);
        connect(m_data.data(), &WindowData::opacityChanged, this, &WindowState::opacityChanged);

        initialize();
    }
}

WindowStateGeometry* WindowState::geometry() const
{
    if (!m_data) return nullptr;
    return m_data->m_geometry;
}

WindowStateGeometry* WindowState::windowedGeometry() const
{
    if (!m_data) return nullptr;
    return m_data->m_windowedGeometry;
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

bool WindowState::spread() const
{
    if (!m_data)
        return false;
    return m_data->m_spread;
}

void WindowState::setSpread(bool spread)
{
    if (!m_data) return;
    if (m_data->m_spread == spread) {
        return;
    }
    m_data->m_spread = spread;
    Q_EMIT m_data->spreadChanged(spread);
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
        Q_EMIT geometryChanged();
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

WindowStateGeometry::WindowStateGeometry(QObject *parent)
    : QObject(parent)
{
}

int WindowStateGeometry::x() const
{
    return m_rect.x();
}

void WindowStateGeometry::setX(int x)
{
    if (m_rect.left() == x) return;
    m_rect.moveLeft(x);
    Q_EMIT xChanged(x);
}

int WindowStateGeometry::y() const
{
    return m_rect.y();
}

void WindowStateGeometry::setY(int y)
{
    if (m_rect.top() == y) return;
    m_rect.moveTop(y);
    Q_EMIT yChanged(y);
}

int WindowStateGeometry::width() const
{
    return m_rect.width();
}

void WindowStateGeometry::setWidth(int width)
{
    if (m_rect.width() == width) return;
    m_rect.setWidth(width);
    Q_EMIT widthChanged(width);
}

int WindowStateGeometry::height() const
{
    return m_rect.height();
}

void WindowStateGeometry::setHeight(int height)
{
    if (m_rect.height() == height) return;
    m_rect.setHeight(height);
    Q_EMIT heightChanged(height);
}
