set(IntegratedLightDM_SOURCES
    Greeter.cpp
    UsersModel.cpp
    GreeterPrivate.cpp
    UsersModelPrivate.cpp
    )

include_directories(
    ${CMAKE_CURRENT_BINARY_DIR}
    )

add_library(integratedLightDM SHARED ${IntegratedLightDM_SOURCES})

target_link_libraries(integratedLightDM
    -lpam
    )

qt5_use_modules(integratedLightDM Concurrent Gui)

set_target_properties(integratedLightDM PROPERTIES
                      OUTPUT_NAME lightdm-qt5-3)

install(TARGETS integratedLightDM
    DESTINATION ${SHELL_INSTALL_QML}/liblightdm
    )
