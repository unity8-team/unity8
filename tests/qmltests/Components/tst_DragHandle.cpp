/*
 * Copyright (C) 2013 Canonical, Ltd.
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

#include <functional>
#include <QtTest/QtTest>
#include <QtCore/QObject>
#include <qpa/qwindowsysteminterface.h>
#include <QtQuick/QQuickView>
#include <QtQml/QQmlEngine>

#include <DirectionalDragArea.h>

class FakeTimer : public UbuntuGestures::AbstractTimer
{
    Q_OBJECT
public:
    FakeTimer(QObject *parent = 0)
        : UbuntuGestures::AbstractTimer(parent)
    {}

    virtual int interval() const { return m_duration; }
    virtual void setInterval(int msecs) { m_duration = msecs; }
private:
    int m_duration;
};

class FakeTimeSource : public UbuntuGestures::TimeSource
{
public:
    FakeTimeSource() { m_msecsSinceReference = 0; }
    qint64 msecsSinceReference() override {return m_msecsSinceReference;}
    qint64 m_msecsSinceReference;
};

class tst_DragHandle: public QObject
{
    Q_OBJECT
public:
    tst_DragHandle() : m_device(0) { }
private Q_SLOTS:
    void initTestCase(); // will be called before the first test function is executed
    void cleanupTestCase(); // will be called after the last test function was executed.

    void init(); // called right before each and every test function is executed
    void cleanup(); // called right after each and every test function is executed

    void dragThreshold_horizontal();
    void dragThreshold_horizontal_data();
    void dragThreshold_vertical();
    void dragThreshold_vertical_data();
    void stretch_horizontal();
    void stretch_vertical();
    void hintingAnimation();
    void hintingAnimation_data();
    void hintingAnimation_dontRestartAfterFinishedAndStillPressed();
    void hintingAnimation_persistentHint();
    void hintingAnimation_persistentHint_data();
    void hintingAnimation_releaseAfterPersistentHint();
    void hintingAnimation_releaseAfterPersistentHint_data();
    void hintingAnimation_rollbackPersistentHint();
    void hintingAnimation_rollbackPersistentHint_data();
    void hintingAnimation_tapThenShowWithHandle();
    void hintingAnimation_tapThenShowWithHandle_data();
    void hintingAnimation_tapThenHideParent();
    void hintingAnimation_tapThenHideParent_data();
    void hintingAnimation_tapThenShowParent();
    void hintingAnimation_tapThenShowParent_data();
    void hintingAnimation_changingPersistencyDuration();
    void hintingAnimation_changingPersistencyDuration_data();
    void hintingAnimation_resetHintRollbackTimer();
    void hintingAnimation_resetHintRollbackTimer_data();
    void hintingAnimation_resetHintRollbackTimerDuringDrag();
    void hintingAnimation_resetHintRollbackTimerDuringDrag_data();

private:
    void flickAndHold(DirectionalDragArea *dragHandle, qreal distance);
    void drag(QPointF &touchPoint, const QPointF& direction, qreal distance,
              int numSteps, qint64 timeMs = 500);
    DirectionalDragArea *fetchAndSetupDragHandle(const char *objectName);
    qreal fetchDragThreshold(DirectionalDragArea *dragHandle);
    void tryCompare(std::function<qreal ()> actualFunc, qreal expectedValue);

    QQuickView *createView();
    QQuickView *m_view;
    QTouchDevice *m_device;
    FakeTimer *m_fakeTimer;
    QSharedPointer<FakeTimeSource> m_fakeTimeSource;
};


void tst_DragHandle::initTestCase()
{
    if (!m_device) {
        m_device = new QTouchDevice;
        m_device->setType(QTouchDevice::TouchScreen);
        QWindowSystemInterface::registerTouchDevice(m_device);
    }

    m_view = 0;
}

void tst_DragHandle::cleanupTestCase()
{
}

void tst_DragHandle::init()
{
    m_view = createView();
    m_view->setSource(QUrl::fromLocalFile(TEST_DIR"/tst_DragHandle.qml"));

    m_view->show();
    QVERIFY(QTest::qWaitForWindowExposed(m_view));
    QVERIFY(m_view->rootObject() != 0);
    qApp->processEvents();

    m_fakeTimer = new FakeTimer;
    m_fakeTimeSource.reset(new FakeTimeSource);

    // disable the button row so that it wont steal mouse events.
    QQuickItem *buttonRow =  m_view->rootObject()->findChild<QQuickItem*>("buttonRow");
    if (buttonRow) {
        buttonRow->setEnabled(false);
    }
}

void tst_DragHandle::cleanup()
{
    delete m_view;
    m_view = 0;

    delete m_fakeTimer;
    m_fakeTimer = 0;

    m_fakeTimeSource.reset();
}

QQuickView *tst_DragHandle::createView()
{
    QQuickView *window = new QQuickView(0);
    window->setResizeMode(QQuickView::SizeRootObjectToView);
    window->engine()->addImportPath(QLatin1String(UBUNTU_GESTURES_PLUGIN_DIR));
    window->engine()->addImportPath(QLatin1String(TEST_DIR));

    return window;
}

void tst_DragHandle::tryCompare(std::function<qreal ()> actualFunc,
                                qreal expectedValue)
{
    int waitCount = 0;
    while (actualFunc() != expectedValue && waitCount < 100) {
        QTest::qWait(50);
        ++waitCount;
    }
    QCOMPARE(actualFunc(), expectedValue);
}

namespace {
QPointF calculateDirectionVector(DirectionalDragArea *edgeDragArea)
{
    QPointF localOrigin(0., 0.);
    QPointF localDirection;
    switch (edgeDragArea->direction()) {
        case Direction::Upwards:
            localDirection.rx() = 0.;
            localDirection.ry() = -1.;
            break;
        case Direction::Downwards:
            localDirection.rx() = 0.;
            localDirection.ry() = 1;
            break;
        case Direction::Leftwards:
            localDirection.rx() = -1.;
            localDirection.ry() = 0.;
            break;
        default: // Direction::Rightwards:
            localDirection.rx() = 1.;
            localDirection.ry() = 0.;
            break;
    }
    QPointF sceneOrigin = edgeDragArea->mapToScene(localOrigin);
    QPointF sceneDirection = edgeDragArea->mapToScene(localDirection);
    return sceneDirection - sceneOrigin;
}
}

void tst_DragHandle::flickAndHold(DirectionalDragArea *dragHandle,
                                  qreal distance)
{
    QPointF initialTouchPos = dragHandle->mapToScene(
        QPointF(dragHandle->width() / 2.0, dragHandle->height() / 2.0));
    QPointF touchPoint = initialTouchPos;

    QTest::touchEvent(m_view, m_device).press(0, touchPoint.toPoint());

    int numSteps = 10;
    QPointF dragDirectionVector = calculateDirectionVector(dragHandle);
    drag(touchPoint, dragDirectionVector, distance, numSteps);

    // Wait for quite a bit before finally releasing to make a very low flick/release
    // speed.
    m_fakeTimeSource->m_msecsSinceReference += 5000;
    QTest::touchEvent(m_view, m_device).release(0, touchPoint.toPoint());
}

void tst_DragHandle::drag(QPointF &touchPoint, const QPointF& direction, qreal distance,
                          int numSteps, qint64 timeMs)
{
    qint64 timeStep = timeMs / numSteps;
    QPointF touchMovement = direction * (distance / (qreal)numSteps);
    for (int i = 0; i < numSteps; ++i) {
        touchPoint += touchMovement;
        m_fakeTimeSource->m_msecsSinceReference += timeStep;
        QTest::touchEvent(m_view, m_device).move(0, touchPoint.toPoint());
    }
}

DirectionalDragArea *tst_DragHandle::fetchAndSetupDragHandle(const char *objectName)
{
    DirectionalDragArea *dragHandle =
        m_view->rootObject()->findChild<DirectionalDragArea*>(objectName);
    Q_ASSERT(dragHandle != 0);
    dragHandle->setRecognitionTimer(m_fakeTimer);
    dragHandle->setTimeSource(m_fakeTimeSource);

    AxisVelocityCalculator *edgeDragEvaluator =
        dragHandle->findChild<AxisVelocityCalculator*>("edgeDragEvaluator");
    Q_ASSERT(edgeDragEvaluator != 0);
    edgeDragEvaluator->setTimeSource(m_fakeTimeSource);

    return dragHandle;
}

qreal tst_DragHandle::fetchDragThreshold(DirectionalDragArea *dragHandle)
{
    AxisVelocityCalculator *edgeDragEvaluator =
        dragHandle->findChild<AxisVelocityCalculator*>("edgeDragEvaluator");
    Q_ASSERT(edgeDragEvaluator != 0);

    return edgeDragEvaluator->property("dragThreshold").toReal();
}

/*
    Checks that ending a low-speed drag before dragThreshold results in the
    Showable getting back to its original position, whereas ending after dragThreshold
    results in Showable continuing until reaching its new states (shown or hidden)
 */
