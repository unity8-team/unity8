include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/plugins/Cursor/3rd_party/xcursor
    ${CMAKE_SOURCE_DIR}/plugins/Cursor/
)

include_directories(
    SYSTEM
    ${Qt5Gui_PRIVATE_INCLUDE_DIRS}
)

set(QMLPLUGIN_SRC
    plugin.cpp
    WindowedMousePointer.cpp
    ${CMAKE_SOURCE_DIR}/plugins/Cursor/CursorImageInfo.cpp
    ${CMAKE_SOURCE_DIR}/plugins/Cursor/CursorImageProvider.cpp
    ${CMAKE_SOURCE_DIR}/plugins/Cursor/MousePointer.cpp
    # We need to run moc on this header
    ${APPLICATION_API_INCLUDEDIR}/unity/shell/application/MirMousePointerInterface.h
    )

add_library(WindowedCursor-qml SHARED ${QMLPLUGIN_SRC})

target_link_libraries(WindowedCursor-qml
    xcursorloader-static
    ${QT5PLATFORM_SUPPORT_LDFLAGS}
)

qt5_use_modules(WindowedCursor-qml Qml Quick Svg)

# It takes Cursor.qml directly from the production Cursor plugin. We use our own qmldir file though, hence
# the custom globbing expression.
add_unity8_mock(Cursor 1.1 Cursor
    GLOBBING_EXPRESSIONS ${CMAKE_CURRENT_SOURCE_DIR}/qmldir ${CMAKE_SOURCE_DIR}/plugins/Cursor/*.qml)
