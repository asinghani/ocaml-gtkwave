# A HTTP server for GTKWave's Tcl interface
# Tested with GTKWave v3.3.116
# Requires [tcllib]
#
# Security: This does not handle any input sanitization. This server should
# only ever be run on a link-local address, Do NOT expose to an external
# network.
#
# Use: Launch gtkwave with the `-W` flag. Once the Tcl REPL launches, run
# [source server.tcl] to start the server.
package require httpd 4.1
httpd::server create HTTPD port 8015 myaddr "127.0.0.1"

HTTPD plugin dispatch ::httpd::plugin.dict_dispatch

# POST /call_menu_item Args: [item=STRING]
HTTPD uri add * /call_menu_item [list mixin {content reply.call_menu_item}]
clay::define ::reply.call_menu_item {
  method content {} {
    set formdata [dict merge [my FormData]]
    gtkwave::[dict get $formdata item]
    my puts "OK"
  }
}

# POST /add_comment_trace Args: [comment=STRING]
HTTPD uri add * /add_comment_trace [list mixin {content reply.add_comment_trace}]
clay::define ::reply.add_comment_trace {
  method content {} {
    set formdata [dict merge [my FormData]]
    gtkwave::addCommentTracesFromList [list [dict get $formdata comment]]
    gtkwave::/Edit/UnHighlight_All
    my puts "OK"
  }
}

# POST /add_wave Args: [signal=STRING]
HTTPD uri add * /add_wave [list mixin {content reply.add_wave}]
clay::define ::reply.add_wave {
  method content {} {
    set formdata [dict merge [my FormData]]
    switch -- [gtkwave::addSignalsFromList [list [dict get $formdata signal]]] {
      0 { my error 500 "Error: Failed to find signal" }
      default { my puts "OK" }
    }
    gtkwave::/Edit/UnHighlight_All
  }
}

# POST /remove_wave Args: [signal=STRING]
HTTPD uri add * /remove_wave [list mixin {content reply.remove_wave}]
clay::define ::reply.remove_wave {
  method content {} {
    set formdata [dict merge [my FormData]]
    switch -- [gtkwave::deleteSignalsFromListIncludingDuplicates [list [dict get $formdata signal]]] {
      0 { my error 500 "Error: Failed to find signal" }
      default { my puts "OK" }
    }
    gtkwave::/Edit/UnHighlight_All
  }
}

# POST /find_next_edge Args: [signal=STRING]
HTTPD uri add * /find_next_edge [list mixin {content reply.find_next_edge}]
clay::define ::reply.find_next_edge {
  method content {} {
    set formdata [dict merge [my FormData]]
    switch -- [gtkwave::highlightSignalsFromList [list [dict get $formdata signal]]] {
      0 { my error 500 "Error: Failed to find signal" }
      default { my puts "OK" }
    }
    gtkwave::findNextEdge
    gtkwave::/Edit/UnHighlight_All
  }
}

# POST /find_prev_edge Args: [signal=STRING]
HTTPD uri add * /find_prev_edge [list mixin {content reply.find_prev_edge}]
clay::define ::reply.find_prev_edge {
  method content {} {
    set formdata [dict merge [my FormData]]
    switch -- [gtkwave::highlightSignalsFromList [list [dict get $formdata signal]]] {
      0 { my error 500 "Error: Failed to find signal" }
      default { my puts "OK" }
    }
    gtkwave::findPrevEdge
    gtkwave::/Edit/UnHighlight_All
  }
}

# POST /open_tree_node Args: [node=STRING]
HTTPD uri add * /open_tree_node [list mixin {content reply.open_tree_node}]
clay::define ::reply.open_tree_node {
  method content {} {
    set formdata [dict merge [my FormData]]
    switch -- [gtkwave::forceOpenTreeNode [list [dict get $formdata node]]] {
      0 { my puts "OK" }
      1 { my error 500 "Error: failed to find node" }
      default { my error 500 "Error: unknown error" }
    }
    gtkwave::/Edit/UnHighlight_All
  }
}

