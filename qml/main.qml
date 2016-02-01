import QtQuick 2.3
import Unity.Screens 0.1

Instantiator {
    id: root

    readonly property var screens: Screens{}
    readonly property var shell: OrientedShell {}

    model: screens
    ScreenWindow {
        id: window
        visible: true
        screen: model.screen

        readonly property bool isPrimary: (screens.count === 1 || outputType === 11)

        Loader {
            id: loader
            anchors.fill: parent
            source: (isPrimary) ? "" : "DisabledScreenNotice.qml"
            Binding { target: loader.item; property: "units"; value: units }
        }

        onIsPrimaryChanged: {
            if (isPrimary) {
                shell.parent = loader
                shell.anchors.fill = loader
            }
        }

        Component.onCompleted: {
            print("Window created for Screen", screen, screen.geometry, outputType, Screens.HDMIA, screen.devicePixelRatio)
            if (isPrimary) {
                shell.parent = loader
                shell.anchors.fill = loader
            }
        }
        Component.onDestruction: {
            print("Window destroyed")
        }

        onScaleChanged: print("NOTICE: scale changed for", model.screen, "to", scale);
        onFormFactorChanged: print("NOTICE: form factor changed for", model.screen, "to", formFactor)
    }
}
