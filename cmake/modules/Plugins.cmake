find_program(qmlplugindump_exe qmlplugindump)

if(NOT qmlplugindump_exe)
  msg(FATAL_ERROR "Could not locate qmlplugindump.")
endif()

# Creates target for copying and installing qmlfiles
#
# export_qmlfiles(plugin sub_path)
#
#
# Target to be created:
#   - plugin-qmlfiles - Copies the qml files (*.qml, *.js, qmldir) into the shadow build folder.

macro(export_qmlfiles PLUGIN PLUGIN_PATH)

    file(GLOB QMLFILES
        *.qml
        *.js
        qmldir
    )

    # copy the qmldir file
    add_custom_target(${PLUGIN}-qmlfiles ALL
                        COMMAND cp ${QMLFILES} ${CMAKE_BINARY_DIR}/${PLUGIN_PATH}
                        DEPENDS ${QMLFILES}
                        SOURCES ${QMLFILES}
    )

    # install the qmlfiles file.
    install(FILES ${QMLFILES}
        DESTINATION ${QT_IMPORTS_DIR}/${PLUGIN_PATH}
    )
endmacro(export_qmlfiles)

macro(export_artwork PLUGIN PLUGIN_PATH)

    file(GLOB ARTFILES
        *.png
        *.svg
    )

    # copy the qmldir file
    add_custom_target(${PLUGIN}-artwork ALL
                        COMMAND cp ${ARTFILES} ${CMAKE_BINARY_DIR}/${PLUGIN_PATH}
                        DEPENDS ${ARTFILES}
                        SOURCES ${ARTFILES}
    )

    # install the qmlfiles file.
    install(FILES ${ARTFILES}
        DESTINATION ${QT_IMPORTS_DIR}/${PLUGIN_PATH}
    )
endmacro(export_artwork)


# Creates target for generating the qmltypes file for a plugin and installs plugin files
#
# export_qmlplugin(plugin version sub_path [TARGETS target1 [target2 ...]])
#
# TARGETS additional install targets (eg the plugin shared object)
#
# Target to be created:
#   - plugin-qmltypes - Generates the qmltypes file in the shadow build folder.

macro(export_qmlplugin PLUGIN VERSION PLUGIN_PATH)
    set(multi_value_keywords TARGETS)
    cmake_parse_arguments(qmlplugin "" "" "${multi_value_keywords}" ${ARGN})

    # Only try to generate .qmltypes if not cross compiling
    if(NOT CMAKE_CROSSCOMPILING)
        # create the plugin.qmltypes file
        add_custom_target(${PLUGIN}-qmltypes ALL
            COMMAND ${qmlplugindump_exe} -notrelocatable ${PLUGIN} ${VERSION} ${CMAKE_BINARY_DIR} > ${CMAKE_BINARY_DIR}/${PLUGIN_PATH}/plugin.qmltypes
        )
        add_dependencies(${PLUGIN}-qmltypes ${PLUGIN}-qmlfiles ${qmlplugin_TARGETS})

        # install the qmltypes file.
        install(FILES ${CMAKE_BINARY_DIR}/${PLUGIN_PATH}/plugin.qmltypes
            DESTINATION ${QT_IMPORTS_DIR}/${PLUGIN_PATH}
        )
    endif()

    # install the additional targets
    install(TARGETS ${qmlplugin_TARGETS}
        DESTINATION ${QT_IMPORTS_DIR}/${PLUGIN_PATH}
    )
endmacro(export_qmlplugin)
