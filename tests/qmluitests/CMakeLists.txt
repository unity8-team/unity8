add_custom_target(qmluitests)

set(qmltest_DEFAULT_TARGETS qmluitests alltests)
set(qmltest_DEFAULT_NO_ADD_TEST TRUE)

add_qml_test(ButtonMenu)
add_qml_test(Calendar)
add_qml_test(CalendarMenu)
add_qml_test(EventMenu)
add_qml_test(MediaPlayerMenu)
add_qml_test(ProgressBarMenu)
add_qml_test(SliderMenu)
add_qml_test(UserSessionMenu)
add_qml_test(TimeZoneMenu)
