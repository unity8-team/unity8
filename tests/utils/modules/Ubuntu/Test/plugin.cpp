/*
 * Copyright (C) 2012, 2013 Canonical, Ltd.
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


#include "plugin.h"
#include "testutil.h"
#include "TouchEventSequenceWrapper.h"

#include <qqml.h>
#include <QQmlEngine>

static QObject *s_testRootObject = nullptr;
static QObject *testRootObject(QQmlEngine *engine, QJSEngine *jsEngine)
{
    Q_UNUSED(jsEngine);
    if (!s_testRootObject) {
        s_testRootObject = new QObject(engine);
    }
    return s_testRootObject;
}

static QObject *testutil_provider(QQmlEngine* /* engine */, QJSEngine* /* scriptEngine */)
{
    return new TestUtil();
}

void UbuntuTestPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(QLatin1String(uri) == QLatin1String("Ubuntu.Test"));
    // @uri Ubuntu.Test
    qmlRegisterSingletonType<TestUtil>(uri, 0, 1, "Util", testutil_provider);
    qmlRegisterUncreatableType<TouchEventSequenceWrapper>(uri, 0, 1, "TouchEventSequence",
            "You cannot directly create a TouchEventSequence object.");
}

void UbuntuTestPlugin::initializeEngine(QQmlEngine *engine, const char *uri)
{
    Q_UNUSED(uri);
    Q_UNUSED(engine);
    qmlRegisterSingletonType<QObject>("Qt.test.qtestroot", 1, 0, "QTestRootObject", testRootObject);
}