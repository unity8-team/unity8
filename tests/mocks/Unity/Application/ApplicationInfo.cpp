/*
 * Copyright (C) 2013-2016 Canonical, Ltd.
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

#include "ApplicationInfo.h"
#include "ApplicationInstance.h"
#include "MirSurface.h"

#include <paths.h>

#include <QGuiApplication>
#include <QQuickItem>
#include <QQuickView>
#include <QQmlComponent>

#define APPLICATION_DEBUG 1

#if APPLICATION_DEBUG
#define DEBUG_MSG(params) qDebug().nospace() << "Application["<<appId()<<"]::" << __func__  << " " << params
#else
#define DEBUG_MSG(params) ((void)0)
#endif

#define WARNING_MSG(params) qWarning().nospace() << "Application["<<appId()<<"]::" << __func__  << " " << params

ApplicationInfo::ApplicationInfo(const QString &appId, QObject *parent)
    : ApplicationInfoInterface(appId, parent)
    , m_appId(appId)
    , m_applicationInstances(new ApplicationInstanceListModel)
{
}

ApplicationInfo::ApplicationInfo(QObject *parent)
    : ApplicationInfo(QString(), parent)
{
}

ApplicationInfo::~ApplicationInfo()
{
}

void ApplicationInfo::setIconId(const QString &iconId)
{
    setIcon(QString("../../tests/graphics/applicationIcons/%2@18.png")
            .arg(iconId));
}

void ApplicationInfo::setScreenshotId(const QString &screenshotId)
{
    QString screenshotFileName;

    if (screenshotId.endsWith(".svg")) {
        screenshotFileName = QString("qrc:///Unity/Application/screenshots/%2")
            .arg(screenshotId);
    } else {
        screenshotFileName = QString("qrc:///Unity/Application/screenshots/%2@12.png")
            .arg(screenshotId);
    }

    if (screenshotFileName != m_screenshotFileName) {
        m_screenshotFileName = screenshotFileName;
    }
}

void ApplicationInfo::setName(const QString &value)
{
    if (value != m_name) {
        m_name = value;
        Q_EMIT nameChanged(value);
    }
}

void ApplicationInfo::setIcon(const QUrl &value)
{
    if (value != m_icon) {
        m_icon = value;
        Q_EMIT iconChanged(value);
    }
}


void ApplicationInfo::close()
{
    DEBUG_MSG("");

    for (int i = 0; i < m_applicationInstances->count(); ++i) {
        auto appInstance = static_cast<ApplicationInstance*>(m_applicationInstances->get(i));
        appInstance->close();
    }
}

Qt::ScreenOrientations ApplicationInfo::supportedOrientations() const
{
    return m_supportedOrientations;
}

void ApplicationInfo::setSupportedOrientations(Qt::ScreenOrientations orientations)
{
    m_supportedOrientations = orientations;
}

bool ApplicationInfo::rotatesWindowContents() const
{
    return m_rotatesWindowContents;
}

void ApplicationInfo::setRotatesWindowContents(bool value)
{
    m_rotatesWindowContents = value;
}

bool ApplicationInfo::isTouchApp() const
{
    return m_isTouchApp;
}

void ApplicationInfo::setIsTouchApp(bool isTouchApp)
{
    m_isTouchApp = isTouchApp;
}

bool ApplicationInfo::exemptFromLifecycle() const
{
    return m_exemptFromLifecycle;
}

void ApplicationInfo::setExemptFromLifecycle(bool exemptFromLifecycle)
{
    if (m_exemptFromLifecycle != exemptFromLifecycle)
    {
        m_exemptFromLifecycle = exemptFromLifecycle;
        Q_EMIT exemptFromLifecycleChanged(m_exemptFromLifecycle);
    }
}

QSize ApplicationInfo::initialSurfaceSize() const
{
    return m_initialSurfaceSize;
}

void ApplicationInfo::setInitialSurfaceSize(const QSize &size)
{
    if (size != m_initialSurfaceSize) {
        m_initialSurfaceSize = size;
        Q_EMIT initialSurfaceSizeChanged(m_initialSurfaceSize);
    }
}

void ApplicationInfo::setShellChrome(Mir::ShellChrome shellChrome)
{
    m_shellChrome = shellChrome;
    for (int i = 0; i < m_applicationInstances->count(); ++i) {
        auto surfaceList = m_applicationInstances->get(i)->surfaceList();
        if (surfaceList->rowCount() > 0) {
            static_cast<MirSurface*>(surfaceList->get(0))->setShellChrome(shellChrome);
        }
    }
}

bool ApplicationInfo::focused() const
{
    bool someInstanceHasFocus = false; // to be proven wrong
    for (int i = 0; i < m_applicationInstances->count() && !someInstanceHasFocus; ++i) {
        someInstanceHasFocus = m_applicationInstances->get(i)->focused();
    }
    return someInstanceHasFocus;
}

void ApplicationInfo::setFocused(bool value)
{
    if (focused() == value) {
        return;
    }

    if (m_applicationInstances->count() > 0) {
        static_cast<ApplicationInstance*>(m_applicationInstances->get(0))->setFocused(value);
    }
}

void ApplicationInfo::requestFocus()
{
    if (m_applicationInstances->count() > 0) {
        static_cast<ApplicationInstance*>(m_applicationInstances->get(0))->requestFocus();
    }
}

void ApplicationInfo::start()
{
    DEBUG_MSG("");
    if (m_applicationInstances->count() == 0) {
        createInstance();
    }
}

void ApplicationInfo::createInstance()
{
    DEBUG_MSG("");
    auto appInstance = new ApplicationInstance(this);
    appInstance->setFullscreen(m_fullscreen);

    connect(appInstance, &ApplicationInstance::closed, this, [this, appInstance]() {
        m_applicationInstances->remove(appInstance);
        disconnect(appInstance, 0, this, 0);
        appInstance->deleteLater();
        if (m_applicationInstances->count() == 0) {
            Q_EMIT closed();
        }
    });

    connect(appInstance->surfaceList(), &MirSurfaceListInterface::countChanged, this, [this]() {
        Q_EMIT surfaceCountChanged(surfaceCount());
    });

    connect(appInstance, &ApplicationInstance::focusRequested,
            this, &ApplicationInfo::focusRequested);

    m_applicationInstances->append(appInstance);
}

int ApplicationInfo::surfaceCount() const
{
    int result = 0;
    for (int i = 0; i < m_applicationInstances->count(); ++i) {
        result += m_applicationInstances->get(i)->surfaceList()->count();
    }
    return result;
}
