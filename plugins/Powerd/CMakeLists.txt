include(Plugins)

add_definitions(-DSM_BUSNAME=systemBus)

add_library(Powerd-qml MODULE
    plugin.cpp
    Powerd.cpp
    )

qt5_use_modules(Powerd-qml DBus Qml)
pkg_check_modules(UA REQUIRED ubuntu-platform-api)

include_directories(
    ${UA_INCLUDE_DIRS}
    )

target_link_libraries(Powerd-qml
    ${UA_LDFLAGS}
    )

export_qmlfiles(Powerd Powerd)
export_qmlplugin(Powerd 0.1 Powerd TARGETS Powerd-qml)