# GET /get_displayed_waves (NOTE: this excludes comment and blank traces, so it does not match trace indices)
HTTPD uri add * /get_displayed_waves [list mixin {content reply.get_displayed_waves}]
clay::define ::reply.get_displayed_waves {
  method content {} {
    set totalNumTraces [gtkwave::getTotalNumTraces]
    my puts $totalNumTraces
    for {set i 0} {$i < $totalNumTraces} {incr i} {
      set traceName [gtkwave::getTraceNameFromIndex $i]
      my puts "$traceName"
    }
  }
}

# GET /get_dumpfile_name
HTTPD uri add * /get_dumpfile_name [list mixin {content reply.get_dumpfile_name}]
clay::define ::reply.get_dumpfile_name {
  method content {} {
    my puts [gtkwave::getDumpFileName]
  }
}

# GET /get_dumpfile_type (VCD/PVCD/LXT/LXT2/GHW/VZT)
HTTPD uri add * /get_dumpfile_type [list mixin {content reply.get_dumpfile_type}]
clay::define ::reply.get_dumpfile_type {
  method content {} {
    my puts [gtkwave::getDumpType]
  }
}

# GET /get_dumpfile_time_range
HTTPD uri add * /get_dumpfile_time_range [list mixin {content reply.get_dumpfile_time_range}]
clay::define ::reply.get_dumpfile_time_range {
  method content {} {
    my puts [gtkwave::getMinTime],[gtkwave::getMaxTime]
  }
}

# GET /get_all_signals
HTTPD uri add * /get_all_signals [list mixin {content reply.get_all_signals}]
clay::define ::reply.get_all_signals {
  method content {} {
    set numFacs [gtkwave::getNumFacs]
    for {set i 0} {$i < $numFacs} {incr i} {
      set facName [gtkwave::getFacName $i]
      my puts "$facName"
    }
  }
}

# GET /get_marker_position (-1 means not added)
HTTPD uri add * /get_marker_position [list mixin {content reply.get_marker_position}]
clay::define ::reply.get_marker_position {
  method content {} {
    my puts [gtkwave::getMarker]
  }
}

# POST /set_marker_position Args: [position=INT] (-1 to remove)
HTTPD uri add * /set_marker_position [list mixin {content reply.set_marker_position}]
clay::define ::reply.set_marker_position {
  method content {} {
    set formdata [dict merge [my FormData]]
    gtkwave::setMarker [list [dict get $formdata position]]
    my puts "OK"
  }
}

# POST /get_named_marker_position Args:[marker=A-Z] (-1 means not added)
HTTPD uri add * /get_named_marker_position [list mixin {content reply.get_named_marker_position}]
clay::define ::reply.get_named_marker_position {
  method content {} {
    set formdata [dict merge [my FormData]]
    my puts [gtkwave::getNamedMarker [dict get $formdata marker]]
  }
}

# POST /set_named_marker_position Args: [marker=A-Z position=INT comment=STRING] (-1 to remove)
HTTPD uri add * /set_named_marker_position [list mixin {content reply.set_named_marker_position}]
clay::define ::reply.set_named_marker_position {
  method content {} {
    set formdata [dict merge [my FormData]]
    gtkwave::setNamedMarker [dict get $formdata marker] \
      [dict get $formdata position] [dict get $formdata comment]
    my puts "OK"
  }
}

# GET /get_window_time_range
HTTPD uri add * /get_window_time_range [list mixin {content reply.get_window_time_range}]
clay::define ::reply.get_window_time_range {
  method content {} {
    my puts [gtkwave::getWindowStartTime],[gtkwave::getWindowEndTime]
  }
}

# POST /set_window_time_range Args: [start=INT end=INT]
HTTPD uri add * /set_window_time_range [list mixin {content reply.set_window_time_range}]
clay::define ::reply.set_window_time_range {
  method content {} {
    set formdata [dict merge [my FormData]]
    gtkwave::setZoomRangeTimes [dict get $formdata start] [dict get $formdata end]
    my puts "OK"
  }
}

