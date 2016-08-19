import QtQuick 2.4
import Utils 0.1
import Ubuntu.Components 1.3

AbstractStage {
    id: root

    property string mode: "staged"

    Connections {
        target: panelState
        onCloseClicked: { }
        onMinimizeClicked: {
            if (priv.focusedAppDelegate) { priv.focusedAppDelegate.minimize(); }
        }
        onRestoreClicked: {
            if (priv.focusedAppDelegate) { priv.focusedAppDelegate.unmaximize(); }
        }
        onFocusMaximizedApp: {
        }
    }

    Binding {
        target: panelState
        property: "buttonsVisible"
        value: priv.focusedAppDelegate !== null && priv.focusedAppDelegate.maximized
    }

    QtObject {
        id: priv
        property var focusedAppDelegate: null
    }

    states: [
        State {
            name: "staged"; when: root.mode === "staged"
        },
        State {
            name: "windowed"; when: root.mode === "windowed"
        }
    ]

    FocusScope {
        id: appContainer
        objectName: "appContainer"
        anchors.fill: parent

        TopLevelSurfaceRepeater {
            id: appRepeater
            model: topLevelSurfaceList
            objectName: "appRepeater"

            delegate: FocusScope {
                id: appDelegate

                property int windowedX: 0
                property int windowedY: 0
                property int windowedWidth: units.gu(60)
                property int windowedHeight: units.gu(60)

                property bool maximized: false

                x: windowState.relativePosition.mappedX
                y: windowState.relativePosition.mappedY

                width: decoratedWindow.implicitWidth
                height: decoratedWindow.implicitHeight
                opacity: windowState.valid ? windowState.opacity : 1
                scale: windowState.valid ? windowState.scale : 1

                WindowedState {
                    id: windowState

                    target: appDelegate
                    windowId: model.application.appId

                    relativePosition {
                        x: windowState.geometry.x
                        y: windowState.geometry.y

                        onXChanged: {
                            if (windowState.state === WindowState.Normal) {
                                appDelegate.windowedX = relativePosition.mappedX;
                            }
                        }
                        onYChanged: {
                            if (windowState.state === WindowState.Normal) {
                                appDelegate.windowedY = relativePosition.mappedY;
                            }
                        }
                    }
                }

                Component.onCompleted: {
                    console.log("DELEGATE DONE ", screenWindow.objectName, state);
                    console.log("   shared position: ", windowState.geometry.x, windowState.geometry.y);
                    console.log("   local position : ", windowState.relativePosition.mappedX, windowState.relativePosition.mappedY);
                }

                states: [
                    State {
                        name: "offscreen"
                    },
                    State {
                        name: "staged"
                        when: root.state == "staged"
                        PropertyChanges {
                            target: windowState.absolutePosition
                            x: root.leftMargin
                            y: 0
                        }
                        PropertyChanges {
                            target: windowState.geometry
                            height: appContainer.height
                            width: appContainer.width - root.leftMargin
                        }
                    },
                    State {
                        name: "normal"
                        when: windowState.valid && windowState.state === WindowState.Normal
                        PropertyChanges {
                            target: windowState.absolutePosition
                            restoreEntryValues: false
                            x: appDelegate.windowedX
                            y: appDelegate.windowedY
                        }
                        PropertyChanges {
                            target: windowState.geometry
                            restoreEntryValues: false
                            width: appDelegate.windowedWidth
                            height: appDelegate.windowedHeight
                        }
                    },
                    State {
                        name: "maximized"
                        when: windowState.valid && windowState.state === WindowState.Maximized && windowState.stateSource
                        PropertyChanges {
                            target: appDelegate
                            maximized: true
                        }
                        PropertyChanges {
                            target: windowState.absolutePosition
                            x: root.leftMargin
                            y: 0
                        }
                        PropertyChanges {
                            target: windowState.geometry
                            height: appContainer.height
                            width: appContainer.width - root.leftMargin
                        }
                    },
                    State {
                        name: "minimized"
                        when: windowState.valid && windowState.state & WindowState.Minimized && windowState.stateSource
                        PropertyChanges {
                            target: windowState
                            scale: units.gu(5) / appDelegate.width;
                            opacity: 0
                        }
                        PropertyChanges {
                            target: windowState.absolutePosition
                            x: -appDelegate.width / 2 + root.leftMargin
                        }
                    }
                ]
                state: "offscreen"
                onStateChanged: console.log("app", model.application.appId, state, "on ", screenWindow.objectName)

                transitions: [
                    Transition {
                        from: "offscreen"
                        PropertyAction { target: appDelegate; properties: "maximized" }
                        PropertyAction { target: windowState.absolutePosition; properties: "x,y" }
                        PropertyAction { target: windowState.geometry; properties: "width,height" }
                        PropertyAction { target: windowState; properties: "scale,opacity" }
                    },
                    Transition {
                        to: "normal"
                        PropertyAction { target: appDelegate; properties: "maximized" }
                        UbuntuNumberAnimation { target: windowState.absolutePosition; properties: "x,y" }
                        UbuntuNumberAnimation { target: windowState.geometry; properties: "width,height" }
                        UbuntuNumberAnimation { target: windowState; properties: "scale,opacity" }
                    },
                    Transition {
                        to: "maximized"
                        PropertyAction { target: appDelegate; properties: "maximized" }
                        UbuntuNumberAnimation { target: windowState.absolutePosition; properties: "x,y" }
                        UbuntuNumberAnimation { target: windowState.geometry; properties: "width,height" }
                        UbuntuNumberAnimation { target: windowState; properties: "scale,opacity" }
                    },
                    Transition {
                        to: "minimized"
                        PropertyAction { target: appDelegate; properties: "maximized" }
                        UbuntuNumberAnimation { target: windowState.absolutePosition; properties: "x,y" }
                        UbuntuNumberAnimation { target: windowState.geometry; properties: "width,height" }
                        UbuntuNumberAnimation { target: windowState; properties: "scale,opacity" }
                    }
                ]

                function maximize(animate) {
                    if (windowState.state == WindowState.Normal) {
                        windowState.saveWindowState();
                    }

                    priv.focusedAppDelegate = appDelegate;
                    windowState.state = WindowState.Maximized;
                }

                function unmaximize(animate) {
                    priv.focusedAppDelegate = appDelegate;
                    windowState.state = WindowState.Normal;
                }

                function minimize(animate) {
                    if (windowState.state == WindowState.Normal) {
                        windowState.saveWindowState();
                    }

                    priv.focusedAppDelegate = appDelegate;
                    windowState.state |= WindowState.Minimized;
                }

                function restore() {
                    if (windowState.state !== WindowState.Normal) {
                        windowState.loadWindowState();
                    }

                    priv.focusedAppDelegate = appDelegate;
                    windowState.state &= ~WindowState.Minimized;
                }

                Connections {
                    target: model.surface
                    onFocusRequested: {
                        priv.focusedAppDelegate = appDelegate;
                        // only if this stage was the source of the minimize.
                        if (windowState.state & ~WindowState.Minimized && windowState.stateSource) {
                            appDelegate.restore();
                        }
                    }
                }

                WindowDecoration {
                    target: appDelegate
                    height: units.gu(3)
                    width: appDelegate.width
                    title: model.application.appId
                    panelState: root.panelState

                    onMaximizeClicked: appDelegate.maximize()
                    onMinimizeClicked: appDelegate.minimize()
                }

                DecoratedWindow {
                    id: decoratedWindow
                    anchors.left: appDelegate.left
                    anchors.top: appDelegate.top

                    application: model.application
                    surface: model.surface
                    active: appDelegate.focus
                    focus: true
                    showDecoration: true

                    requestedWidth: windowState.valid ? windowState.geometry.width : -1
                    requestedHeight: windowState.valid ? windowState.geometry.height : -1

                    width: implicitWidth
                    height: implicitHeight
                    panelState: root.panelState

                    onMaximizeClicked: {
                        if (windowState.state & WindowState.Maximized) {
                            appDelegate.restore();
                        } else {
                            appDelegate.maximize();
                        }
                    }
                    onMinimizeClicked: {
                        appDelegate.minimize();
                    }
                }
            }
        }
    }
}
