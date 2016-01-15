#ifndef SHORTCUTACTION_H
#define SHORTCUTACTION_H

#include <QObject>
#include <QKeySequence>
#include <QQuickItem>

class ShortcutAction : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool enabled READ isEnabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(QVariant shortcut READ shortcut WRITE setShortcut NOTIFY shortcutChanged)
    Q_PROPERTY(QQuickItem* target READ target WRITE setTarget NOTIFY targetChanged)

public:
    ShortcutAction(QObject* parent = nullptr);
    ~ShortcutAction();

    QVariant shortcut() const;
    void setShortcut(const QVariant &shortcut);

    bool isEnabled() const { return m_enabled; }
    void setEnabled(bool e);

    QQuickItem* target() const { return m_target; }
    void setTarget(QQuickItem* target);

    bool event(QEvent *e) override;

    void trigger(QObject* source = nullptr);

Q_SIGNALS:
    void targetChanged();
    void enabledChanged();
    void triggered(QObject* source = nullptr);
    void shortcutChanged(QVariant shortcut);

private:
    QKeySequence m_shortcut;
    bool m_enabled;
    QQuickItem* m_target;
};

#endif // SHORTCUTACTION_H
