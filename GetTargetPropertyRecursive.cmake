
function(get_target_property_recursive outputvar target property)
    get_target_property(_ept_li ${target} ${property})
    get_target_property(_ept_deps ${target} LINK_LIBRARIES)
    foreach(_ept_ll ${_ept_deps})
        if(TARGET ${_ept_ll})
            get_target_property_recursive(_ept_out ${_ept_ll} ${property})
            list(APPEND _ept_li ${_ept_out})
        endif()
    endforeach()
    set(${outputvar} ${_ept_li} PARENT_SCOPE)
endfunction()