void tst_DragHandle::dragThreshold_horizontal()
{
    QFETCH(qreal, rotation);

    QQuickItem *baseItem =  m_view->rootObject()->findChild<QQuickItem*>("baseItem");
    baseItem->setRotation(rotation);

    DirectionalDragArea *dragHandle = fetchAndSetupDragHandle("rightwardsDragHandle");

    qreal dragThreshold = fetchDragThreshold(dragHandle);

    // end before the threshold
    flickAndHold(dragHandle, dragThreshold * 0.7);

    // should rollback
    QQuickItem *parentItem = dragHandle->parentItem();
    tryCompare([&](){ return parentItem->x(); }, -parentItem->width());
    QCOMPARE(parentItem->property("shown").toBool(), false);

    // end after the threshold
    flickAndHold(dragHandle, dragThreshold * 1.2);

    // should keep going until completion
    tryCompare([&](){ return parentItem->x(); }, 0);
    QCOMPARE(parentItem->property("shown").toBool(), true);

    dragHandle = fetchAndSetupDragHandle("leftwardsDragHandle");

    dragThreshold = fetchDragThreshold(dragHandle);

    // end before the threshold
    flickAndHold(dragHandle, dragThreshold * 0.7);

    // should rollback
    tryCompare([&](){ return parentItem->x(); }, 0);
    QCOMPARE(parentItem->property("shown").toBool(), true);

    // end after the threshold
    flickAndHold(dragHandle, dragThreshold * 1.2);

    // should keep going until completion
    tryCompare([&](){ return parentItem->x(); }, -parentItem->width());
    QCOMPARE(parentItem->property("shown").toBool(), false);
}

void tst_DragHandle::dragThreshold_horizontal_data()
{
    QTest::addColumn<qreal>("rotation");

    QTest::newRow("not rotated") << 0.;
    QTest::newRow("rotated 90")  << 90.;
}

void tst_DragHandle::dragThreshold_vertical()
{
    QFETCH(qreal, rotation);

    QQuickItem *baseItem =  m_view->rootObject()->findChild<QQuickItem*>("baseItem");
    baseItem->setRotation(rotation);

    DirectionalDragArea *dragHandle = fetchAndSetupDragHandle("downwardsDragHandle");

    qreal dragThreshold = fetchDragThreshold(dragHandle);

    // end before the threshold
    flickAndHold(dragHandle, dragThreshold * 0.7);

    // should rollback
    QQuickItem *parentItem = dragHandle->parentItem();
    tryCompare([&](){ return parentItem->y(); }, -parentItem->height());
    QCOMPARE(parentItem->property("shown").toBool(), false);

    // end after the threshold
    flickAndHold(dragHandle, dragThreshold * 1.2);

    // should keep going until completion
    tryCompare([&](){ return parentItem->y(); }, 0);
    QCOMPARE(parentItem->property("shown").toBool(), true);

    dragHandle = fetchAndSetupDragHandle("upwardsDragHandle");

    dragThreshold = fetchDragThreshold(dragHandle);

    // end before the threshold
    flickAndHold(dragHandle, dragThreshold * 0.7);

    // should rollback
    tryCompare([&](){ return parentItem->y(); }, 0);
    QCOMPARE(parentItem->property("shown").toBool(), true);

    // end after the threshold
    flickAndHold(dragHandle, dragThreshold * 1.2);

    // should keep going until completion
    tryCompare([&](){ return parentItem->y(); }, -parentItem->height());
    QCOMPARE(parentItem->property("shown").toBool(), false);
}

