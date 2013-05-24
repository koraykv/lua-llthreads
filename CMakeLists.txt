#
# A simple low-level Lua wrapper for pthreads.
#

CMAKE_MINIMUM_REQUIRED(VERSION 2.6 FATAL_ERROR)
CMAKE_POLICY(VERSION 2.6)
IF(LUAROCKS_PREFIX)
    MESSAGE(STATUS "Installing Torch through Luarocks")
    STRING(REGEX REPLACE "(.*)lib/luarocks/rocks.*" "\\1" CMAKE_INSTALL_PREFIX  "${LUAROCKS_PREFIX}")
    MESSAGE(STATUS "Prefix inferred from Luarocks: ${CMAKE_INSTALL_PREFIX}")
ENDIF()
FIND_PACKAGE(Torch REQUIRED)

SET(src src/pre_generated-llthreads.nobj.c)

SET(luasrc)


SET(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

SET(COMMON_CFLAGS "${CFLAGS}")
SET(COMMON_LDFLAGS)
SET(COMMON_LIBS)

if(WIN32)
	set(COMMON_CFLAGS "${COMMON_CFLAGS} -I${LUA_INCLUDE_DIR}")
	set(COMMON_LDFLAGS "${COMMON_LDFLAGS} ${LUA_LIBRARY}")
endif()
## MAC OSX needs extra linker flags
if(APPLE)
	set(COMMON_LDFLAGS "${COMMON_LDFLAGS} -undefined dynamic_lookup")
endif()

## find threads
set(CMAKE_THREAD_PREFER_PTHREAD TRUE)
include(FindThreads)

include(CustomMacros)

## LuaNativeObjects
include(LuaNativeObjects)

IF(USE_PRE_GENERATED_BINDINGS)
	set(LUA_LLTHREADS_SRC src/pre_generated-llthreads.nobj.c)
ELSE()
	# Generate Lua bindings.
	GenLuaNativeObjects(LUA_LLTHREADS_SRC)
ENDIF()

INCLUDE_DIRECTORIES(${Torch_SOURCE_INCLUDES})
ADD_TORCH_PACKAGE(llthreads "${src}"  "${luasrc}" "Low Level Threading")
TARGET_LINK_LIBRARIES(llthreads ${COMMON_LIBS} ${CMAKE_THREAD_LIBS_INIT})

set_target_properties(llthreads PROPERTIES PREFIX "")
add_target_properties(llthreads COMPILE_FLAGS "${COMMON_CFLAGS}")
add_target_properties(llthreads LINK_FLAGS "${LD_FLAGS} ${COMMON_LDFLAGS}")
set_target_properties(llthreads PROPERTIES OUTPUT_NAME llthreads)

