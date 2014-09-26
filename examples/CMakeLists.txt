file(GLOB QML_JS_FILES *.qml *.js)
add_custom_target( ExampleQmlFiles SOURCES ${QML_JS_FILES} )
