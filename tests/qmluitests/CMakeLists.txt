add_custom_target(qmluitests)

set(qmltest_DEFAULT_TARGETS qmluitests alltests)
set(qmltest_DEFAULT_NO_ADD_TEST TRUE)

add_qml_test(ButtonMenu)
add_qml_test(MediaPlayerMenu)