void tst_DragHandle::dragThreshold_vertical_data()
{
    QTest::addColumn<qreal>("rotation");

    QTest::newRow("not rotated") << 0.;
    QTest::newRow("rotated 90")  << 90.;
}

/*
  Checks that when the stretch property is true, dragging the DragHandle increases
  the width or height (depending on its direction) of its parent Showable
 */
void tst_DragHandle::stretch_horizontal()
{
    DirectionalDragArea *dragHandle = fetchAndSetupDragHandle("rightwardsDragHandle");
    qreal totalDragDistance = dragHandle->property("maxTotalDragDistance").toReal();
    QQuickItem *parentItem = dragHandle->parentItem();

    // enable strech mode
    m_view->rootObject()->setProperty("stretch", QVariant(true));

    QCOMPARE(parentItem->width(), 0.0);

    // flick all the way
    flickAndHold(dragHandle, totalDragDistance);

    // should keep going until completion
    // Parent item should now have its full height
    tryCompare([&](){ return parentItem->width(); }, totalDragDistance);
    QCOMPARE(parentItem->property("shown").toBool(), true);

    dragHandle = fetchAndSetupDragHandle("leftwardsDragHandle");

    // flick all the way
    flickAndHold(dragHandle, totalDragDistance);

    // should keep going until completion
    // Parent item should now have its full height
    tryCompare([&](){ return parentItem->width(); }, 0.0);
    QCOMPARE(parentItem->property("shown").toBool(), false);
}

void tst_DragHandle::stretch_vertical()
{
    DirectionalDragArea *dragHandle = fetchAndSetupDragHandle("downwardsDragHandle");
    qreal totalDragDistance = dragHandle->property("maxTotalDragDistance").toReal();
    QQuickItem *parentItem = dragHandle->parentItem();

    // enable strech mode
    m_view->rootObject()->setProperty("stretch", QVariant(true));

    QCOMPARE(parentItem->height(), 0.0);

    // flick all the way
    flickAndHold(dragHandle, totalDragDistance);

    // should keep going until completion
    // Parent item should now have its full height
    tryCompare([&](){ return parentItem->height(); }, totalDragDistance);
    QCOMPARE(parentItem->property("shown").toBool(), true);

    dragHandle = fetchAndSetupDragHandle("upwardsDragHandle");

    // flick all the way
    flickAndHold(dragHandle, totalDragDistance);

    // should keep going until completion
    // Parent item should now have its full height
    tryCompare([&](){ return parentItem->height(); }, 0.0);
    QCOMPARE(parentItem->property("shown").toBool(), false);
}

/*
    Set DragHandle.hintDisplacement to a value bigger than zero.
    Then lay a finger on the DragHandle.
    The expected behavior is that it will move or strech its parent Showable
    by hintDisplacement pixels.
 */
void tst_DragHandle::hintingAnimation()
{
    QFETCH(QString, handle);
    QFETCH(int, hintAnimationDuration);
    QFETCH(bool, partialHint);

    DirectionalDragArea *dragHandle = fetchAndSetupDragHandle(handle.toUtf8().data());
    QQuickItem *parentItem = dragHandle->parentItem();
    qreal hintDisplacement = 100.0;

    // enable hinting animations and stretch mode
    m_view->rootObject()->setProperty("hintDisplacement", QVariant(hintDisplacement));
    m_view->rootObject()->setProperty("stretch", QVariant(true));
    m_view->rootObject()->setProperty("hintAnimationDuration", QVariant(hintAnimationDuration));

    switch (dragHandle->direction()) {
        case Direction::Upwards:
        case Direction::Downwards:
            QCOMPARE(parentItem->height(), 0.0);
            break;
        case Direction::Leftwards:
        default: // Direction::Rightwards:
            QCOMPARE(parentItem->width(), 0.0);
            break;
    }

    QPointF initialTouchPos = dragHandle->mapToScene(
        QPointF(dragHandle->width() / 2.0, dragHandle->height() / 2.0));
    QPointF touchPoint = initialTouchPos;

    // Pressing causes the Showable to be stretched by hintDisplacement pixels
    QTest::touchEvent(m_view, m_device).press(0, touchPoint.toPoint());

    switch (dragHandle->direction()) {
        case Direction::Upwards:
        case Direction::Downwards:
                if (partialHint) {
                    tryCompare([&](){ return parentItem->height() > 0.0; }, true);
                } else {
                    tryCompare([&](){ return parentItem->height(); }, hintDisplacement);
                }
            break;
        case Direction::Leftwards:
        default: // Direction::Rightwards:
            if (partialHint) {
                tryCompare([&](){ return parentItem->width() > 0.0; }, true);
            } else {
                tryCompare([&](){ return parentItem->width(); }, hintDisplacement);
            }
            break;
    }

    // Releasing causes the Showable to shrink back to 0 pixels.
    QTest::touchEvent(m_view, m_device).release(0, touchPoint.toPoint());

    switch (dragHandle->direction()) {
        case Direction::Upwards:
        case Direction::Downwards:
        tryCompare([&](){ return parentItem->height(); }, 0.0);
            break;
        case Direction::Leftwards:
        default: // Direction::Rightwards:
        tryCompare([&](){ return parentItem->width(); }, 0.0);
            break;
    }

    QCOMPARE(parentItem->property("shown").toBool(), false);
}

void tst_DragHandle::hintingAnimation_data()
{
    QTest::addColumn<QString>("handle");
    QTest::addColumn<int>("hintAnimationDuration");
    QTest::addColumn<bool>("partialHint");

    QTest::newRow("downwards") << "downwardsDragHandle" << 150 << false;
    QTest::newRow("rightwards")  << "rightwardsDragHandle" << 150 << false;
    QTest::newRow("downwards_longAnimation") << "downwardsDragHandle" << 500 << false;
    QTest::newRow("rightwards_longAnimation")  << "rightwardsDragHandle" << 500 << false;
    QTest::newRow("downwards_longAnimation_partialHint") << "downwardsDragHandle" << 500 << true;
    QTest::newRow("rightwards_longAnimation_partialHint")  << "rightwardsDragHandle" << 500 << true;
}

