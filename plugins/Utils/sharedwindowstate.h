#ifndef SHAREDWINDOWSTATE_H
#define SHAREDWINDOWSTATE_H

#include <QObject>
#include <QHash>
#include <QSharedPointer>
#include <QRect>
#include <QQmlParserStatus>
#include <unity/shell/application/ApplicationInfoInterface.h>

using namespace unity::shell::application;

class WindowData;

class WindowData : public QObject
{
    Q_OBJECT
    Q_ENUMS(State)
public:
    enum State {
        Normal = 1 << 0,
        Maximized = 1 << 1,
        Minimized = 1 << 2,
        Fullscreen = 1 << 3,
        MaximizedLeft = 1 << 4,
        MaximizedRight = 1 << 5,
        MaximizedHorizontally = 1 << 6,
        MaximizedVertically = 1 << 7
    };
    Q_DECLARE_FLAGS(States, State)
#if (QT_VERSION >= QT_VERSION_CHECK(5, 5, 0))
    Q_FLAG(States)
#endif

    WindowData(QObject* parent = 0);

Q_SIGNALS:
    void validChanged(bool valid);
    void stateChanged(State state);
    void stageChanged(ApplicationInfoInterface::Stage stage);
    void xChanged(int);
    void yChanged(int);
    void widthChanged(int);
    void heightChanged(int);
    void opacityChanged(qreal);
    void scaleChanged(qreal);

public:
    bool m_valid;
    State m_state;
    ApplicationInfoInterface::Stage m_stage;
    QRect m_geometry;
    qintptr m_stateSource;
    qreal m_opacity;
    qreal m_scale;
};

class WindowStateGeometry;

class WindowState : public QObject,
                    public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)

    Q_PROPERTY(bool valid READ valid NOTIFY validChanged)
    Q_PROPERTY(QString windowId READ windowId WRITE setWindowId NOTIFY windowIdChanged)
    Q_PROPERTY(WindowData::State state READ state WRITE setState NOTIFY stateChanged)
    Q_PROPERTY(bool stateSource READ stateSource NOTIFY stateChanged)
    Q_PROPERTY(ApplicationInfoInterface::Stage stage READ stage WRITE setStage NOTIFY stageChanged)

    Q_PROPERTY(qreal opacity READ opacity WRITE setOpacity NOTIFY opacityChanged)
    Q_PROPERTY(qreal scale READ scale WRITE setScale NOTIFY scaleChanged)
    Q_PROPERTY(WindowStateGeometry* geometry READ geometry CONSTANT)
public:

    explicit WindowState(QObject *parent = 0);
    ~WindowState();

    bool valid() const;

    QString windowId() const { return m_windowId; }
    void setWindowId(const QString& windowId);

    WindowStateGeometry* geometry() const;

    WindowData::State state() const;
    void setState(WindowData::State state);

    ApplicationInfoInterface::Stage stage() const;
    void setStage(ApplicationInfoInterface::Stage stage);

    qreal opacity() const;
    void setOpacity(qreal opacity);

    qreal scale() const;
    void setScale(qreal scale);

    bool stateSource() const;

    void classBegin() override {}
    void componentComplete() override;

Q_SIGNALS:
    void initialized();

    void validChanged(bool valid);
    void windowIdChanged(const QString& windowId);
    void stateChanged(WindowData::State state);
    void stageChanged(ApplicationInfoInterface::Stage stage);
    void opacityChanged(qreal opacity);
    void scaleChanged(qreal scale);

private:
    void initialize();

    QString m_windowId;
    WindowStateGeometry* m_geometry;
    QSharedPointer<WindowData> m_data;
    bool m_created;
    bool m_completed;

    friend class WindowStateGeometry;
};

class WindowStateGeometry : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int x READ x WRITE setX NOTIFY xChanged)
    Q_PROPERTY(int y READ y WRITE setY NOTIFY yChanged)
    Q_PROPERTY(int width READ width WRITE setWidth NOTIFY widthChanged)
    Q_PROPERTY(int height READ height WRITE setHeight NOTIFY heightChanged)
public:
    WindowStateGeometry(WindowState* windowState = 0);

    int x() const;
    void setX(int x);

    int y() const;
    void setY(int y);

    int width() const;
    void setWidth(int width);

    int height() const;
    void setHeight(int height);

Q_SIGNALS:
    void xChanged(int x);
    void yChanged(int y);
    void widthChanged(int width);
    void heightChanged(int height);

private:
    WindowState* m_state;
};

class SharedStateStorage : public QObject
{
    Q_OBJECT
public:
    static SharedStateStorage *instance();

    QSharedPointer<WindowData> windowData(const QString& wid, bool& created);

private:
    explicit SharedStateStorage(QObject *parent = 0);
    ~SharedStateStorage();

private:
    QHash<QString, QWeakPointer<WindowData>> m_states;
};

#endif // SHAREDWINDOWSTATE_H
