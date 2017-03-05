
include(CMakeDependentOption)

function(setup_sanitize prefix)
if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")

    # option to turn sanitize on/off
    option(${prefix}_SANITIZE ON)

    # options for individual sanitizers - contingent on sanitize on/off
    cmake_dependent_option(${prefix}_ASAN  "" ON "${prefix}_SANITIZE" OFF)
    cmake_dependent_option(${prefix}_TSAN  "" ON "${prefix}_SANITIZE" OFF)
    cmake_dependent_option(${prefix}_MSAN  "" ON "${prefix}_SANITIZE" OFF)
    cmake_dependent_option(${prefix}_UBSAN "" ON "${prefix}_SANITIZE" OFF)

    # compile flags
    set(${prefix}_ASAN_CFLAGS "-O1 -g -fsanitize=address -fno-omit-frame-pointer -fno-optimize-sibling-calls" CACHE STRING "compile flags for clang address sanitizer: https://clang.llvm.org/docs/AddressSanitizer.html")
    set(${prefix}_TSAN_CFLAGS "-O1 -g -fsanitize=thread -fno-omit-frame-pointer" CACHE STRING "compile flags for clang address sanitizer: https://clang.llvm.org/docs/ThreadSanitizer.html")
    set(${prefix}_MSAN_CFLAGS "-O1 -g -fsanitize=memory -fsanitize-memory-track-origins -fno-omit-frame-pointer -fno-optimize-sibling-calls" CACHE STRING "compile flags for clang address sanitizer: https://clang.llvm.org/docs/MemorySanitizer.html")
    set(${prefix}_UBSAN_CFLAGS "-g -fsanitize=undefined" CACHE STRING "compile flags for clang address sanitizer: https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html")
    # the flags are strings; we need to separate them into a list
    # to prevent cmake from quoting them when passing to the targets
    separate_arguments(${prefix}_ASAN_CFLAGS_SEP  UNIX_COMMAND ${${prefix}_ASAN_CFLAGS})
    separate_arguments(${prefix}_TSAN_CFLAGS_SEP  UNIX_COMMAND ${${prefix}_TSAN_CFLAGS})
    separate_arguments(${prefix}_MSAN_CFLAGS_SEP  UNIX_COMMAND ${${prefix}_MSAN_CFLAGS})
    separate_arguments(${prefix}_UBSAN_CFLAGS_SEP UNIX_COMMAND ${${prefix}_UBSAN_CFLAGS})

    # linker flags
    set(${prefix}_ASAN_LFLAGS "-g -fsanitize=address" CACHE STRING "linker flags for clang address sanitizer: https://clang.llvm.org/docs/AddressSanitizer.html")
    set(${prefix}_TSAN_LFLAGS "-g -fsanitize=thread" CACHE STRING "linker flags for clang address sanitizer: https://clang.llvm.org/docs/ThreadSanitizer.html")
    set(${prefix}_MSAN_LFLAGS "-g -fsanitize=memory" CACHE STRING "linker flags for clang address sanitizer: https://clang.llvm.org/docs/MemorySanitizer.html")
    set(${prefix}_UBSAN_LFLAGS "-g -fsanitize=undefined" CACHE STRING "linker flags for clang address sanitizer: https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html")
    # the flags are strings; we need to separate them into a list
    # to prevent cmake from quoting them when passing to the targets
    separate_arguments(${prefix}_ASAN_LFLAGS_SEP  UNIX_COMMAND ${${prefix}_ASAN_LFLAGS})
    separate_arguments(${prefix}_TSAN_LFLAGS_SEP  UNIX_COMMAND ${${prefix}_TSAN_LFLAGS})
    separate_arguments(${prefix}_MSAN_LFLAGS_SEP  UNIX_COMMAND ${${prefix}_MSAN_LFLAGS})
    separate_arguments(${prefix}_UBSAN_LFLAGS_SEP UNIX_COMMAND ${${prefix}_UBSAN_LFLAGS})

    # run environment
    string(REGEX REPLACE "([0-9]+\\.[0-9]+).*" "\\1" LLVM_VERSION "${CMAKE_CXX_COMPILER_VERSION}")
    find_program(LLVM_SYMBOLIZER llvm-symbolizer
        NAMES llvm-symbolizer-${LLVM_VERSION} llvm-symbolizer
        DOC "symbolizer to use in sanitize tools")
    set(${prefix}_ASAN_RENV  "env ASAN_SYMBOLIZER_PATH=${LLVM_SYMBOLIZER} ASAN_OPTIONS=symbolize=1" CACHE STRING "run environment for clang address sanitizer: https://clang.llvm.org/docs/AddressSanitizer.html")
    set(${prefix}_TSAN_RENV  "env TSAN_SYMBOLIZER_PATH=${LLVM_SYMBOLIZER} TSAN_OPTIONS=symbolize=1" CACHE STRING "run environment for clang thread sanitizer: https://clang.llvm.org/docs/ThreadSanitizer.html")
    set(${prefix}_MSAN_RENV  "env MSAN_SYMBOLIZER_PATH=${LLVM_SYMBOLIZER} MSAN_OPTIONS=symbolize=1" CACHE STRING "run environment for clang memory sanitizer: https://clang.llvm.org/docs/MemorySanitizer.html")
    set(${prefix}_UBSAN_RENV "env UBSAN_SYMBOLIZER_PATH=${LLVM_SYMBOLIZER} UBSAN_OPTIONS='symbolize=1 print_stacktrace=1'" CACHE STRING "run environment for clang address sanitizer: https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html")
