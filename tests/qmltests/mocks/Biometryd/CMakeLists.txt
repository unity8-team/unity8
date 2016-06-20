include_directories(
    ${CMAKE_CURRENT_BINARY_DIR}
)

set(MOCK_BIOMETRYD_SOURCES
    plugin.cpp
    MockDevice.cpp
    MockFingerprintReader.cpp
    MockObserver.cpp
    MockOperation.cpp
    MockService.cpp
    MockTemplateStore.cpp
    MockUser.cpp
)

add_library(MockBiometryd MODULE ${MOCK_BIOMETRYD_SOURCES})

qt5_use_modules(MockBiometryd Qml Quick Core)

add_usc_mock(Biometryd 0.0 Biometryd TARGETS MockBiometryd)