/*
    Regression test for LP#1269022: https://bugs.launchpad.net/unity8/+bug/1269022

    1) Click on handle.
    2) wait for hint portion to appear
    3) slowly drag handle, only a few pixels

    Expected outcome:
        Nothing happens

    Actual outcome:
        Handle will momentarily move back to zero position, then back down to the
        hint displacement location.
 */
void tst_DragHandle::hintingAnimation_dontRestartAfterFinishedAndStillPressed()
{
    DirectionalDragArea *dragHandle = fetchAndSetupDragHandle("downwardsDragHandle");
    QQuickItem *parentItem = dragHandle->parentItem();
    qreal hintDisplacement = 100.0;

    // enable hinting animations
    m_view->rootObject()->setProperty("hintDisplacement", QVariant(hintDisplacement));
    m_view->rootObject()->setProperty("stretch", QVariant(true));

    QCOMPARE(parentItem->height(), 0.0);

    QPointF initialTouchPos = dragHandle->mapToScene(
        QPointF(dragHandle->width() / 2.0, dragHandle->height() / 2.0));
    QPointF touchPoint = initialTouchPos;

    // Pressing causes the Showable to be stretched by hintDisplacement pixels
    const int touchId = 0;
    QTest::touchEvent(m_view, m_device).press(touchId, touchPoint.toPoint());
    tryCompare([&](){ return parentItem->height(); }, hintDisplacement);


    QSignalSpy parentHeightChangedSpy(parentItem, SIGNAL(heightChanged()));

    drag(touchPoint, QPointF(0.0, -1.0) /*dragDirectionVector*/, 15 /*distance*/, 3 /*numSteps*/);

    // Give some time for animations to run, if any
    QTest::qWait(300);

    // parentItem height shouldn't have changed at all
    QVERIFY(parentHeightChangedSpy.isEmpty());
}

/*
    Set DragHandle.hintDisplacement & DragHandle.hintPersistencyDuration to a value bigger than zero.
    Then lay a finger on the DragHandle.
    The expected behavior is that it will move or strech its parent Showable
    by hintDisplacement pixels and remain at that position for DragHandle.hintPersistencyDuration ms when
    finger is removed.
 */
void tst_DragHandle::hintingAnimation_persistentHint()
{
    QFETCH(QString, handle);
    QFETCH(int, hintAnimationDuration);
    QFETCH(bool, tap);

    DirectionalDragArea *dragHandle = fetchAndSetupDragHandle(handle.toUtf8().data());
    QQuickItem *parentItem = dragHandle->parentItem();
    qreal hintDisplacement = 100.0;
    int hintPersistencyDuration = 200;

    // enable hinting animations and stretch mode
    m_view->rootObject()->setProperty("hintDisplacement", QVariant(hintDisplacement));
    m_view->rootObject()->setProperty("hintAnimationDuration", QVariant(hintAnimationDuration));
    m_view->rootObject()->setProperty("hintPersistencyDuration", QVariant(hintPersistencyDuration));
    m_view->rootObject()->setProperty("stretch", QVariant(true));

    switch (dragHandle->direction()) {
        case Direction::Upwards:
        case Direction::Downwards:
            QCOMPARE(parentItem->height(), 0.0);
            break;
        case Direction::Leftwards:
        default: // Direction::Rightwards:
            QCOMPARE(parentItem->width(), 0.0);
            break;
    }

    QPointF initialTouchPos = dragHandle->mapToScene(
        QPointF(dragHandle->width() / 2.0, dragHandle->height() / 2.0));
    QPointF touchPoint = initialTouchPos;

    // Pressing causes the Showable to be stretched by hintDisplacement pixels
    QTest::touchEvent(m_view, m_device).press(0, touchPoint.toPoint());
    if (tap) {
        QTest::touchEvent(m_view, m_device).release(0, touchPoint.toPoint());
    }

    switch (dragHandle->direction()) {
        case Direction::Upwards:
        case Direction::Downwards:
            tryCompare([&](){ return parentItem->height(); }, hintDisplacement);
            break;
        case Direction::Leftwards:
        default: // Direction::Rightwards:
            tryCompare([&](){ return parentItem->width(); }, hintDisplacement);
            break;
    }

    if (!tap) {
        QTest::touchEvent(m_view, m_device).release(0, touchPoint.toPoint());
    }

    // Releasing causes the Showable to shrink back to 0 pixels
    // after the hintPersistencyDuration interval.
    QTest::qWait(hintPersistencyDuration/2);
    switch (dragHandle->direction()) {
        case Direction::Upwards:
        case Direction::Downwards:
            QCOMPARE(parentItem->height(), hintDisplacement);
            tryCompare([&](){ return parentItem->height(); }, 0.0);
            break;
        case Direction::Leftwards:
        default: // Direction::Rightwards:
            QCOMPARE(parentItem->width(), hintDisplacement);
            tryCompare([&](){ return parentItem->width(); }, 0.0);
            break;
    }

    QCOMPARE(parentItem->property("shown").toBool(), false);
}

void tst_DragHandle::hintingAnimation_persistentHint_data()
{
    QTest::addColumn<QString>("handle");
    QTest::addColumn<int>("hintAnimationDuration");
    QTest::addColumn<bool>("tap");

    QTest::newRow("downwards_hold") << "downwardsDragHandle" << 150 << false;
    QTest::newRow("rightwards_hold")  << "rightwardsDragHandle" << 150 << false;
    QTest::newRow("downwards_tap") << "downwardsDragHandle" << 150 << true;
    QTest::newRow("rightwards_tap")  << "rightwardsDragHandle" << 150 << true;
    QTest::newRow("downwards_longAnimation_hold") << "downwardsDragHandle" << 500 << false;
    QTest::newRow("rightwards_longAnimation_hold")  << "rightwardsDragHandle" << 500 << false;
    QTest::newRow("downwards_longAnimation_tap") << "downwardsDragHandle" << 500 << true;
    QTest::newRow("rightwards_longAnimation_tap")  << "rightwardsDragHandle" << 500 << true;
}