endif()
endfunction()


function(sanitize_get_target_command name prefix which_sanitizer output)
    if("${which_sanitizer}" STREQUAL ASAN)
    elseif("${which_sanitizer}" STREQUAL TSAN)
    elseif("${which_sanitizer}" STREQUAL MSAN)
    elseif("${which_sanitizer}" STREQUAL UBSAN)
    else()
        message(FATAL_ERROR "the sanitizer must be one of: ASAN, TSAN, MSAN, UBSAN")
    endif()
    set(${output} ${${prefix}_${which_sanitizer}_RENV} ${name})
endfunction()


function(sanitize_target name prefix)
    set(options0arg
        LIBRARY
        EXECUTABLE
    )
    set(options1arg
        OUTPUT_TARGET_NAMES
    )
    set(optionsnarg
        SOURCES
        INC_DIRS
        LIBS
        LIB_DIRS
    )
    cmake_parse_arguments(_c4st "${options0arg}" "${options1arg}" "${optionsnarg}" ${ARGN})

    if(TARGET sanitize)
    else()
        add_custom_target(sanitize)
    endif()
    if(TARGET asan)
    else()
        add_custom_target(asan)
        add_dependencies(sanitize asan)
    endif()
    if(TARGET msan)
    else()
        add_custom_target(msan)
        add_dependencies(sanitize msan)
    endif()
    if(TARGET tsan)
    else()
        add_custom_target(tsan)
        add_dependencies(sanitize tsan)
    endif()
    if(TARGET ubsan)
    else()
        add_custom_target(ubsan)
        add_dependencies(sanitize ubsan)
    endif()

    set(targets)

    # https://clang.llvm.org/docs/AddressSanitizer.html
    if(${prefix}_ASAN)
        if(${_c4st_LIBRARY})
            add_library(${name}-asan EXCLUDE_FROM_ALL ${_c4st_SOURCES})
        elseif(${_c4st_EXECUTABLE})
            add_executable(${name}-asan EXCLUDE_FROM_ALL ${_c4st_SOURCES})
        endif()
        list(APPEND targets ${name}-asan)
        target_include_directories(${name}-asan PUBLIC ${_c4st_INC_DIRS})
        set(_real_libs)
        foreach(_l ${_c4st_LIBS})
            if(TARGET ${_l}-asan)
                list(APPEND _real_libs ${_l}-asan)
            else()
                list(APPEND _real_libs ${_l})
            endif()
        endforeach()
        target_link_libraries(${name}-asan PUBLIC ${_real_libs})
        target_compile_options(${name}-asan PUBLIC ${${prefix}_ASAN_CFLAGS_SEP})
        # http://stackoverflow.com/questions/25043458/does-cmake-have-something-like-target-link-options
        target_link_libraries(${name}-asan PUBLIC ${${prefix}_ASAN_LFLAGS_SEP})
        add_dependencies(asan ${name}-asan)
    endif()

    # https://clang.llvm.org/docs/ThreadSanitizer.html
    if(${prefix}_TSAN)
        if(${_c4st_LIBRARY})
            add_library(${name}-tsan EXCLUDE_FROM_ALL ${_c4st_SOURCES})
        elseif(${_c4st_EXECUTABLE})
            add_executable(${name}-tsan EXCLUDE_FROM_ALL ${_c4st_SOURCES})
        endif()
        list(APPEND targets ${name}-tsan)
        target_include_directories(${prefix}-tsan PUBLIC ${_c4st_INC_DIRS})
        set(_real_libs)
        foreach(_l ${_c4st_LIBS})
            if(TARGET ${_l}-tsan)
                list(APPEND _real_libs ${_l}-tsan)
            else()
                list(APPEND _real_libs ${_l})
            endif()
        endforeach()
        target_link_libraries(${name}-tsan PUBLIC ${_real_libs})
        target_compile_options(${name}-tsan PUBLIC ${${prefix}_TSAN_CFLAGS_SEP})
        # http://stackoverflow.com/questions/25043458/does-cmake-have-something-like-target-link-options
        target_link_libraries(${name}-tsan PUBLIC ${${prefix}_TSAN_LFLAGS_SEP})
        add_dependencies(tsan ${name}-tsan)
    endif()

    # https://clang.llvm.org/docs/MemorySanitizer.html
    if(${prefix}_MSAN)
        if(${_c4st_LIBRARY})
            add_library(${name}-msan EXCLUDE_FROM_ALL ${_c4st_SOURCES})
        elseif(${_c4st_EXECUTABLE})
            add_executable(${name}-msan EXCLUDE_FROM_ALL ${_c4st_SOURCES})
        endif()
        list(APPEND targets ${name}-msan)
        target_include_directories(${prefix}-msan PUBLIC ${_c4st_INC_DIRS})
        set(_real_libs)
        foreach(_l ${_c4st_LIBS})
            if(TARGET ${_l}-msan)
                list(APPEND _real_libs ${_l}-msan)
            else()
                list(APPEND _real_libs ${_l})
            endif()
        endforeach()
        target_link_libraries(${name}-msan PUBLIC ${_real_libs})
        target_compile_options(${name}-msan PUBLIC ${${prefix}_MSAN_CFLAGS_SEP})
        # http://stackoverflow.com/questions/25043458/does-cmake-have-something-like-target-link-options
        target_link_libraries(${name}-msan PUBLIC ${${prefix}_MSAN_LFLAGS_SEP})
        add_dependencies(msan ${name}-msan)
    endif()

    # https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html
    if(${prefix}_UBSAN)
        if(${_c4st_LIBRARY})
            add_library(${name}-ubsan EXCLUDE_FROM_ALL ${_c4st_SOURCES})
        elseif(${_c4st_EXECUTABLE})
            add_executable(${name}-ubsan EXCLUDE_FROM_ALL ${_c4st_SOURCES})
        endif()
        list(APPEND targets ${name}-ubsan)
        target_include_directories(${prefix}-ubsan PUBLIC ${_c4st_INC_DIRS})
        set(_real_libs)
        foreach(_l ${_c4st_LIBS})
            if(TARGET ${_l}-ubsan)
                list(APPEND _real_libs ${_l}-ubsan)
            else()
                list(APPEND _real_libs ${_l})
            endif()
        endforeach()
        target_link_libraries(${name}-ubsan PUBLIC ${_real_libs})
        target_compile_options(${name}-ubsan PUBLIC ${${prefix}_UBSAN_CFLAGS_SEP})
        # http://stackoverflow.com/questions/25043458/does-cmake-have-something-like-target-link-options
        target_link_libraries(${name}-ubsan PUBLIC ${${prefix}_UBSAN_LFLAGS_SEP})
        add_dependencies(ubsan ${name}-ubsan)
    endif()

    if(_c4st_OUTPUT_TARGET_NAMES)
        set(${_c4st_OUTPUT_TARGET_NAMES} ${targets} PARENT_SCOPE)
    endif()
endfunction()