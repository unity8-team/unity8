project(com.ubuntu.reminders C CXX)
cmake_minimum_required(VERSION 2.8.9)

set(CMAKE_AUTOMOC ON)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -fno-permissive -pedantic -Wall -Wextra -fPIC")

# Standard install paths
include(GNUInstallDirs)

# components PATH
execute_process(
    COMMAND qmake -query QT_INSTALL_QML
    OUTPUT_VARIABLE QT_IMPORTS_DIR
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

option(INSTALL_TESTS "Install the tests on make install" on)
option(CLICK_MODE "Installs to a contained location" off)

set(APP_NAME reminders)
set(DESKTOP_FILE "${PROJECT_NAME}_${APP_NAME}.desktop")
set(ICON ${APP_NAME}.png)
set(AUTOPILOT_DIR reminders)
set(APP_HARDCODE reminders)
set(MAIN_QML ${APP_HARDCODE}.qml)

if(CLICK_MODE)
    if(NOT DEFINED BZR_SOURCE)
		set(BZR_SOURCE "lp:${APP_HARDCODE}")
		message("-- Setting BZR_SOURCE to ${BZR_SOURCE}")
    endif(NOT DEFINED BZR_SOURCE)
    STRING(REPLACE "/usr/" "/"  QT_IMPORTS_DIR  ${QT_IMPORTS_DIR})
    set(CMAKE_INSTALL_PREFIX /)
    set(CMAKE_INSTALL_BINDIR /)
	set(DATA_DIR /)
	set(EXEC "qmlscene $@ -I .${QT_IMPORTS_DIR} qml/${MAIN_QML}")
	set(DESKTOP_DIR ${DATA_DIR})
else(CLICK_MODE)
	set(DATA_DIR ${CMAKE_INSTALL_DATADIR}/${APP_HARDCODE})
	set(EXEC "qmlscene $@ ${CMAKE_INSTALL_PREFIX}/${DATA_DIR}/qml/${MAIN_QML}")
	set(ICON "${CMAKE_INSTALL_PREFIX}/${DATA_DIR}/${ICON}")
	set(DESKTOP_DIR ${CMAKE_INSTALL_DATADIR}/applications)
endif(CLICK_MODE)

file(GLOB_RECURSE I18N_SRC_FILES
     RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
     rc/**.qml desktop/**.desktop.in)
list(SORT I18N_SRC_FILES)


file(GLOB SRC_FILES
     RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
     *.qml *.js *.png *.js)
install(FILES ${SRC_FILES}  DESTINATION ${DATA_DIR})

configure_file(${DESKTOP_FILE}.in ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE})
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE} DESTINATION ${DESKTOP_DIR})
 
# Tests
enable_testing()

add_subdirectory(click)
add_subdirectory(po)
add_subdirectory(tests)
add_subdirectory(3rdParty)
add_subdirectory(src)
