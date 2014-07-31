file(GLOB QML_JS_FILES *.qml *.js)
add_custom_target( ComponentTestQMLFiles SOURCES ${QML_JS_FILES} )

add_qml_test(. Calendar)
add_qml_test(. StatusIcon)