/*
1 - tap on DragHandle
* DragHandle moves to hintDisplacement and stays there
2 - press on the DragHandle, drag it to more than hintDisplacement but less the half of the screen and release it.
* DragHandle moves back to hintDisplacement and stays there
3 - wait beyond persistencyDuration time
* DragHandle finally rolls back its parent to the original hidden position.
 */
void tst_DragHandle::hintingAnimation_releaseAfterPersistentHint()
{
    QFETCH(QString, handle);

    DirectionalDragArea *dragHandle = fetchAndSetupDragHandle(handle.toUtf8().data());
    QQuickItem *parentItem = dragHandle->parentItem();
    qreal hintDisplacement = 100.0;
    int hintPersistencyDuration = 200;

    // enable hinting animations and stretch mode
    m_view->rootObject()->setProperty("hintDisplacement", QVariant(hintDisplacement));
    m_view->rootObject()->setProperty("hintPersistencyDuration", QVariant(hintPersistencyDuration));
    m_view->rootObject()->setProperty("stretch", QVariant(true));

    QPointF initialTouchPos = dragHandle->mapToScene(
        QPointF(dragHandle->width() / 2.0, dragHandle->height() / 2.0));

    // 1 - tap on DragHandle
    QTest::touchEvent(m_view, m_device).press(0, initialTouchPos.toPoint());
    QTest::touchEvent(m_view, m_device).release(0, initialTouchPos.toPoint());

    switch (dragHandle->direction()) {
        case Direction::Upwards:
        case Direction::Downwards:
            tryCompare([&](){ return parentItem->height(); }, hintDisplacement);
            break;
        case Direction::Leftwards:
        default: // Direction::Rightwards:
            tryCompare([&](){ return parentItem->width(); }, hintDisplacement);
            break;
    }

    // 2 - press on the DragHandle, drag it to more than hintDisplacement but less the half of the screen and release it.
    QPointF hintTouchPos = dragHandle->mapToScene(
        QPointF(dragHandle->width() / 2.0, dragHandle->height() / 2.0));

    QPointF dragDirectionVector = calculateDirectionVector(dragHandle);
    QTest::touchEvent(m_view, m_device).press(0, hintTouchPos.toPoint());
    drag(hintTouchPos, dragDirectionVector, hintDisplacement * 1.2, 20);

    switch (dragHandle->direction()) {
        case Direction::Upwards:
        case Direction::Downwards:
            tryCompare([&](){ return parentItem->height() > hintDisplacement; }, true);
            break;
        case Direction::Leftwards:
        default: // Direction::Rightwards:
            tryCompare([&](){ return parentItem->width() > hintDisplacement; }, true);
            break;
    }

    QTest::touchEvent(m_view, m_device).release(0, hintTouchPos.toPoint());

    // 3 - wait beyond persistencyDuration time
    QTest::qWait(hintPersistencyDuration * 1.5);

    switch (dragHandle->direction()) {
        case Direction::Upwards:
        case Direction::Downwards:
            tryCompare([&](){ return parentItem->height(); }, 0.0);
            break;
        case Direction::Leftwards:
        default: // Direction::Rightwards:
        tryCompare([&](){ return parentItem->width(); }, 0.0);
            break;
    }
}

void tst_DragHandle::hintingAnimation_releaseAfterPersistentHint_data()
{
    QTest::addColumn<QString>("handle");

    QTest::newRow("downwards") << "downwardsDragHandle";
    QTest::newRow("rightwards")  << "rightwardsDragHandle";
}

/*
1 - tap on DragHandle
* DragHandle moves to hintDisplacement and stays there
2 - press on the DragHandle, drag it to less than hintDisplacement and release it.
* DragHandle rolls back its parent to the original hidden position.
 */
void tst_DragHandle::hintingAnimation_rollbackPersistentHint()
{
    QFETCH(QString, handle);

    DirectionalDragArea *dragHandle = fetchAndSetupDragHandle(handle.toUtf8().data());
    QQuickItem *parentItem = dragHandle->parentItem();
    qreal hintDisplacement = 100.0;
    int hintPersistencyDuration = -1; // infinite

    // enable hinting animations and stretch mode
    m_view->rootObject()->setProperty("hintDisplacement", QVariant(hintDisplacement));
    m_view->rootObject()->setProperty("hintPersistencyDuration", QVariant(hintPersistencyDuration));
    m_view->rootObject()->setProperty("stretch", QVariant(true));

    QPointF initialTouchPos = dragHandle->mapToScene(
        QPointF(dragHandle->width() / 2.0, dragHandle->height() / 2.0));
    QPointF touchPoint = initialTouchPos;

    // 1 - tap on DragHandle
    QTest::touchEvent(m_view, m_device).press(0, touchPoint.toPoint());
    QTest::touchEvent(m_view, m_device).release(0, touchPoint.toPoint());

    switch (dragHandle->direction()) {
        case Direction::Upwards:
        case Direction::Downwards:
            tryCompare([&](){ return parentItem->height(); }, hintDisplacement);
            break;
        case Direction::Leftwards:
        default: // Direction::Rightwards:
            tryCompare([&](){ return parentItem->width(); }, hintDisplacement);
            break;
    }

    // 2 - press on the DragHandle, drag it to less than hintDisplacement and release it.
    flickAndHold(dragHandle, -hintDisplacement/2);

    switch (dragHandle->direction()) {
        case Direction::Upwards:
        case Direction::Downwards:
            tryCompare([&](){ return parentItem->height(); }, 0.0);
            break;
        case Direction::Leftwards:
        default: // Direction::Rightwards:
        tryCompare([&](){ return parentItem->width(); }, 0.0);
            break;
    }
}

void tst_DragHandle::hintingAnimation_rollbackPersistentHint_data()
{
    QTest::addColumn<QString>("handle");

    QTest::newRow("downwards") << "downwardsDragHandle";
    QTest::newRow("rightwards")  << "rightwardsDragHandle";
}

/*
1 - tap on DragHandle
* DragHandle moves to hintDisplacement and stays there
2 - press on the DragHandle, drag it beyond half of the screen and release it.
* DragHandle calls show() on its parent, making it move all the way to its shown position.
 */
