include(QmlPlugins)

# Set up and optionally install a mock plugin for ubuntu-settings-components.
#
# add_usc_mock(plugin version path
#     [PREFIX string]  # Install the plugin to the specified prefix under unity8 private plugin directory
#     [...]            # See export_qmlfiles and export_qmlplugin documentation for more options
# )

macro(add_usc_mock PLUGIN VERSION PATH)
    set(single PREFIX)
    cmake_parse_arguments(MOCK "" "${single}" "" ${ARGN})

    if(MOCK_PREFIX)
        export_qmlfiles(${PLUGIN} ${PATH}
            DESTINATION ${SHELL_INSTALL_QML}/${MOCK_PREFIX}
            TARGET_PREFIX ${MOCK_PREFIX}-Mock
            ${MOCK_UNPARSED_ARGUMENTS}
        )
        export_qmlplugin(${PLUGIN} ${VERSION} ${PATH}
            DESTINATION ${SHELL_INSTALL_QML}/${MOCK_PREFIX}
            TARGET_PREFIX ${MOCK_PREFIX}-Mock
            ${MOCK_UNPARSED_ARGUMENTS}
        )
    else()
        export_qmlfiles(${PLUGIN} ${PATH} TARGET_PREFIX Mock ${MOCK_UNPARSED_ARGUMENTS})
        export_qmlplugin(${PLUGIN} ${VERSION} ${PATH} TARGET_PREFIX Mock ${MOCK_UNPARSED_ARGUMENTS})
    endif()
endmacro()

add_subdirectory(Biometryd)
