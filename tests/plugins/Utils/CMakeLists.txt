# add_qml_test macro
include(QmlTest)

include_directories(
    ${UtilsQmlPlugin_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/../../../plugins/Utils
    ${CMAKE_CURRENT_BINARY_DIR}
    )

set(qmltest_DEFAULT_IMPORT_PATHS
  ${CMAKE_BINARY_DIR}/tests/utils/modules
  ${CMAKE_BINARY_DIR}/tests/mocks
)

macro(run_tests)
    set(_test_list "")
    foreach(_test ${ARGN})
        set(testCommand ${CMAKE_CURRENT_BINARY_DIR}/${_test}Exec
              -o ${CMAKE_BINARY_DIR}/${_test}.xml,xunitxml
              -o -,txt)
        add_test(NAME ${_test} COMMAND ${testCommand})
        add_custom_target(${_test} ${testCommand})
        add_executable(${_test}Exec ${_test}.cpp modeltest.cpp)
        qt5_use_modules(${_test}Exec Test Core Qml)
        target_link_libraries(${_test}Exec
            Utils-qml
            )
        set(_test_list "${_test_list};${_test}")
    endforeach()
endmacro(run_tests)

run_tests(
    qlimitproxymodeltest
    qsortfilterproxymodeltest
    timeformattertest
    )

set(qmltest_DEFAULT_NO_ADD_TEST TRUE)
add_qml_test(. PassthroughMouseArea IMPORT_PATHS ${CMAKE_BINARY_DIR}/plugins ${qmltest_DEFAULT_IMPORT_PATHS})
add_dependencies(qmluitests testPassthroughMouseArea)
