import QtQuick 2.0

ListModel {
    id: allFeedsModel
    ListElement {
        feedName_m: "Today"
        feedId_m: "home-feed"
        installed_m: true
        favourite_m: true
        persistent_m: true
        feed_screenshot_m: "home-feed.jpg"
    }
    ListElement {
        feedName_m: "Apps"
        feedId_m: "apps-feed"
        installed_m: true
        favourite_m: true
        persistent_m: true
        feed_screenshot_m: "apps-feed.jpg"
    }
    ListElement {
        feedName_m: "Nearby"
        feedId_m: "nearby-feed"
        installed_m: true
        favourite_m: true
        persistent_m: false
        feed_screenshot_m: "nearby-feed.jpg"
    }
    ListElement {
        feedName_m: "News"
        feedId_m: "news-feed"
        installed_m: true
        favourite_m: true
        persistent_m: false
        feed_screenshot_m: "news-feed.jpg"
    }
    ListElement {
        feedName_m: "Music"
        feedId_m: "music-feed"
        installed_m: true
        favourite_m: true
        persistent_m: false
        feed_screenshot_m: "music-feed.jpg"
    }
    ListElement {
        feedName_m: "Photos"
        feedId_m: "photos-feed"
        installed_m: true
        favourite_m: true
        persistent_m: false
        feed_screenshot_m: "photos-feed.jpg"
    }
    ListElement {
        feedName_m: "Video"
        feedId_m: "video-feed"
        installed_m: true
        favourite_m: true
        persistent_m: false
        feed_screenshot_m: "video-feed.jpg"
    }
    ListElement {
        feedName_m: "Shopping"
        feedId_m: "shopping-feed"
        installed_m: true
        favourite_m: false
        persistent_m: false
        feed_screenshot_m: "shopping-feed.jpg"
    }
    ListElement {
        feedName_m: "Amazon"
        feedId_m: "amazon-feed"
        installed_m: true
        favourite_m: false
        persistent_m: false
        feed_screenshot_m: ""
    }
    ListElement {
        feedName_m: "Ebay"
        feedId_m: "ebay-feed"
        installed_m: true
        favourite_m: false
        persistent_m: false
        feed_screenshot_m: ""
    }
    ListElement {
        feedName_m: "Youtube"
        feedId_m: "youtube-feed"
        installed_m: false
        favourite_m: false
        persistent_m: false
        feed_screenshot_m: ""
    }
}
