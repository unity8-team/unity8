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
 *
 * Author: Michael Terry <michael.terry@canonical.com>
 */

#include "../UsersModelPrivate.h"

namespace QLightDM
{

UsersModelPrivate::UsersModelPrivate(UsersModel* parent)
  : q_ptr(parent)
{
    entries =
    {
        { "has-password",      "Has Password", 0, 0, false, false, 0, 0, 1000 },
        { "has-pin",           "Has PIN",      0, 0, false, false, 0, 0, 1001 },
        { "different-prompt",  "Different Prompt", 0, 0, false, false, 0, 0, 1002 },
        { "no-password",       "No Password", 0, 0, false, false, 0, 0, 1003 },
        { "auth-error",        "Auth Error", 0, 0, false, false, 0, 0, 1004 },
        { "two-factor",        "Two Factor", 0, 0, false, false, 0, 0, 1005 },
        { "info-prompt",       "Info Prompt", 0, 0, false, false, 0, 0, 1006 },
        { "html-info-prompt",  "HTML Info Prompt", 0, 0, false, false, 0, 0, 1007 },
        { "long-info-prompt",  "Long Info Prompt", 0, 0, false, false, 0, 0, 1008 },
        { "wide-info-prompt",  "Wide Info Prompt", 0, 0, false, false, 0, 0, 1009 },
        { "multi-info-prompt", "Multi Info Prompt", 0, 0, false, false, 0, 0, 1010 },
        { "long-name",         "Long name (far far too long to fit)", 0, 0, false, false, 0, 0, 1011 },
        { "color-background",  "Color Background", "#dd4814", 0, false, false, 0, 0, 1012 },
        // white and black are a bit redundant, but useful for manually testing if UI is still readable
        { "white-background",  "White Background", "#ffffff", 0, false, false, 0, 0, 1013 },
        { "black-background",  "Black Background", "#000000", 0, false, false, 0, 0, 1014 },
        { "no-background",     "No Background", "", 0, false, false, 0, 0, 1015 },
        { "unicode",           "가나다라마", 0, 0, false, false, 0, 0, 1016 },
        { "no-response",       "No Response", 0, 0, false, false, 0, 0, 1017 },
        { "empty-name",        "", 0, 0, false, false, 0, 0, 1018 },
    };
}

}