void tst_DragHandle::hintingAnimation_tapThenShowWithHandle()
{
    QFETCH(QString, handle);

    DirectionalDragArea *dragHandle = fetchAndSetupDragHandle(handle.toUtf8().data());
    QQuickItem *parentItem = dragHandle->parentItem();
    qreal hintDisplacement = 100.0;
    int hintPersistencyDuration = -1; // infinite

    // enable hinting animations and stretch mode
    m_view->rootObject()->setProperty("hintDisplacement", QVariant(hintDisplacement));
    m_view->rootObject()->setProperty("hintPersistencyDuration", QVariant(hintPersistencyDuration));

    QPointF initialTouchPos = dragHandle->mapToScene(
        QPointF(dragHandle->width() / 2.0, dragHandle->height() / 2.0));
    QPointF touchPoint = initialTouchPos;

    // 1 - tap on DragHandle
    QTest::touchEvent(m_view, m_device).press(0, touchPoint.toPoint());
    QTest::touchEvent(m_view, m_device).release(0, touchPoint.toPoint());

    switch (dragHandle->direction()) {
        case Direction::Upwards:
        case Direction::Downwards:
            tryCompare([&](){ return parentItem->y(); }, -parentItem->height() + hintDisplacement);
            break;
        case Direction::Leftwards:
        default: // Direction::Rightwards:
            tryCompare([&](){ return parentItem->x(); }, -parentItem->width() + hintDisplacement);
            break;
    }

    // 2 - press on the DragHandle, drag it beyond half of the screen and release it.
    qreal dragThreshold = fetchDragThreshold(dragHandle);
    flickAndHold(dragHandle, dragThreshold * 1.2);

    switch (dragHandle->direction()) {
        case Direction::Upwards:
        case Direction::Downwards:
            tryCompare([&](){ return parentItem->y(); }, 0);
            break;
        case Direction::Leftwards:
        default: // Direction::Rightwards:
        tryCompare([&](){ return parentItem->x(); }, 0);
            break;
    }
    QCOMPARE(parentItem->property("shown").toBool(), true);
}

void tst_DragHandle::hintingAnimation_tapThenShowWithHandle_data()
{
    QTest::addColumn<QString>("handle");

    QTest::newRow("downwards") << "downwardsDragHandle";
    QTest::newRow("rightwards")  << "rightwardsDragHandle";
}

/*
1 - tap on DragHandle
* DragHandle moves to hintDisplacement and stays there
2 - hide() the parent
* parent moves back to its original, hidden, position.
3 - tap on DragHandle once again
* DragHandle moves to hintDisplacement and stays there
 */
void tst_DragHandle::hintingAnimation_tapThenHideParent()
{
    QFETCH(QString, handle);

    DirectionalDragArea *dragHandle = fetchAndSetupDragHandle(handle.toUtf8().data());
    QQuickItem *parentItem = dragHandle->parentItem();
    qreal hintDisplacement = 100.0;
    int hintPersistencyDuration = -1; // infinite

    // enable hinting animations and stretch mode
    m_view->rootObject()->setProperty("hintDisplacement", QVariant(hintDisplacement));
    m_view->rootObject()->setProperty("hintPersistencyDuration", QVariant(hintPersistencyDuration));
    m_view->rootObject()->setProperty("stretch", QVariant(true));

    QPointF initialTouchPos = dragHandle->mapToScene(
        QPointF(dragHandle->width() / 2.0, dragHandle->height() / 2.0));
    QPointF touchPoint = initialTouchPos;

    // 1 - tap on DragHandle
    QTest::touchEvent(m_view, m_device).press(0, touchPoint.toPoint());
    QTest::touchEvent(m_view, m_device).release(0, touchPoint.toPoint());

    switch (dragHandle->direction()) {
        case Direction::Upwards:
        case Direction::Downwards:
            tryCompare([&](){ return parentItem->height(); }, hintDisplacement);
            break;
        case Direction::Leftwards:
        default: // Direction::Rightwards:
            tryCompare([&](){ return parentItem->width(); }, hintDisplacement);
            break;
    }

    // 2 - hide() the parent
    QMetaObject::invokeMethod(parentItem, "hide");
    switch (dragHandle->direction()) {
        case Direction::Upwards:
        case Direction::Downwards:
            tryCompare([&](){ return parentItem->height(); }, 0.0);
            break;
        case Direction::Leftwards:
        default: // Direction::Rightwards:
            tryCompare([&](){ return parentItem->width(); }, 0.0);
            break;
    }

    // 3 - tap on DragHandle once again
    QTest::touchEvent(m_view, m_device).press(0, touchPoint.toPoint());
    QTest::touchEvent(m_view, m_device).release(0, touchPoint.toPoint());

    switch (dragHandle->direction()) {
        case Direction::Upwards:
        case Direction::Downwards:
            tryCompare([&](){ return parentItem->height(); }, hintDisplacement);
            break;
        case Direction::Leftwards:
        default: // Direction::Rightwards:
            tryCompare([&](){ return parentItem->width(); }, hintDisplacement);
            break;
    }
}

void tst_DragHandle::hintingAnimation_tapThenHideParent_data()
{
    QTest::addColumn<QString>("handle");

    QTest::newRow("downwards") << "downwardsDragHandle";
    QTest::newRow("rightwards")  << "rightwardsDragHandle";
}

/*
1 - tap on DragHandle
* DragHandle moves to hintDisplacement and stays there
2 - show() the parent
* parent moves all the way to its shown position
3 - wait beyond persistencyDuration time
* parent stays put
 */
