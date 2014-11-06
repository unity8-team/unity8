import QtQuick 2.0

ListModel {
    id: allFeedsModel
    ListElement {
        feedName_m: "Today"
        feedId_m: "home-feed"
        installed_m: true
        favourite_m: true
        persistent_m: true
        custom_qml_file_m: ""
        feed_screenshot_m: "home-feed.jpg"
        feed_icon_m: ""
        feed_promo_icon_m: ""
    }
    ListElement {
        feedName_m: "Apps"
        feedId_m: "apps-feed"
        installed_m: true
        favourite_m: true
        persistent_m: true
        custom_qml_file_m: "Apps/AppsFeed.qml"
        feed_screenshot_m: "apps-feed.jpg"
        feed_icon_m: "apps-feed-icon.jpg"
        feed_promo_icon_m: "apps-feed-promo.jpg"
    }
    ListElement {
        feedName_m: "Nearby"
        feedId_m: "nearby-feed"
        installed_m: true
        favourite_m: true
        persistent_m: false
        custom_qml_file_m: ""
        feed_screenshot_m: "nearby-feed.jpg"
        feed_icon_m: "nearby-feed-icon.jpg"
        feed_promo_icon_m: "nearby-feed-promo.jpg"
    }
    ListElement {
        feedName_m: "News"
        feedId_m: "news-feed"
        installed_m: true
        favourite_m: true
        persistent_m: false
        custom_qml_file_m: ""
        feed_screenshot_m: "news-feed.jpg"
        feed_icon_m: "news-feed-icon.jpg"
        feed_promo_icon_m: "news-feed-promo.jpg"
    }
    ListElement {
        feedName_m: "Music"
        feedId_m: "music-feed"
        installed_m: true
        favourite_m: true
        persistent_m: false
        custom_qml_file_m: ""
        feed_screenshot_m: "music-feed.jpg"
        feed_icon_m: "music-feed-icon.jpg"
        feed_promo_icon_m: "music-feed-promo.jpg"
    }
    ListElement {
        feedName_m: "Photos"
        feedId_m: "photos-feed"
        installed_m: true
        favourite_m: false
        persistent_m: false
        custom_qml_file_m: ""
        feed_screenshot_m: "photos-feed.jpg"
        feed_icon_m: "photos-feed-icon.jpg"
        feed_promo_icon_m: "photos-feed-promo.jpg"
    }
    ListElement {
        feedName_m: "Video"
        feedId_m: "video-feed"
        installed_m: true
        favourite_m: false
        persistent_m: false
        custom_qml_file_m: ""
        feed_screenshot_m: "video-feed.jpg"
        feed_icon_m: "video-feed-icon.jpg"
        feed_promo_icon_m: "video-feed-promo.jpg"
    }
    ListElement {
        feedName_m: "Shopping"
        feedId_m: "shopping-feed"
        installed_m: false
        favourite_m: false
        persistent_m: false
        custom_qml_file_m: ""
        feed_screenshot_m: "shopping-feed.jpg"
        feed_icon_m: "shopping-feed-icon.jpg"
        feed_promo_icon_m: "shopping-feed-promo.jpg"
    }
    ListElement {
        feedName_m: "Amazon"
        feedId_m: "amazon-feed"
        installed_m: false
        favourite_m: false
        persistent_m: false
        custom_qml_file_m: ""
        feed_screenshot_m: ""
        feed_icon_m: ""
        feed_promo_icon_m: ""
    }
    ListElement {
        feedName_m: "Ebay"
        feedId_m: "ebay-feed"
        installed_m: false
        favourite_m: false
        persistent_m: false
        custom_qml_file_m: ""
        feed_screenshot_m: ""
        feed_icon_m: ""
        feed_promo_icon_m: ""
    }
    ListElement {
        feedName_m: "Youtube"
        feedId_m: "youtube-feed"
        installed_m: false
        favourite_m: false
        persistent_m: false
        custom_qml_file_m: ""
        feed_screenshot_m: ""
        feed_icon_m: ""
        feed_promo_icon_m: ""
    }
}
