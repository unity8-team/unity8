import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Window 2.0

Item {
    id: feedManager

    width: 100
    height: 100

    property alias dashModel: dashModel
    property alias manageDashModel: manageDashModel

    Component.onCompleted: {
        __initialize()
    }

    function printDashModel() {
        console.log("Print dash model:")
        for (var i = 0; i < dashModel.count; i++) {
            console.log("name", dashModel.get(i).feedName_m)
            console.log("installed", dashModel.get(i).installed_m)
            console.log("favourite", dashModel.get(i).favourite_m)
            console.log("")
        }
    }

    function printManageDashModel() {
        console.log("Print manage dash model:")
        for (var i = 0; i < manageDashModel.count; i++) {
            console.log("name", manageDashModel.get(i).feedName_m)
            console.log("installed", manageDashModel.get(i).installed_m)
            console.log("favourite", manageDashModel.get(i).favourite_m)
            console.log("---------------------------------------------")
        }
    }


    function __initialize() {
        __initializeManageDashModel()
        __initializeDashModel()
    }

    function __initializeManageDashModel() {
        manageDashModel.clear()
        for (var i = 0; i < allFeedsModel.count; i++) {
            if (allFeedsModel.get(i).installed_m) {
                manageDashModel.append(allFeedsModel.get(i))
            }
        }
    }

    function __initializeDashModel() {
        dashModel.clear()
        for (var i = 0; i < manageDashModel.count; i++) {
            if (manageDashModel.get(i).favourite_m) {
                dashModel.append(manageDashModel.get(i))
            }
        }
    }

    // API: called outside to favourite one feed
    function favouriteFeed(feedName) {
        console.log("Favourite a feed:", feedName)

        var foundManageIndex = findFirstModelIndexByName(manageDashModel, feedName)
        var foundDashIndex = findFirstModelIndexByName(dashModel, feedName)

        if (foundManageIndex != -1 && foundDashIndex == -1) {
            manageDashModel.setProperty(foundManageIndex, "favourite_m", true)
            dashModel.append(manageDashModel.get(foundManageIndex))
        } else if (foundDashIndex != -1) {
            console.log("Favourite: Feed is already a favourite")
        } else if (foundManageIndex == -1) {
            console.log("Favourite: Feed not installed")
        }

        __groupFavouriteFeedsInTheBeginning(manageDashModel)
    }

    // API: called outside to unfavourite one feed
    function unfavouriteFeed(feedName) {
        console.log("Unfavourite a feed:", feedName)

        var foundIndex = findFirstModelIndexByName(manageDashModel, feedName)
        if (foundIndex != -1) {
            manageDashModel.get(foundIndex).favourite_m = false
        } else {
            console.log("Unfavourite: Feed not installed")
        }

        // remove item in Dash model
        foundIndex = findFirstModelIndexByName(dashModel, feedName)
        if (foundIndex != -1) {
            dashModel.remove(foundIndex)
        } else {
            console.log("Unfavourite: Feed is not part of dash")
        }

        __groupFavouriteFeedsInTheBeginning(manageDashModel)
    }

    function moveFavouriteFeed(feedName, toIndex) {
        console.log("moveFavouriteFeed, feed:", feedName, " to:", toIndex)
        var foundManageIndex = findFirstModelIndexByName(manageDashModel, feedName)
        var foundDashIndex = findFirstModelIndexByName(dashModel, feedName)
        if (foundManageIndex != -1 && foundDashIndex != -1) {
            manageDashModel.move(foundManageIndex, toIndex, 1)
            dashModel.move(foundDashIndex, toIndex, 1)
        } else {
            console.log("moveFavouriteFeed: Feed not found or models not in sync")
        }
    }

    function removeInstalledFeed(feedName) {
        console.log("removeInstalledFeed:", feedName)

        // remove item in Dash model
        var foundIndex = findFirstModelIndexByName(dashModel, feedName)
        if (foundIndex != -1) {
            dashModel.remove(foundIndex)
        } else {
            console.log("Unfavourite: Feed is not part of dash")
        }

        // remove item in Dash model
        foundIndex = findFirstModelIndexByName(manageDashModel, feedName)
        if (foundIndex != -1) {
            manageDashModel.remove(foundIndex)
        } else {
            console.log("Unfavourite: Feed is not part of manageDash model")
        }

    }

    // helpers--------------------------------------------------
    function findFirstModelIndexByName(model, feedName) {
        for (var i = 0; i < model.count; i++) {
            if (model.get(i).feedName_m == feedName) {
                return i
            }
        }
        return -1
    }

    function findFirstModelIndexById(model, feedId) {
        for (var i = 0; i < model.count; i++) {
            if (model.get(i).feedId_m == feedId) {
                return i
            }
        }
        return -1
    }

    function __groupFavouriteFeedsInTheBeginning(model) {
        var foundCount = 0
        for (var i = 0; i < model.count; i++) {
            if (model.get(i).favourite_m == true) {
                model.move(i, foundCount, 1)
                foundCount++
            }
        }
    }

    AllFeedsModel {
        id: allFeedsModel
    }

    ListModel {
        id: dashModel
    }

    ListModel {
        id: spreadModel
    }

    ListModel {
        id: manageDashModel
    }

}