void tst_DragHandle::hintingAnimation_tapThenShowParent()
{
    QFETCH(QString, handle);

    DirectionalDragArea *dragHandle = fetchAndSetupDragHandle(handle.toUtf8().data());
    QQuickItem *parentItem = dragHandle->parentItem();
    qreal hintDisplacement = 100.0;
    int hintPersistencyDuration = 200;

    // enable hinting animations and stretch mode
    m_view->rootObject()->setProperty("hintDisplacement", QVariant(hintDisplacement));
    m_view->rootObject()->setProperty("hintPersistencyDuration", QVariant(hintPersistencyDuration));

    QPointF initialTouchPos = dragHandle->mapToScene(
        QPointF(dragHandle->width() / 2.0, dragHandle->height() / 2.0));
    QPointF touchPoint = initialTouchPos;

    // 1 - tap on DragHandle
    QTest::touchEvent(m_view, m_device).press(0, touchPoint.toPoint());
    QTest::touchEvent(m_view, m_device).release(0, touchPoint.toPoint());

    switch (dragHandle->direction()) {
        case Direction::Upwards:
        case Direction::Downwards:
            tryCompare([&](){ return parentItem->y(); }, -parentItem->height() + hintDisplacement);
            break;
        case Direction::Leftwards:
        default: // Direction::Rightwards:
            tryCompare([&](){ return parentItem->x(); }, -parentItem->width() + hintDisplacement);
            break;
    }

    // 2 - show() the parent
    QMetaObject::invokeMethod(parentItem, "show");
    switch (dragHandle->direction()) {
        case Direction::Upwards:
        case Direction::Downwards:
            tryCompare([&](){ return parentItem->y(); }, 0);
            break;
        case Direction::Leftwards:
        default: // Direction::Rightwards:
            tryCompare([&](){ return parentItem->x(); }, 0);
            break;
    }
    QCOMPARE(parentItem->property("shown").toBool(), true);

    // 3 - wait beyond persistencyDuration time
    QTest::qWait(hintPersistencyDuration * 1.5);

    switch (dragHandle->direction()) {
        case Direction::Upwards:
        case Direction::Downwards:
            tryCompare([&](){ return parentItem->y(); }, 0);
            break;
        case Direction::Leftwards:
        default: // Direction::Rightwards:
            tryCompare([&](){ return parentItem->x(); }, 0);
            break;
    }
    QCOMPARE(parentItem->property("shown").toBool(), true);
}

void tst_DragHandle::hintingAnimation_tapThenShowParent_data()
{
    QTest::addColumn<QString>("handle");

    QTest::newRow("downwards") << "downwardsDragHandle";
    QTest::newRow("rightwards")  << "rightwardsDragHandle";
}

/*
1 - tap on DragHandle
* DragHandle moves to hintDisplacement and stays there
2 - set infinite hintPersistencyDuration and wait beyond old hintPersistencyDuration time
* parent stays put
3 - set finite hintPersistencyDuration and wait for less than hintPersistencyDuration time
* parent stays put
4 - wait beyond hintPersistencyDuration time
* DragHandle rolls back its parent to the original hidden position.
 */
void tst_DragHandle::hintingAnimation_changingPersistencyDuration()
{
    QFETCH(QString, handle);

    DirectionalDragArea *dragHandle = fetchAndSetupDragHandle(handle.toUtf8().data());
    QQuickItem *parentItem = dragHandle->parentItem();
    qreal hintDisplacement = 100.0;
    int hintPersistencyDuration = 200;

    // enable hinting animations and stretch mode
    m_view->rootObject()->setProperty("hintDisplacement", QVariant(hintDisplacement));
    m_view->rootObject()->setProperty("hintPersistencyDuration", QVariant(hintPersistencyDuration));
    m_view->rootObject()->setProperty("stretch", QVariant(true));

    QPointF initialTouchPos = dragHandle->mapToScene(
        QPointF(dragHandle->width() / 2.0, dragHandle->height() / 2.0));
    QPointF touchPoint = initialTouchPos;

    // 1 - tap on DragHandle
    QTest::touchEvent(m_view, m_device).press(0, touchPoint.toPoint());
    QTest::touchEvent(m_view, m_device).release(0, touchPoint.toPoint());

    switch (dragHandle->direction()) {
        case Direction::Upwards:
        case Direction::Downwards:
            tryCompare([&](){ return parentItem->height(); }, hintDisplacement);
            QTest::qWait(hintPersistencyDuration / 2);
            tryCompare([&](){ return parentItem->height(); }, hintDisplacement);
            break;
        case Direction::Leftwards:
        default: // Direction::Rightwards:
            tryCompare([&](){ return parentItem->width(); }, hintDisplacement);
            QTest::qWait(hintPersistencyDuration / 2);
            tryCompare([&](){ return parentItem->width(); }, hintDisplacement);
            break;
    }

    // 2 - set infinite hintPersistencyDuration
    m_view->rootObject()->setProperty("hintPersistencyDuration", QVariant(-1));
    QTest::qWait(hintPersistencyDuration * 1.5);

    switch (dragHandle->direction()) {
        case Direction::Upwards:
        case Direction::Downwards:
            tryCompare([&](){ return parentItem->height(); }, hintDisplacement);
            break;
        case Direction::Leftwards:
        default: // Direction::Rightwards:
            QTest::qWait(hintPersistencyDuration / 2);
            tryCompare([&](){ return parentItem->width(); }, hintDisplacement);
            break;
    }

    // 2 - set infinite hintPersistencyDuration
    m_view->rootObject()->setProperty("hintPersistencyDuration", QVariant(hintPersistencyDuration));
    QTest::qWait(hintPersistencyDuration / 2);

    switch (dragHandle->direction()) {
        case Direction::Upwards:
        case Direction::Downwards:
            tryCompare([&](){ return parentItem->height(); }, hintDisplacement);
            QTest::qWait(hintPersistencyDuration);
            tryCompare([&](){ return parentItem->height(); }, 0.0);
            break;
        case Direction::Leftwards:
        default: // Direction::Rightwards:
            tryCompare([&](){ return parentItem->width(); }, hintDisplacement);
            QTest::qWait(hintPersistencyDuration);
            tryCompare([&](){ return parentItem->width(); }, 0.0);
            break;
    }
}

void tst_DragHandle::hintingAnimation_changingPersistencyDuration_data()
{
    QTest::addColumn<QString>("handle");

    QTest::newRow("downwards") << "downwardsDragHandle";
    QTest::newRow("rightwards")  << "rightwardsDragHandle";
}

