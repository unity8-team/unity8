/*
 * Copyright: 2013 Canonical, Ltd
 *
 * This file is part of reminders-app
 *
 * reminders-app is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * reminders-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Michael Zanetti <michael.zanetti@canonical.com>
 */

#include <QtGui/QGuiApplication>
#include <QtQuick/QQuickView>
#include <QtQml/QtQml>

#include <QDebug>

/*
 * This is just a minimalistic main to fire up our own qml scene which has the
 * import path for the plugin preconfigured. This is just used for easier
 * development and while we can ship this, we could also run the app ourselves
 * with:
 * qmlscene -I /path/to/plugin/ reminders-app.qml
 */

int main(int argc, char *argv[])
{

    // Do the same as qmlscene does
    QGuiApplication a(argc, argv);
    QQuickView view;
    view.setResizeMode(QQuickView::SizeRootObjectToView);

    // Additionally add the -I ../plugin to load the plugin
    QStringList importPathList = view.engine()->importPathList();
    importPathList.append(QDir::currentPath() + "/../plugin/");
    view.engine()->setImportPathList(importPathList);

    // and directly load the qml file
    view.setSource(QUrl::fromLocalFile("qml/reminders-app.qml"));

    view.show();

    return a.exec();
}
