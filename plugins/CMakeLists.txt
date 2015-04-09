include(QmlPlugins)

macro(add_usc_plugin PLUGIN VERSION PATH)
    export_qmlfiles(${PLUGIN} ${PATH} DESTINATION ${QT_IMPORTS_DIR} ${ARGN})
    export_qmlplugin(${PLUGIN} ${VERSION} ${PATH} DESTINATION ${QT_IMPORTS_DIR} ${ARGN})
endmacro()

add_subdirectory(Ubuntu)
