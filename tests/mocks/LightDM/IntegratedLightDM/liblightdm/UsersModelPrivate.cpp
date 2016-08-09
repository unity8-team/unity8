/*
 * Copyright (C) 2014-2016 Canonical, Ltd.
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

#include "UsersModelPrivate.h"
#include "UsersModel.h"

#define MOCK_UID 9999 // Don't want to use something like 0 as that is root

namespace QLightDM
{

UsersModelPrivate::UsersModelPrivate(UsersModel* parent)
  : mockMode("single")
  , q_ptr(parent)
{
    char *envMockMode = getenv("LIBLIGHTDM_MOCK_MODE");
    if (envMockMode) {
        mockMode = envMockMode;
    }
    resetEntries();
}

void UsersModelPrivate::resetEntries()
{
    Q_Q(UsersModel);

    q->beginResetModel();

    if (mockMode == "single") {
        resetEntries_single();
    } else if (mockMode == "single-passphrase") {
        resetEntries_singlePassphrase();
    } else if (mockMode == "single-pin") {
        resetEntries_singlePin();
    } else if (mockMode == "full") {
        resetEntries_full();
    }

    // Assign uids in a loop, just to avoid having to muck with them when
    // adding or removing test users.
    for (int i = 0; i < entries.size(); i++) {
        entries[i].uid = i + 1;
    }

    q->endResetModel();
}

void UsersModelPrivate::resetEntries_single()
{
    entries =
    {
        { "single", "Single User", 0, 0, false, false, "ubuntu", 0, MOCK_UID },
    };
}

void UsersModelPrivate::resetEntries_singlePassphrase()
{
    entries =
    {
        { "single", "Single User", 0, 0, false, false, "ubuntu", 0, MOCK_UID },
    };
}

void UsersModelPrivate::resetEntries_singlePin()
{
    entries =
    {
        { "has-pin", "Has PIN", 0, 0, false, false, "ubuntu", 0, MOCK_UID },
    };
}

void UsersModelPrivate::resetEntries_full()
{
    entries =
    {
        { "has-password",      "Has Password", 0, 0, false, false, "ubuntu", 0, MOCK_UID },
        { "has-pin",           "Has PIN",      0, 0, false, false, "ubuntu", 0, MOCK_UID },
        { "different-prompt",  "Different Prompt", 0, 0, false, false, "ubuntu", 0, MOCK_UID },
        { "no-password",       "No Password", 0, 0, false, false, "ubuntu", 0, MOCK_UID },
        { "auth-error",        "Auth Error", 0, 0, false, false, "ubuntu", 0, MOCK_UID },
        { "two-factor",        "Two Factor", 0, 0, false, false, "ubuntu", 0, MOCK_UID },
        { "info-prompt",       "Info Prompt", 0, 0, false, false, "ubuntu", 0, MOCK_UID },
        { "html-info-prompt",  "HTML Info Prompt", 0, 0, false, false, "ubuntu", 0, MOCK_UID },
        { "long-info-prompt",  "Long Info Prompt", 0, 0, false, false, "ubuntu", 0, MOCK_UID },
        { "wide-info-prompt",  "Wide Info Prompt", 0, 0, false, false, "ubuntu", 0, MOCK_UID },
        { "multi-info-prompt", "Multi Info Prompt", 0, 0, false, false, "ubuntu", 0, MOCK_UID },
        { "long-name",         "Long name (far far too long to fit, seriously this would never fit on the screen, you will never see this part of the name)", 0, 0, false, false, "ubuntu", 0, MOCK_UID },
        { "color-background",  "Color Background", "#dd4814", 0, false, false, "ubuntu", 0, MOCK_UID },
        // white and black are a bit redundant, but useful for manually testing if UI is still readable
        { "white-background",  "White Background", "#ffffff", 0, false, false, "ubuntu", 0, MOCK_UID },
        { "black-background",  "Black Background", "#000000", 0, false, false, "ubuntu", 0, MOCK_UID },
        { "no-background",     "No Background", "", 0, false, false, "ubuntu", 0, MOCK_UID },
        { "unicode",           "가나다라마", 0, 0, false, false, "ubuntu", 0, MOCK_UID },
        { "no-response",       "No Response", 0, 0, false, false, "ubuntu", 0, MOCK_UID },
        { "empty-name",        "", 0, 0, false, false, "ubuntu", 0, MOCK_UID },
    };
}

} // namespace QLightDM
