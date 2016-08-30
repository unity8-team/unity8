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

#ifndef APPLICATION_H
#define APPLICATION_H

#include <QObject>

// unity-api
#include <unity/shell/application/ApplicationInfoInterface.h>
#include <unity/shell/application/Mir.h>

#include "ApplicationInstanceListModel.h"

using namespace unity::shell::application;

class ApplicationInfo : public ApplicationInfoInterface {
    Q_OBJECT


    // Only exists in this fake implementation
    Q_PROPERTY(QString screenshot READ screenshot CONSTANT)
public:
    ApplicationInfo(QObject *parent = nullptr);
    ApplicationInfo(const QString &appId, QObject *parent = nullptr);
    ~ApplicationInfo();

    void setIconId(const QString &iconId);
    void setScreenshotId(const QString &screenshotId);

    void setAppId(const QString &value) { m_appId = value; }
    QString appId() const override { return m_appId; }

    void setName(const QString &value);
    QString name() const override { return m_name; }

    QString comment() const override { return QString(); }

    QUrl icon() const override { return m_icon; }

    bool focused() const override;

    QString splashTitle() const override { return QString(); }
    QUrl splashImage() const override { return QUrl(); }
    bool splashShowHeader() const override { return false; }
    QColor splashColor() const override { return QColor(0,0,0,0); }
    QColor splashColorHeader() const override { return QColor(0,0,0,0); }
    QColor splashColorFooter() const override { return QColor(0,0,0,0); }

    QString screenshot() const { return m_screenshotFileName; }


    Qt::ScreenOrientations supportedOrientations() const override;
    void setSupportedOrientations(Qt::ScreenOrientations orientations);

    bool rotatesWindowContents() const override;
    void setRotatesWindowContents(bool value);

    bool isTouchApp() const override;
    void setIsTouchApp(bool isTouchApp); // only in mock

    bool exemptFromLifecycle() const override;
    void setExemptFromLifecycle(bool) override;

    QSize initialSurfaceSize() const override;
    void setInitialSurfaceSize(const QSize &size) override;

    ApplicationInstanceListInterface* instanceList() const override { return m_applicationInstances; }

    Q_INVOKABLE void setShellChrome(Mir::ShellChrome shellChrome);

    int surfaceCount() const override;

    void setFocused(bool value);

    //////
    // internal mock stuff
    void start();
    void close();
    void requestFocus();
    void setFullscreen(bool value) { m_fullscreen = value; }
    Mir::ShellChrome shellChrome() const { return m_shellChrome; }

public Q_SLOTS:
    Q_INVOKABLE void createInstance();

Q_SIGNALS:
    void closed();

private:
    void setIcon(const QUrl &value);

    QString m_screenshotFileName;

    QString m_appId;
    QString m_name;
    QUrl m_icon;
    Qt::ScreenOrientations m_supportedOrientations{Qt::PortraitOrientation |
            Qt::LandscapeOrientation |
            Qt::InvertedPortraitOrientation |
            Qt::InvertedLandscapeOrientation};
    bool m_rotatesWindowContents{false};
    bool m_isTouchApp{true};
    bool m_exemptFromLifecycle{false};
    QSize m_initialSurfaceSize;
    Mir::ShellChrome m_shellChrome{Mir::NormalChrome};
    bool m_fullscreen{false};

    ApplicationInstanceListModel *m_applicationInstances;
};

Q_DECLARE_METATYPE(ApplicationInfo*)

#endif  // APPLICATION_H
