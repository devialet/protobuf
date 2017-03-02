include(GNUInstallDirs)

set(_libraries libprotobuf-lite libprotobuf )
if( TARGET libprotoc )
  list( APPEND _libraries libprotoc )
endif()

set(_executables)
if( TARGET protoc )
  list( APPEND _executables protoc )
endif()

set_property(TARGET ${_libraries}
  PROPERTY INTERFACE_INCLUDE_DIRECTORIES
  $<BUILD_INTERFACE:${protobuf_source_dir}/src>
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)
install(TARGETS ${_libraries} EXPORT protobuf-targets
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT ${_library}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT ${_library}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT ${_library})

if( _executables )
  install(TARGETS ${_executables} EXPORT protoc-targets
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT protoc)
endif()

file(STRINGS extract_includes.bat.in _extract_strings
  REGEX "^copy")
foreach(_extract_string ${_extract_strings})
  string(REPLACE "copy \${PROTOBUF_SOURCE_WIN32_PATH}\\" ""
    _extract_string ${_extract_string})
  string(REPLACE "\\" "/" _extract_string ${_extract_string})
  string(REGEX MATCH "^[^ ]+"
    _extract_from ${_extract_string})
  string(REGEX REPLACE "^${_extract_from} ([^$]+)" "\\1"
    _extract_to ${_extract_string})
  get_filename_component(_extract_from "${protobuf_SOURCE_DIR}/${_extract_from}" ABSOLUTE)
  get_filename_component(_extract_name ${_extract_to} NAME)
  get_filename_component(_extract_to ${_extract_to} PATH)
  string(REPLACE "include/" "${CMAKE_INSTALL_INCLUDEDIR}/"
    _extract_to "${_extract_to}")
  if(EXISTS "${_extract_from}")
    install(FILES "${_extract_from}"
      DESTINATION "${_extract_to}"
      COMPONENT protobuf-headers
      RENAME "${_extract_name}")
  else()
    message(AUTHOR_WARNING "The file \"${_extract_from}\" is listed in "
      "\"${protobuf_SOURCE_DIR}/cmake/extract_includes.bat.in\" "
      "but there not exists. The file will not be installed.")
  endif()
endforeach()

# Internal function for parsing auto tools scripts
function(_protobuf_auto_list FILE_NAME VARIABLE)
  file(STRINGS ${FILE_NAME} _strings)
  set(_list)
  foreach(_string ${_strings})
    set(_found)
    string(REGEX MATCH "^[ \t]*${VARIABLE}[ \t]*=[ \t]*" _found "${_string}")
    if(_found)
      string(LENGTH "${_found}" _length)
      string(SUBSTRING "${_string}" ${_length} -1 _draft_list)
      foreach(_item ${_draft_list})
        string(STRIP "${_item}" _item)
        list(APPEND _list "${_item}")
      endforeach()
    endif()
  endforeach()
  set(${VARIABLE} ${_list} PARENT_SCOPE)
endfunction()

# Install well-known type proto files
_protobuf_auto_list("../src/Makefile.am" nobase_dist_proto_DATA)
foreach(_file ${nobase_dist_proto_DATA})
  get_filename_component(_file_from "../src/${_file}" ABSOLUTE)
  get_filename_component(_file_name ${_file} NAME)
  get_filename_component(_file_path ${_file} PATH)
  if(EXISTS "${_file_from}")
    install(FILES "${_file_from}"
      DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${_file_path}"
      COMPONENT protobuf-protos
      RENAME "${_file_name}")
  else()
    message(AUTHOR_WARNING "The file \"${_file_from}\" is listed in "
      "\"${protobuf_SOURCE_DIR}/../src/Makefile.am\" as nobase_dist_proto_DATA "
      "but there not exists. The file will not be installed.")
  endif()
endforeach()

# Install configuration
set(_cmakedir_desc " directory relative to CMAKE_INSTALL to install the cmake configuration files")
if(NOT MSVC)
  set(PROTOBUF_INSTALL_CMAKEDIR "${CMAKE_INSTALL_LIBDIR}/cmake/protobuf" CACHE STRING "Protobuf ${_cmakedir_desc}")
  set(PROTOC_INSTALL_CMAKEDIR "${CMAKE_INSTALL_LIBDIR}/cmake/protoc" CACHE STRING "Protoc ${_cmakedir_desc}")
else()
  set(PROTOBUF_INSTALL_CMAKEDIR "cmake" CACHE STRING "Protobuf ${_cmakedir_desc}")
  set(PROTOC_INSTALL_CMAKEDIR "cmake" CACHE STRING "Protoc ${_cmakedir_desc}")
endif()
mark_as_advanced(CMAKE_INSTALL_CMAKEDIR)

configure_file(protobuf-config.cmake.in
  ${PROTOBUF_INSTALL_CMAKEDIR}/protobuf-config.cmake @ONLY)
configure_file(protobuf-config-version.cmake.in
  ${PROTOBUF_INSTALL_CMAKEDIR}/protobuf-config-version.cmake @ONLY)
configure_file(protobuf-module.cmake.in
  ${PROTOBUF_INSTALL_CMAKEDIR}/protobuf-module.cmake @ONLY)
configure_file(protobuf-options.cmake
  ${PROTOBUF_INSTALL_CMAKEDIR}/protobuf-options.cmake @ONLY)

if( _executables )
  configure_file(protoc-config.cmake.in
    ${PROTOC_INSTALL_CMAKEDIR}/protoc-config.cmake @ONLY)
endif()

# Allows the build directory to be used as a find directory.
export(TARGETS ${_libraries} ${_executables}
  NAMESPACE protobuf::
  FILE ${PROTOBUF_INSTALL_CMAKEDIR}/protobuf-targets.cmake
)

install(EXPORT protobuf-targets
  DESTINATION "${PROTOBUF_INSTALL_CMAKEDIR}"
  NAMESPACE protobuf::
  COMPONENT protobuf-export)

install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${PROTOBUF_INSTALL_CMAKEDIR}/
  DESTINATION "${PROTOBUF_INSTALL_CMAKEDIR}"
  COMPONENT protobuf-export
  PATTERN protobuf-targets.cmake EXCLUDE
)

if( _executables )
  install(EXPORT protoc-targets
    DESTINATION "${PROTOC_INSTALL_CMAKEDIR}"
    NAMESPACE protobuf::
    COMPONENT protoc-export)

  install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${PROTOC_INSTALL_CMAKEDIR}/
    DESTINATION "${PROTOC_INSTALL_CMAKEDIR}"
    COMPONENT protoc-export
  )
endif()

option(protobuf_INSTALL_EXAMPLES "Install the examples folder" OFF)
if(protobuf_INSTALL_EXAMPLES)
  install(DIRECTORY ../examples/ DESTINATION examples
    COMPONENT protobuf-examples)
endif()
