import QtQuick 2.0

Item {
    id: showable

    property bool available: true
    property bool shown: true

    property list<QtObject> hides
    property var showAnimation
    property var hideAnimation

    // automatically set the target on showAnimation and hideAnimation to be the
    // showable itself
    onShowAnimationChanged: if (showAnimation) showAnimation["target"] = showable
    onHideAnimationChanged: if (hideAnimation) hideAnimation["target"] = showable

    function __hideOthers() {
        var i
        for (i=0; i<hides.length; i++) {
            hides[i].hide()
        }
    }

    function show() {
        if (available) {
            __hideOthers()
            if (hideAnimation != undefined && hideAnimation.running) {
                hideAnimation.stop()
            }
            if (showAnimation != undefined) {
                if (!showAnimation.running) {
                    showAnimation.restart()
                }
            } else {
                visible = true
            }

            shown = true
            return true
        }
        return false
    }

    function hide() {
        if (showAnimation != undefined && showAnimation.running) {
            showAnimation.stop()
        }
        if (hideAnimation != undefined) {
            if (!hideAnimation.running) {
                hideAnimation.restart()
            }
        } else {
            visible = false
        }

        shown = false
    }
}
