open! Core
open! Async

type t

val create : ?host:string -> port:int -> unit -> t

(** Call the given menu item (given as a list of strings) *)
val call_menu_item : path:string list -> t -> unit Deferred.Or_error.t

(** Add a comment trace at the highlighted location or the bottom of the wave
    list *)
val add_comment_trace : comment:string -> t -> unit Deferred.Or_error.t

(** Add the given signal as a wave. If not specified, [format] defaults to Hex,
    and [color] defaults to the GTKwave default signal color *)
val add_wave
  :  ?color:Wave_color.t
  -> ?format:Wave_format.t
  -> signal:string
  -> t
  -> unit Deferred.Or_error.t

(** Remove all copies of the given signal if they have been added as waves *)
val remove_wave : signal:string -> t -> unit Deferred.Or_error.t

(** If the given signal is added as a wave, move the primary marker to the next
    edge of the signal *)
val find_next_edge : signal:string -> t -> unit Deferred.Or_error.t

(** If the given signal is added as a wave, move the primary marker to the
    previous edge of the signal *)
val find_prev_edge : signal:string -> t -> unit Deferred.Or_error.t

(** Open the given path in the SST window *)
val open_tree_node : node:string -> t -> unit Deferred.Or_error.t

(** Get a list of the waves currently being displayed. The ordering is not
    guaranteed due to the presence of comment traces, blank traces, and
    translation filters *)
val get_displayed_waves : t -> string list Deferred.Or_error.t

(** Get the name of the currently open file *)
val get_dumpfile_name : t -> string Deferred.Or_error.t

(** Get the file format of the currently open file *)
val get_dumpfile_type : t -> string Deferred.Or_error.t

(** Get the time range spanned by the currently open file *)
val get_dumpfile_time_range : t -> (int * int) Deferred.Or_error.t

(** Get a list of all signals in the currently open file *)
val get_all_signals : t -> string list Deferred.Or_error.t

(** Get the location of the primary marker, if it is placed *)
val get_primary_marker_position : t -> int option Deferred.Or_error.t

(** Set the location of the primary marker, or pass None to remove it *)
val set_primary_marker_position : position:int option -> t -> unit Deferred.Or_error.t

(** Get the location of the given indexed marker, or None if it doesn't exist.
    Valid marker indices are 0-25, inclusive. This does not affect the primary
    marker, which is distinct from the named markers *)
val get_named_marker_position : index:int -> t -> int option Deferred.Or_error.t

(** Set the location of the given indexed marker, or pass None to remove it.
    Optionally include a comment to be displayed at the top of the marker.
    Valid marker indices are 0-25, inclusive. This does not affect the primary
    marker, which is distinct from the named markers *)
val set_named_marker_position
  :  ?comment:string
  -> index:int
  -> position:int option
  -> t
  -> unit Deferred.Or_error.t

(** Configure all named markers, removing any existing ones. Markers are
    provided as a list of tuples of (position, optional comment). This does not
    affect the primary marker, which is distinct from the named markers *)
val set_all_named_markers
  :  markers:(int * string option) list
  -> t
  -> unit Deferred.Or_error.t

(** Get the time range currently visible in the window *)
val get_window_time_range : t -> (int * int) Deferred.Or_error.t

(** Set the time range visible in the window *)
val set_window_time_range : start:int -> end_:int -> t -> unit Deferred.Or_error.t

(** Get the value of a signal at the given time. This is done by adding the
    signal, setting it as binary, looking up the signal value, then removing
    it. The signal is attempted to be formatted as 4-state binary (0/1/X/Z). *)
val get_signal_value_at_time
  :  signal:string
  -> time:int
  -> t
  -> string Deferred.Or_error.t

(** Get the transitions of a signal in the given time span. This is done by
    adding the signal, setting it as binary, looking up the signal value, then
    removing it. The signal is attempted to be formatted as 4-state binary
    (0/1/X/Z), and returned as a list of (time, value) tuples. *)
val get_signal_transitions
  :  ?max:int
  -> ?direction:[ `Backward | `Forward ]
  -> signal:string
  -> start_time:int
  -> end_time:int
  -> t
  -> (int * string) list Deferred.Or_error.t

(** Reload the currently open file *)
val reload_file : t -> unit Deferred.Or_error.t

(** Highlight the given signal. This will not un-highlight other
    already-highlighted signals *)
val highlight_signal : signal:string -> t -> unit Deferred.Or_error.t

(** Un-highlight all highlighted signals *)
val unhighlight_all : t -> unit Deferred.Or_error.t

(** Set the base directory to load translation and transaction filters from. *)
val set_filter_directory : path:string -> t -> unit Deferred.Or_error.t

(** Load the given translation file (enum). This will add it to the translation
    file list when selecting in the GUI. *)
val load_translate_file : filename:string -> t -> unit Deferred.Or_error.t

(** Load the given translation process (single signal filter). This will add it
    to the translation process list when selecting in the GUI. *)
val load_translate_process_file : filename:string -> t -> unit Deferred.Or_error.t

(** Load the given transaction process (multiple signal filter). This will add
    it to the transaction process list when selecting in the GUI. *)
val load_transaction_process_file : filename:string -> t -> unit Deferred.Or_error.t

(** Apply the given translation file (enum) to the specified signal. This will
    also load the file (and add it to the list in the GUI) if it is not already
    loaded. *)
val apply_translate_file
  :  signal:string
  -> filename:string
  -> t
  -> unit Deferred.Or_error.t

(** Apply the given translation process (single signal filter) to the specified
    signal. This will also load the file (and add it to the list in the GUI) if
    it is not already loaded. *)
val apply_translate_process_file
  :  signal:string
  -> filename:string
  -> t
  -> unit Deferred.Or_error.t

(** Apply the given transaction process (multiple signal filter) to the
    specified signal. This will also load the file (and add it to the list in
    the GUI) if it is not already loaded. *)
val apply_transaction_process_file
  :  signal:string
  -> filename:string
  -> t
  -> unit Deferred.Or_error.t
