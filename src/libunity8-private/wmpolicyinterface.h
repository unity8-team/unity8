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

#ifndef WMPOLICYINTERFACE_H
#define WMPOLICYINTERFACE_H

#include <memory>
#include <functional>

#include <qglobal.h>

namespace miral {
class Workspace;
class Window;
}

class Q_DECL_EXPORT WMPolicyInterface
{
public:
    static WMPolicyInterface *instance();

    virtual std::shared_ptr<miral::Workspace> createWorkspace() = 0;

    virtual void releaseWorkspace(const std::shared_ptr<miral::Workspace> &workspace) = 0;

    virtual void forEachWindowInWorkspace(
        std::shared_ptr<miral::Workspace> const& workspace,
        std::function<void(miral::Window const& window)> const& callback) = 0;

    virtual void moveWorkspaceContentToWorkspace(const std::shared_ptr<miral::Workspace> &toWorkspace,
                                                 const std::shared_ptr<miral::Workspace> &fromWorkspace) = 0;

    virtual void setActiveWorkspace(const std::shared_ptr<miral::Workspace>& workspace) = 0;
};

extern Q_DECL_EXPORT WMPolicyInterface* wmPolicyInterface;

#endif // WMPOLICYINTERFACE_H