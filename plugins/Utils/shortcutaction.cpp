#include "shortcutaction.h"

#include <QQuickItem>
#include <QQuickWindow>
#include <QVariant>
#include <QShortcutEvent>
#include <private/qguiapplication_p.h>

namespace {

bool qShortcutContextMatcher(QObject *o, Qt::ShortcutContext context)
{
    if (!static_cast<ShortcutAction*>(o)->isEnabled())
        return false;

    switch (context) {
    case Qt::ApplicationShortcut:
    case Qt::WindowShortcut:
        break;
    case Qt::WidgetShortcut: {
        QQuickItem* target = static_cast<ShortcutAction*>(o)->target();
        if (target && target->hasActiveFocus()) {
            return true;
        }
        return true;
    }
    case Qt::WidgetWithChildrenShortcut:
        break;
    }

    return false;
}

}


ShortcutAction::ShortcutAction(QObject* parent)
    : QObject(parent)
    , m_enabled(true)
{
}

ShortcutAction::~ShortcutAction()
{
    setShortcut(QString());
}

QVariant ShortcutAction::shortcut() const
{
    return m_shortcut.toString(QKeySequence::NativeText);
}

void ShortcutAction::setShortcut(const QVariant &arg)
{
    QKeySequence sequence;
    if (arg.type() == QVariant::Int)
        sequence = QKeySequence(static_cast<QKeySequence::StandardKey>(arg.toInt()));
    else
        sequence = QKeySequence::fromString(arg.toString());

    if (sequence == m_shortcut)
        return;

    if (!m_shortcut.isEmpty())
        QGuiApplicationPrivate::instance()->shortcutMap.removeShortcut(0, this, m_shortcut);

    m_shortcut = sequence;

    if (!m_shortcut.isEmpty()) {
        Qt::ShortcutContext context = Qt::WidgetShortcut;
        QGuiApplicationPrivate::instance()->shortcutMap.addShortcut(this, m_shortcut, context, qShortcutContextMatcher);
    }
    Q_EMIT shortcutChanged(shortcut());
}

void ShortcutAction::setEnabled(bool e)
{
    if (e == m_enabled) return;
    m_enabled = e;

    Q_EMIT enabledChanged();
}

void ShortcutAction::setTarget(QQuickItem *target)
{
    if (target == m_target) return;
    m_target = target;

    Q_EMIT targetChanged();
}

bool ShortcutAction::event(QEvent *e)
{
    if (!m_enabled)
        return false;

    if (e->type() != QEvent::Shortcut)
        return false;

    QShortcutEvent *se = static_cast<QShortcutEvent *>(e);

    Q_ASSERT_X(se->key() == m_shortcut,
               "QQuickAction::event",
               "Received shortcut event from incorrect shortcut");
    if (se->isAmbiguous()) {
        qWarning("QQuickAction::event: Ambiguous shortcut overload: %s", se->key().toString(QKeySequence::NativeText).toLatin1().constData());
        return false;
    }

    trigger();

    return true;
}

void ShortcutAction::trigger(QObject* source)
{
    if (!m_enabled)
        return;

    Q_EMIT triggered(source);
}

