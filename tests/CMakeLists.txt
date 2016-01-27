add_subdirectory(utils)

# QML tests that require graphical capabitlies.
add_custom_target(qmluitests)
add_dependencies(qmluitests UbuntuTest)

add_custom_target(qmltests)
add_dependencies(qmltests qmluitests)

add_subdirectory(imports)
add_subdirectory(qmltests)
