add_library(Aethercast-qml MODULE
    plugin.cpp
    aethercastmanager.cpp
    inputprovider.cpp
    inputprovideradaptor.cpp
    managerinterface.cpp
    )

qt5_use_modules(Aethercast-qml Qml Gui DBus)

add_unity8_plugin(Aethercast 0.1 Aethercast TARGETS Aethercast-qml)
