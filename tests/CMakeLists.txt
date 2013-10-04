# QML tests that require graphical capabitlies.
add_custom_target(qmluitests)

add_custom_target(qmltests)
add_dependencies(qmltests qmluitests)

add_subdirectory(qmltests)