/*
1 - tap on DragHandle
* DragHandle moves parent hintDisplacement position
2 - wait 0.5*persistencyDuration time
* parent stays put
3.1-3.x - call resetHintRollbackTimer() and wait 0.5*persistencyDuration time
* parent stays put
* DragHandle rolls back its parent to the original hidden position.
 */
void tst_DragHandle::hintingAnimation_resetHintRollbackTimer()
{
    QFETCH(QString, handle);

    DirectionalDragArea *dragHandle = fetchAndSetupDragHandle(handle.toUtf8().data());
    QQuickItem *parentItem = dragHandle->parentItem();
    qreal hintDisplacement = 100.0;
    int hintPersistencyDuration = 200;

    // enable hinting animations and stretch mode
    m_view->rootObject()->setProperty("hintDisplacement", QVariant(hintDisplacement));
    m_view->rootObject()->setProperty("hintPersistencyDuration", QVariant(hintPersistencyDuration));
    m_view->rootObject()->setProperty("stretch", QVariant(true));

    QPointF initialTouchPos = dragHandle->mapToScene(
        QPointF(dragHandle->width() / 2.0, dragHandle->height() / 2.0));
    QPointF touchPoint = initialTouchPos;

    // 1 - tap on DragHandle
    QTest::touchEvent(m_view, m_device).press(0, touchPoint.toPoint());
    QTest::touchEvent(m_view, m_device).release(0, touchPoint.toPoint());

    switch (dragHandle->direction()) {
        case Direction::Upwards:
        case Direction::Downwards:
            tryCompare([&](){ return parentItem->height(); }, hintDisplacement);
            QTest::qWait(hintPersistencyDuration / 2);
            tryCompare([&](){ return parentItem->height(); }, hintDisplacement);
            break;
        case Direction::Leftwards:
        default: // Direction::Rightwards:
            tryCompare([&](){ return parentItem->width(); }, hintDisplacement);
            QTest::qWait(hintPersistencyDuration / 2);
            tryCompare([&](){ return parentItem->width(); }, hintDisplacement);
            break;
    }

    for (int i = 0; i < 3; i ++)
    {
        QMetaObject::invokeMethod(dragHandle, "resetHintRollbackTimer");
        QTest::qWait(hintPersistencyDuration / 2);

        switch (dragHandle->direction()) {
            case Direction::Upwards:
            case Direction::Downwards:
                tryCompare([&](){ return parentItem->height(); }, hintDisplacement);
                break;
            case Direction::Leftwards:
            default: // Direction::Rightwards:
                tryCompare([&](){ return parentItem->width(); }, hintDisplacement);
                break;
        }
    }

    QTest::qWait(hintPersistencyDuration);

    switch (dragHandle->direction()) {
        case Direction::Upwards:
        case Direction::Downwards:
            tryCompare([&](){ return parentItem->height(); }, 0.0);
            break;
        case Direction::Leftwards:
        default: // Direction::Rightwards:
            tryCompare([&](){ return parentItem->width(); }, 0.0);
            break;
    }
}

void tst_DragHandle::hintingAnimation_resetHintRollbackTimer_data()
{
    QTest::addColumn<QString>("handle");

    QTest::newRow("downwards") << "downwardsDragHandle";
    QTest::newRow("rightwards")  << "rightwardsDragHandle";
}

/*
1 - press on DragHandle
* DragHandle moves parent hintDisplacement position
2 - drag the DragHandle half-way to completion.
* DragHandle moves parent to drag position accordingly
3 - call resetHintRollbackTimer() and wait beyond persistencyDuration time
* parent didn't move, stayed at drag position.
 */
void tst_DragHandle::hintingAnimation_resetHintRollbackTimerDuringDrag()
{
    QFETCH(QString, handle);

    DirectionalDragArea *dragHandle = fetchAndSetupDragHandle(handle.toUtf8().data());
    QQuickItem *parentItem = dragHandle->parentItem();
    qreal hintDisplacement = 100.0;
    int hintPersistencyDuration = 200;

    // enable hinting animations and stretch mode
    m_view->rootObject()->setProperty("hintDisplacement", QVariant(hintDisplacement));
    m_view->rootObject()->setProperty("hintPersistencyDuration", QVariant(hintPersistencyDuration));
    m_view->rootObject()->setProperty("stretch", QVariant(true));

    QPointF initialTouchPos = dragHandle->mapToScene(
        QPointF(dragHandle->width() / 2.0, dragHandle->height() / 2.0));
    QPointF touchPoint = initialTouchPos;

    // 1 - tap on DragHandle
    QTest::touchEvent(m_view, m_device).press(0, touchPoint.toPoint());

    switch (dragHandle->direction()) {
        case Direction::Upwards:
        case Direction::Downwards:
            tryCompare([&](){ return parentItem->height(); }, hintDisplacement);
            break;
        case Direction::Leftwards:
        default: // Direction::Rightwards:
            tryCompare([&](){ return parentItem->width(); }, hintDisplacement);
            break;
    }

    QPointF dragDirectionVector = calculateDirectionVector(dragHandle);
    qreal dragThreshold = fetchDragThreshold(dragHandle);
    drag(touchPoint, dragDirectionVector, dragThreshold, 20);

    switch (dragHandle->direction()) {
        case Direction::Upwards:
        case Direction::Downwards:
            tryCompare([&](){ return parentItem->height() > hintDisplacement; }, true);
            break;
        case Direction::Leftwards:
        default: // Direction::Rightwards:
            tryCompare([&](){ return parentItem->width() > hintDisplacement; }, true);
            break;
    }

    QMetaObject::invokeMethod(dragHandle, "resetHintRollbackTimer");
    QTest::qWait(hintPersistencyDuration * 1.5);

    tryCompare([&](){ return parentItem->height() > hintDisplacement; }, true);

    QTest::touchEvent(m_view, m_device).release(0, touchPoint.toPoint());
}

void tst_DragHandle::hintingAnimation_resetHintRollbackTimerDuringDrag_data()
{
    QTest::addColumn<QString>("handle");

    QTest::newRow("downwards") << "downwardsDragHandle";
    QTest::newRow("rightwards")  << "rightwardsDragHandle";
}

QTEST_MAIN(tst_DragHandle)

#include "tst_DragHandle.moc"
