/*
 * Copyright 2016 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#include "consolelog.h"

#include <unistd.h>
#include <stdio.h>
#include <thread>
#include <iostream>
#include <sys/ioctl.h>

int secure_dup(int src)
{
    int ret = -1;
    bool fd_blocked = false;
    do
    {
         ret = dup(src);
         fd_blocked = (errno == EINTR ||  errno == EBUSY);
         if (fd_blocked)
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
    while (ret < 0);
    return ret;
}
void secure_pipe(int * pipes)
{
    int ret = -1;
    bool fd_blocked = false;
    do
    {
        ret = pipe(pipes) == -1;
        fd_blocked = (errno == EINTR ||  errno == EBUSY);
        if (fd_blocked)
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
    while (ret < 0);
}
void secure_dup2(int src, int dest)
{
    int ret = -1;
    bool fd_blocked = false;
    do
    {
         ret = dup2(src,dest);
         fd_blocked = (errno == EINTR ||  errno == EBUSY);
         if (fd_blocked)
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
    while (ret < 0);
}

void secure_close(int & fd)
{
    int ret = -1;
    bool fd_blocked = false;
    do
    {
         ret = close(fd);
         fd_blocked = (errno == EINTR);
         if (fd_blocked)
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
    while (ret < 0);
    fd = -1;
}

LogRedirector::LogRedirector()
    : m_ref(0)
    , m_stop(false)
{
    setObjectName("ConsoleLog");

    // make stdout & stderr streams unbuffered
    // so that we don't need to flush the streams
    // before capture and after capture
    // (fflush can cause a deadlock if the stream is currently being used)
    setvbuf(stdout,NULL,_IONBF,0);
    setvbuf(stderr,NULL,_IONBF,0);
}

void LogRedirector::run()
{
    secure_pipe(m_pipe);
    int oldStdOut = secure_dup(fileno(stdout));
    int oldStdErr = secure_dup(fileno(stderr));

    secure_dup2(m_pipe[WRITE], fileno(stdout));
    secure_dup2(m_pipe[WRITE], fileno(stderr));

    while(true) {
        {
            QMutexLocker lock(&m_mutex);
            if (m_stop) break;
        }
        checkLog();
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }

    secure_dup2(oldStdOut, fileno(stdout));
    secure_dup2(oldStdErr, fileno(stderr));

    secure_close(oldStdOut);
    secure_close(oldStdErr);
    secure_close(m_pipe[READ]);
}


void LogRedirector::checkLog()
{
    // dont allow a start/stop stop while in checkLog
    std::string captured;

    // Do not allow read to block with no data.
    // This would cause thread to block until new data arrives.
    int count = 0;
    ioctl(m_pipe[READ], FIONREAD, &count);
    if (count <= 0) return;

    std::string buf;
    const int bufSize = 1024;
    buf.resize(bufSize);
    int bytesRead = 0;
    bytesRead = read(m_pipe[READ], &(*buf.begin()), bufSize);
    while(bytesRead == bufSize)
    {
        captured += buf;
        bytesRead = 0;
        bytesRead = read(m_pipe[READ], &(*buf.begin()), bufSize);
    }
    if (bytesRead > 0)
    {
        buf.resize(bytesRead);
        captured += buf;
    }

    if (!captured.empty()) {
        Q_EMIT log(QString::fromStdString(captured));
    }
}

LogRedirector *LogRedirector::instance()
{
    static LogRedirector* log = nullptr;
    if (!log) {
        log = new LogRedirector();
    }
    return log;
}

void LogRedirector::add(ConsoleLog* logger)
{
    QMutexLocker lock(&m_mutex);
    connect(this, &LogRedirector::log, logger, &ConsoleLog::logged, Qt::UniqueConnection);

    m_ref++;
    if (!LogRedirector::instance()->isRunning()) {
        m_stop = false;
        LogRedirector::instance()->start();
    }
}

void LogRedirector::remove(ConsoleLog* logger)
{
    QMutexLocker lock(&m_mutex);
    disconnect(this, &LogRedirector::log, logger, &ConsoleLog::logged);

    m_ref = qMax(m_ref-1, 0);
    if (m_ref == 0 && LogRedirector::instance()->isRunning()) {
        m_stop = true;
        lock.unlock();
        LogRedirector::instance()->wait();
    }
}

ConsoleLog::ConsoleLog(QObject *parent)
    : QObject(parent)
    , m_enabled(false)
    , m_maxLines(60)
{
    auto updateEnabled = [this]() {
        if (m_enabled) {
            LogRedirector::instance()->add(this);
        } else {
            LogRedirector::instance()->remove(this);
        }
    };
    connect(this, &ConsoleLog::enabledChanged, this, updateEnabled);
}

ConsoleLog::~ConsoleLog()
{
    if (m_enabled) {
        LogRedirector::instance()->remove(this);
    }
}

void ConsoleLog::setEnabled(bool enabled)
{
    if (m_enabled == enabled) {
        return;
    }

    m_enabled = enabled;
    Q_EMIT enabledChanged();
}

QString ConsoleLog::out() const
{
    return m_out.join("\n");
}

void ConsoleLog::setMaxLines(int maxLines)
{
    if (m_maxLines == maxLines) {
        return;
    }

    m_maxLines = maxLines;
    while (m_out.count() > m_maxLines) {
        m_out.removeLast();
    }
    Q_EMIT outChanged();
    Q_EMIT maxLinesChanged();
}

void ConsoleLog::logged(QString captured)
{
    QStringList li = captured.split("\n", QString::SkipEmptyParts);
    li << m_out;
    m_out = li;
    while (m_out.count() > m_maxLines) {
        m_out.removeLast();
    }
    Q_EMIT outChanged();
}
