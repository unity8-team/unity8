# add_qml_test macro
include(QmlTest)

set(qmltest_DEFAULT_TARGETS qmluitests)
set(qmltest_DEFAULT_NO_ADD_TEST TRUE)
set(qmltest_DEFAULT_PROPERTIES "")

set(qmltest_DEFAULT_IMPORT_PATHS
  ${CMAKE_SOURCE_DIR}
)

add_qml_test(Components Calendar)

add_qml_test(Menus ButtonMenu)
add_qml_test(Menus CalendarMenu)
add_qml_test(Menus EventMenu)
add_qml_test(Menus MediaPlayerMenu)
add_qml_test(Menus PlaybackItemMenu)
add_qml_test(Menus ProgressBarMenu)
add_qml_test(Menus SliderMenu)
add_qml_test(Menus UserSessionMenu)
add_qml_test(Menus TimeZoneMenu)