# POST /get_signal_value_at_time Args: [signal=STRING time=INT]
HTTPD uri add * /get_signal_value_at_time [list mixin {content reply.get_signal_value_at_time}]
clay::define ::reply.get_signal_value_at_time {
  method content {} {
    gtkwave::/Edit/UnHighlight_All
    set formdata [dict merge [my FormData]]
    set signal [dict get $formdata signal]
    set time [dict get $formdata time]
    switch -- [gtkwave::addSignalsFromList [list $signal]] {
      0 { my error 500 "Error: Failed to find signal" }
      default {
        gtkwave::/Edit/Data_Format/Binary
        lassign [gtkwave::signalChangeList $signal -start_time $time -max 1] _ value
        if {$value eq ""} {
          my error 500 "Error: signal not found"
        } else {
          my puts $value
        }
        gtkwave::/Edit/Delete
        gtkwave::/Edit/UnHighlight_All
      }
    }
  }
}

# POST /get_signal_transitions Args: [signal=STRING start_time=INT end_time=INT max=INT direction=forward/backward]
HTTPD uri add * /get_signal_transitions [list mixin {content reply.get_signal_transitions}]
clay::define ::reply.get_signal_transitions {
  method content {} {
    set formdata [dict merge [my FormData]]
    set signal [dict get $formdata signal]
    set start_time [dict get $formdata start_time]
    set end_time [dict get $formdata end_time]
    set max [dict get $formdata max]
    set direction [dict get $formdata direction]

    switch -- [gtkwave::addSignalsFromList [list $signal]] {
      0 { my error 500 "Error: Failed to find signal" }
      default {
        gtkwave::/Edit/Data_Format/Binary
        set transitions [gtkwave::signalChangeList $signal -start_time $start_time \
          -end_time $end_time -max $max -dir $direction]

        if {$transitions eq ""} {
          my error 500 "Error: signal not found"
        } else {
          foreach {time value} $transitions {
            my puts "$time,$value"
          }
        }
        gtkwave::/Edit/Delete
        gtkwave::/Edit/UnHighlight_All
      }
    }

  }
}

# POST /reload_file
HTTPD uri add * /reload_file [list mixin {content reply.reload_file}]
clay::define ::reply.reload_file {
  method content {} {
    my puts [gtkwave::getWindowStartTime],[gtkwave::getWindowEndTime]
  }
}

# POST /highlight_signal Args: [signal=STRING]
HTTPD uri add * /highlight_signal [list mixin {content reply.highlight_signal}]
clay::define ::reply.highlight_signal {
  method content {} {
    set formdata [dict merge [my FormData]]
    switch -- [gtkwave::highlightSignalsFromList [list [dict get $formdata signal]]] {
      0 { my error 500 "Error: Failed to find signal" }
      default { my puts "OK" }
    }
  }
}

# POST /unhighlight_all
HTTPD uri add * /unhighlight_all [list mixin {content reply.unhighlight_all}]
clay::define ::reply.unhighlight_all {
  method content {} {
    gtkwave::/Edit/UnHighlight_All
    my puts "OK"
  }
}

# POST /set_filter_directory Args: [path=STRING]
HTTPD uri add * /set_filter_directory [list mixin {content reply.set_filter_directory}]
clay::define ::reply.set_filter_directory {
  method content {} {
    set formdata [dict merge [my FormData]]
    cd [list [dict get $formdata path]]
    my puts "OK"
  }
}

# POST /load_translate_file Args: [filename=STRING] (Path can be relative to filter directory or absolute)
HTTPD uri add * /load_translate_file [list mixin {content reply.load_translate_file}]
clay::define ::reply.load_translate_file {
  method content {} {
    set formdata [dict merge [my FormData]]
    switch -- [gtkwave::setCurrentTranslateFile [list [dict get $formdata filename]]] {
      0 { my error 500 "Error: Failed to load file" }
      default { my puts "OK" }
    }
  }
}

