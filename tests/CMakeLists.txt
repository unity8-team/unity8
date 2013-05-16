# add_qml_test(component_name [NO_ADD_TEST] [NO_TARGETS] [TARGETS target1 target2] [IMPORT_PATH import_path] [PROPERTIES ...])
# NO_ADD_TEST will prevent adding the test to the "make test" target
# NO_TARGETS will prevent adding the test to any targets
# TARGETS lists the targets the test should be added to
# IMPORT_PATH will pass that path to qmltestrunner
# PROPERTIES will be set on the target and test target
#
# To change/set a default value for the whole test suite, prior to calling add_qml_test, set:
# qmltest_DEFAULT_NO_ADD_TEST (default: FALSE)
# qmltest_DEFAULT_TARGETS
# qmltest_DEFAULT_PROPERTIES

macro(add_qml_test COMPONENT_NAME)
    set(options NO_ADD_TEST NO_TARGETS)

    cmake_parse_arguments(qmltest "${options}" "IMPORT_PATH" "TARGETS" ${ARGN})

    set(qmltest_TARGET test${COMPONENT_NAME})
    set(qmltest_FILE tst_${COMPONENT_NAME})

    if("${qmltest_IMPORT_PATH}" STREQUAL "")
        add_custom_target(${qmltest_TARGET}
            qmltestrunner -input ${CMAKE_CURRENT_SOURCE_DIR}/${qmltest_FILE}.qml
                          -o ${CMAKE_BINARY_DIR}/${qmltest_TARGET}.xml,xunitxml
                          -o -,txt)
    else("${qmltest_IMPORT_PATH}" EQUAL "")
        add_custom_target(${qmltest_TARGET}
            qmltestrunner -input ${CMAKE_CURRENT_SOURCE_DIR}/${qmltest_FILE}.qml
                          -import ${qmltest_IMPORT_PATH}
                          -o ${CMAKE_BINARY_DIR}/${qmltest_TARGET}.xml,xunitxml
                          -o -,txt)
    endif("${qmltest_IMPORT_PATH}" STREQUAL "")

    if(NOT "${qmltest_UNPARSED_ARGUMENTS}" STREQUAL "")
        set_target_properties(${qmltest_TARGET} ${qmltest_PROPERTIES})
    elseif(NOT "${qmltest_DEFAULT_PROPERTIES}" STREQUAL "")
        set_target_properties(${qmltest_TARGET} ${qmltest_DEFAULT_PROPERTIES})
    endif(NOT "${qmltest_UNPARSED_ARGUMENTS}" STREQUAL "")

    if("${qmltest_NO_ADD_TEST}" STREQUAL FALSE AND NOT "${qmltest_DEFAULT_NO_ADD_TEST}" STREQUAL "TRUE")
        add_test(${qmltest_TARGET} make ${qmltest_TARGET})

        if(NOT "${qmltest_UNPARSED_ARGUMENTS}" STREQUAL "")
            set_tests_properties(${qmltest_TARGET} ${qmltest_PROPERTIES})
        elseif(NOT "${qmltest_DEFAULT_PROPERTIES}" STREQUAL "")
            set_tests_properties(${qmltest_TARGET} ${qmltest_DEFAULT_PROPERTIES})
        endif(NOT "${qmltest_UNPARSED_ARGUMENTS}" STREQUAL "")
    endif("${qmltest_NO_ADD_TEST}" STREQUAL FALSE AND NOT "${qmltest_DEFAULT_NO_ADD_TEST}" STREQUAL "TRUE")

    if("${qmltest_NO_TARGETS}" STREQUAL "FALSE")
        if(NOT "${qmltest_TARGETS}" STREQUAL "")
            foreach(TARGET ${qmltest_TARGETS})
                add_dependencies(${TARGET} ${qmltest_TARGET})
            endforeach(TARGET)
        elseif(NOT "${qmltest_DEFAULT_TARGETS}" STREQUAL "")
            foreach(TARGET ${qmltest_DEFAULT_TARGETS})
                add_dependencies(${TARGET} ${qmltest_TARGET})
            endforeach(TARGET)
        endif(NOT "${qmltest_TARGETS}" STREQUAL "")
    endif("${qmltest_NO_TARGETS}" STREQUAL "FALSE")
endmacro(add_qml_test)

add_custom_target(alltests)

add_subdirectory(qmluitests)
