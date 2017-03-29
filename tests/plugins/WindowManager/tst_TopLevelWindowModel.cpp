/*
 * Copyright (C) 2017 Canonical, Ltd.
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

#include <QtTest/QtTest>

// WindowManager plugin
#include <TopLevelWindowModel.h>
#include <Window.h>

#include "UnityApplicationMocks.h"

class tst_TopLevelWindowModel : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void init(); // called right before each and every test function is executed
    void cleanup(); // called right after each and every test function is executed

    void singleSurfaceStartsHidden();
    void secondSurfaceIsHidden();

private:
    SurfaceManager *surfaceManager{nullptr};
    ApplicationInstanceList *applicationInstanceList{nullptr};
    TopLevelWindowModel *topLevelWindowModel{nullptr};
};

void tst_TopLevelWindowModel::init()
{
    surfaceManager = new SurfaceManager;

    applicationInstanceList = new ApplicationInstanceList;

    topLevelWindowModel = new TopLevelWindowModel;
    topLevelWindowModel->setSurfaceManager(surfaceManager);
    topLevelWindowModel->setApplicationInstancesModel(applicationInstanceList);
}

void tst_TopLevelWindowModel::cleanup()
{
    delete topLevelWindowModel;
    topLevelWindowModel = nullptr;

    delete applicationInstanceList;
    applicationInstanceList = nullptr;

    delete surfaceManager;
    surfaceManager = nullptr;
}

void tst_TopLevelWindowModel::singleSurfaceStartsHidden()
{
    QCOMPARE(topLevelWindowModel->rowCount(), 0);

    auto application = new Application(QString("hello-world"));
    auto applicationInstance = new ApplicationInstance(application);

    applicationInstanceList->add(applicationInstance);

    QCOMPARE(topLevelWindowModel->rowCount(), 1);
    QCOMPARE((void*)topLevelWindowModel->windowAt(0)->surface(), (void*)nullptr);

    auto surface = new MirSurface(applicationInstance);
    surface->m_state = Mir::HiddenState;
    applicationInstance->m_surfaceList.addSurface(surface);
    Q_EMIT surfaceManager->surfaceCreated(surface);

    QCOMPARE(topLevelWindowModel->rowCount(), 1);
    // not showing the surface as it's still hidden
    QCOMPARE((void*)topLevelWindowModel->windowAt(0)->surface(), (void*)nullptr);

    surface->requestState(Mir::RestoredState);

    QCOMPARE(topLevelWindowModel->rowCount(), 1);
    // Now that the surface is no longer hidden, TopLevelWindowModel should expose it.
    QCOMPARE((void*)topLevelWindowModel->windowAt(0)->surface(), (void*)surface);

    // cleanup
    delete surface;
    delete applicationInstance;
    delete application;
}

void tst_TopLevelWindowModel::secondSurfaceIsHidden()
{
    QCOMPARE(topLevelWindowModel->rowCount(), 0);

    auto application = new Application(QString("hello-world"));
    auto applicationInstance = new ApplicationInstance(application);
    applicationInstanceList->add(applicationInstance);

    QCOMPARE(topLevelWindowModel->rowCount(), 1);
    QCOMPARE((void*)topLevelWindowModel->windowAt(0)->surface(), (void*)nullptr);

    auto firstSurface = new MirSurface(applicationInstance);
    applicationInstance->m_surfaceList.addSurface(firstSurface);
    Q_EMIT surfaceManager->surfaceCreated(firstSurface);

    QCOMPARE(topLevelWindowModel->rowCount(), 1);
    QCOMPARE((void*)topLevelWindowModel->windowAt(0)->surface(), (void*)firstSurface);

    auto secondSurface = new MirSurface(applicationInstance);
    secondSurface->m_state = Mir::HiddenState;
    applicationInstance->m_surfaceList.addSurface(secondSurface);
    Q_EMIT surfaceManager->surfaceCreated(secondSurface);

    // still only the first surface is exposed by TopLevelWindowModel
    QCOMPARE(topLevelWindowModel->rowCount(), 1);
    QCOMPARE((void*)topLevelWindowModel->windowAt(0)->surface(), (void*)firstSurface);

    secondSurface->requestState(Mir::RestoredState);

    // now the second surface finally shows up
    QCOMPARE(topLevelWindowModel->rowCount(), 2);
    QCOMPARE((void*)topLevelWindowModel->windowAt(0)->surface(), (void*)secondSurface);
    QCOMPARE((void*)topLevelWindowModel->windowAt(1)->surface(), (void*)firstSurface);

    secondSurface->requestState(Mir::HiddenState);

    // and it's gone again
    QCOMPARE(topLevelWindowModel->rowCount(), 1);
    QCOMPARE((void*)topLevelWindowModel->windowAt(0)->surface(), (void*)firstSurface);

    // cleanup
    delete firstSurface;
    delete secondSurface;
    delete applicationInstance;
    delete application;
}

QTEST_MAIN(tst_TopLevelWindowModel)

#include "tst_TopLevelWindowModel.moc"