# POST /load_translate_process_file Args: [filename=STRING] (Path can be relative to filter directory or absolute)
HTTPD uri add * /load_translate_process_file [list mixin {content reply.load_translate_process_file}]
clay::define ::reply.load_translate_process_file {
  method content {} {
    set formdata [dict merge [my FormData]]
    switch -- [gtkwave::setCurrentTranslateProc [list [dict get $formdata filename]]] {
      0 { my error 500 "Error: Failed to load file" }
      default { my puts "OK" }
    }
  }
}

# POST /load_transaction_process_file Args: [filename=STRING] (Path can be relative to filter directory or absolute)
HTTPD uri add * /load_transaction_process_file [list mixin {content reply.load_transaction_process_file}]
clay::define ::reply.load_transaction_process_file {
  method content {} {
    set formdata [dict merge [my FormData]]
    switch -- [gtkwave::setCurrentTranslateTransProc [list [dict get $formdata filename]]] {
      0 { my error 500 "Error: Failed to load file" }
      default { my puts "OK" }
    }
  }
}

# POST /apply_translate_file Args: [signal=STRING filename=STRING] (Path can be relative to filter directory or absolute)
HTTPD uri add * /apply_translate_file [list mixin {content reply.apply_translate_file}]
clay::define ::reply.apply_translate_file {
  method content {} {
    set formdata [dict merge [my FormData]]
    set filterIndex [gtkwave::setCurrentTranslateFile [list [dict get $formdata filename]]]
    switch -- $filterIndex {
      0 { my error 500 "Error: Failed to load file" }
      default { 
        switch -- [gtkwave::highlightSignalsFromList [list [dict get $formdata signal]]] {
          0 { my error 500 "Error: Failed to find signal" }
          default { 
            gtkwave::installFileFilter $filterIndex
            gtkwave::/Edit/UnHighlight_All
            my puts "OK"
          }
        }
      }
    }
  }
}

# POST /apply_translate_process_file Args: [signal=STRING filename=STRING] (Path can be relative to filter directory or absolute)
HTTPD uri add * /apply_translate_process_file [list mixin {content reply.apply_translate_process_file}]
clay::define ::reply.apply_translate_process_file {
  method content {} {
    set formdata [dict merge [my FormData]]
    set filterIndex [gtkwave::setCurrentTranslateFile [list [dict get $formdata filename]]]
    switch -- $filterIndex {
      0 { my error 500 "Error: Failed to load file" }
      default { 
        switch -- [gtkwave::highlightSignalsFromList [list [dict get $formdata signal]]] {
          0 { my error 500 "Error: Failed to find signal" }
          default { 
            gtkwave::installProcFilter $filterIndex
            gtkwave::/Edit/UnHighlight_All
            my puts "OK"
          }
        }
      }
    }
  }
}

# POST /apply_transaction_process_file Args: [signal=STRING filename=STRING] (Path can be relative to filter directory or absolute)
HTTPD uri add * /apply_transaction_process_file [list mixin {content reply.apply_transaction_process_file}]
clay::define ::reply.apply_transaction_process_file {
  method content {} {
    set formdata [dict merge [my FormData]]
    set filterIndex [gtkwave::setCurrentTranslateTransProc [list [dict get $formdata filename]]]
    switch -- $filterIndex {
      0 { my error 500 "Error: Failed to load file" }
      default { 
        switch -- [gtkwave::highlightSignalsFromList [list [dict get $formdata signal]]] {
          0 { my error 500 "Error: Failed to find signal" }
          default { 
            gtkwave::installTransFilter $filterIndex
            gtkwave::/Edit/UnHighlight_All
            my puts "OK"
          }
        }
      }
    }
  }
}

puts [list Listening on :[HTTPD port_listening]]
vwait forever
