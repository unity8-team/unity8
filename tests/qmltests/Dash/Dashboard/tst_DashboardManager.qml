/*
 * Copyright 2017 Canonical Ltd.
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

import QtQuick 2.4
import QtTest 1.0
import "../../../../qml/Dash/Dashboard"
import Ubuntu.Components 1.3
import Unity.Test 0.1 as UT

Item {
    id: root
    width: units.gu(40)
    height: units.gu(80)

    DashboardManager {
        id: dashboardManager
    }

    UT.UnityTestCase {
        name: "ManageDashboard"
        when: windowShown

        function initTestCase() {
            //dashboardManager.scopes.load();
        }

        function scrollToCategory(categoryName) {
            var container = findChild(dashboardManager, "categoriesContainer")
            flickToYBeginning(container);

            tryCompareFunction(function(){
                var cat = findChild(container, categoryName + "Section", 0)

                if (cat !== null) {

                    return true;
                }
                touchFlick(container, container.width / 2, units.gu(20), container.width / 2, container.y, true, true, units.gu(2))
                tryCompare(container, "moving", false);
                return false;
            }, true)
        }

        function test_pinning() {
            var container = findChild(dashboardManager, "categoriesContainer")

            scrollToCategory("Favorites");
            var favorites_category = findChild(container, "FavoritesSection")
            var favorites = findChild(favorites_category, "categoryView")
            var first_favorite = findChild(favorites, "layout0");
            var pin_icon = findChild(first_favorite, "pinIcon");

            // scrollToCategory loads the delegate
            // and this guarantees that it is visible
            container.positionViewAtIndex(favorites_category.index, ListView.Visible);

            // Check the icon path as it will be changed in the future
            compare(/graphics\/pinned\.png$/.test(pin_icon.source), true)

            var initialFavoritesCount = favorites.count
            mouseClick(findChild(first_favorite, "favoriteButton"));
            tryCompare(favorites, "count", initialFavoritesCount - 1);

            scrollToCategory("Non Favorites")
            var non_favorites_category = findChild(container, "Non FavoritesSection")
            var non_favorites = findChild(non_favorites_category, "categoryView")
            var first_non_favorite = findChild(non_favorites, "layout0");
            container.positionViewAtIndex(non_favorites_category.index, ListView.Visible);
            pin_icon = findChild(first_non_favorite, "pinIcon");

            compare(/graphics\/unpinned\.png$/.test(pin_icon.source), true)

            var initialNonFavoritesCount = non_favorites.count
            mouseClick(findChild(first_non_favorite, "favoriteButton"));
            tryCompare(non_favorites, "count", initialNonFavoritesCount - 1);
        }
    }
}
