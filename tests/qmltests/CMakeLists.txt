# add_qml_test macro
include(QmlTest)

set(qmltest_DEFAULT_TARGETS qmluitests)
set(qmltest_DEFAULT_NO_ADD_TEST TRUE)
set(qmltest_DEFAULT_PROPERTIES "")

set(qmltest_DEFAULT_IMPORT_PATHS
  ${CMAKE_BINARY_DIR}
  ${CMAKE_BINARY_DIR}/tests/utils/modules
)

add_subdirectory(Menus)
add_subdirectory(Components)
