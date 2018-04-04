file(GLOB_RECURSE USB4JAVA_SOURCES *.c)

option(LINK_UDEV_SHARED "link udev as a shared library" OFF)

add_library(usb4java SHARED ${USB4JAVA_SOURCES})

if(LINK_UDEV_SHARED)
  target_link_libraries(usb4java ${LibUsb_LIBRARIES} udev)
  set(GCC_NO_UNDEFINED_SYMBOLS "-Wl,--no-undefined")
else()
  target_link_libraries(usb4java ${LibUsb_LIBRARIES})
endif()
if(CMAKE_COMPILER_IS_GNUCC)
  set_target_properties(usb4java PROPERTIES LINK_FLAGS "-static-libgcc ${GCC_NO_UNDEFINED_SYMBOLS}")
endif()
install(TARGETS usb4java DESTINATION lib)
