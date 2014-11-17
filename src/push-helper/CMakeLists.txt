set(push-helper_SRCS
    main.cpp
)

add_executable(push-helper ${push-helper_SRCS})

qt5_use_modules(push-helper Core)

if(CLICK_MODE)
  install(TARGETS push-helper DESTINATION ${BIN_DIR})
else()
  install(TARGETS push-helper RUNTIME DESTINATION bin)
endif()
