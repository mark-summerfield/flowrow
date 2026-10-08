# Copyright © 2026 Mark Summerfield. All rights reserved.

namespace eval flowrow {}

oo::class create flowrow::Row {
    variable Frame
    variable ShowAllToolbars
    variable Toolbars ;# dict of toolbar → 0|1 hide|show; insertion ordered
    variable ToobarsVars ;# arrays are unordered ∴ the dict above *needed*
    variable Width
    variable RefreshToolbarsId
    variable Menu
}

# name, e.g., .mainframe.toolbar; _must_ be managed by grid. 
oo::define flowrow::Row constructor name {
    set Frame [ttk::frame $name -relief raised]
    set ShowAllToolbars 1
    set Toolbars [dict create] ;# ttk:frame keys; 0|1 → hide|show values
    array set ToobarsVars {} ;# ditto (but unordered) needed for menu
    set Width 0
    set RefreshToolbarsId ""
    set Menu ""
    bind $Frame <Configure> [callback OnConfigure %w]
}

oo::define flowrow::Row method frame {} { return $Frame }
oo::define flowrow::Row method toolbars {} { return $Toolbars }

oo::define flowrow::Row method refresh {} {
    after cancel $RefreshToolbarsId
    my Refresh
}

oo::define flowrow::Row method add_toolbar toolbar {
    dict set Toolbars $toolbar 1
    set ToobarsVars($toolbar) 1
    $toolbar configure -relief raised -borderwidth 3
    my refresh
}

# If hiding > 1 toolbars use hide_toolbars instead.
oo::define flowrow::Row method show_toolbar {toolbar {show 1}} {
    dict set Toolbars $toolbar $show
    set ToobarsVars($toolbar) $show
    if {!$show} { set ShowAllToolbars 0 }
    if {![my HasVisibleToolbars]} {
        grid remove $Frame
    } else {
        my refresh
    }
}

oo::define flowrow::Row method hide_toolbars args {
    foreach toolbar $args {
        dict set Toolbars $toolbar 0
        set ToobarsVars($toolbar) 0
    }
    set ShowAllToolbars 0
    if {[llength $args] == [dict size $Toolbars]} {
        grid remove $Frame
    } else {
        my refresh
    }
}

# Normally simply hide using: show_toolbar $toolbar 0
oo::define flowrow::Row method remove_toolbar toolbar {
    dict unset Toolbars $toolbar
    array unset ToobarsVars $toolbar
    my refresh
}

oo::define flowrow::Row method HasVisibleToolbars {} {
    dict for {toolbar show} $Toolbars { if {$show} { return 1 } }
    return 0
}

oo::define flowrow::Row method show {{show 1}} {
    set ShowAllToolbars $show
    my OnShowHideAll
}

oo::define flowrow::Row method new_menu {parent_menu names} {
    if {$Menu ne ""} return
    set accels [lreverse [split 123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ ""]]
    set Menu $parent_menu._flowrow
    menu $Menu
    $parent_menu add cascade -menu $Menu -label Toolbars -underline 0
    $Menu add checkbutton -variable [my varname ShowAllToolbars] \
            -label "0 All Toolbars" -underline 0 \
            -offvalue 0 -onvalue 1 -command [callback OnShowHideAll]
    $Menu add separator
    dict for {toolbar show} $Toolbars {
        set ToobarsVars($toolbar) $show
        set prefix ""
        set underline {}
        if {[llength $accels]} {
            set prefix "[lpop accels] "
            set underline 0
        }
        $Menu add checkbutton \
                -variable [my varname ToobarsVars]($toolbar) \
                -label ${prefix}[lpop names 0] -underline $underline \
                -offvalue 0 -onvalue 1 -command [callback OnMenu]
    }
}

oo::define flowrow::Row method OnShowHideAll {} {
    foreach toolbar [dict keys $Toolbars] {
        dict set Toolbars $toolbar $ShowAllToolbars
        set ToobarsVars($toolbar) $ShowAllToolbars
    }
    if {$ShowAllToolbars} {
        grid $Frame
        my refresh
    } else {
        grid remove $Frame
    }
}

oo::define flowrow::Row method OnMenu {} {
    set show 0 ;# the loop is also used to update the Toolbars dict
    foreach toolbar [array names ToobarsVars] {
        dict set Toolbars $toolbar $ToobarsVars($toolbar)
        if {$ToobarsVars($toolbar)} { set show 1 }
    }
    if {$show && !$ShowAllToolbars} { grid $Frame }
    my refresh
}

oo::define flowrow::Row method OnConfigure width {
    if {$width != $Width} {
        after cancel $RefreshToolbarsId
        set RefreshToolbarsId [after 100 [callback Refresh]]
    }
}

oo::define flowrow::Row method Refresh {} {
    set Width [winfo width $Frame]
    if {$Width <= 1} return
    dict for {toolbar _} $Toolbars { grid forget $toolbar }
    lassign [my GetToolbarData] toolbars column_width
    set size [llength $toolbars]
    if {$size} {
        set width 0
        set row 0
        set column 0
        dict for {toolbar tbwidth} $toolbars {
            if {$width + $tbwidth >= $Width} {
                set width 0
                set column 0
                incr row
            }
            set span [expr {int(round($tbwidth / $column_width))}]
            grid $toolbar -row $row -column $column -columnspan $span \
                    -sticky w
            foreach widget [winfo children $toolbar] {
                pack $widget -side left
            }
            incr column $span
            incr width $tbwidth
        }
    } else {
        grid remove $Frame
    }
    set ShowAllToolbars [expr {$size == [llength $Toolbars]}]
}

oo::define flowrow::Row method GetToolbarData {} {
    set column_width -1
    set toolbars [dict create] ;# key=toolbar value=tb_width
    dict for {toolbar show} $Toolbars {
        set tbwidth 0
        if {$show} {
            foreach widget [winfo children $toolbar] {
                set width [winfo reqwidth $widget]
                incr tbwidth $width
                if {$column_width == -1 || $column_width > $width} {
                    set column_width $width
                }
            }
            incr tbwidth 6 ;# allow for relief border
            dict set toolbars $toolbar $tbwidth
        }
    }
    list $toolbars $column_width
}
