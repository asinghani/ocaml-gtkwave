open! Core
open! Async
open! Cohttp
open! Cohttp_async
open Deferred.Or_error.Let_syntax

type t = { base_uri : string }

let create ?(host = "localhost") ~port () =
  { base_uri = [%string "http://%{host}:%{port#Int}/"] }
;;

let make_request ~endpoint ?(args = []) { base_uri } =
  let uri = Uri.of_string (base_uri ^ endpoint) in
  let body = Body.of_form (List.map args ~f:(fun (k, v) -> k, [ v ])) in
  let headers = Header.init_with "content-type" "application/x-www-form-urlencoded" in
  let%bind.Deferred response, body = Client.post ~headers ~body uri in
  let%bind.Deferred body_text = Body.to_string body in
  let status = Response.status response in
  match status with
  | `OK -> Deferred.Or_error.return body_text
  | _ ->
    Deferred.Or_error.error_string
      [%string "%{Code.string_of_status status}: %{body_text}"]
;;

let make_request_unit ~endpoint ?args t = make_request ~endpoint ?args t >>| Fn.ignore

let call_menu_item ~path t =
  let item = path |> String.concat ~sep:"/" |> String.tr ~target:' ' ~replacement:'_' in
  make_request_unit t ~endpoint:"call_menu_item" ~args:[ "item", item ]
;;

let add_comment_trace ~comment t =
  make_request_unit t ~endpoint:"add_comment_trace" ~args:[ "comment", comment ]
;;

let add_wave ~signal t =
  make_request_unit t ~endpoint:"add_wave" ~args:[ "signal", signal ]
;;

let remove_wave ~signal t =
  make_request_unit t ~endpoint:"remove_wave" ~args:[ "signal", signal ]
;;

let find_next_edge ~signal t =
  make_request_unit t ~endpoint:"find_next_edge" ~args:[ "signal", signal ]
;;

let find_prev_edge ~signal t =
  make_request_unit t ~endpoint:"find_prev_edge" ~args:[ "signal", signal ]
;;

let open_tree_node ~node t =
  make_request_unit t ~endpoint:"open_tree_node" ~args:[ "node", node ]
;;

let get_displayed_waves t =
  make_request t ~endpoint:"get_displayed_waves" >>| String.split_lines
;;

let get_dumpfile_name t = make_request t ~endpoint:"get_dumpfile_name"
let get_dumpfile_type t = make_request t ~endpoint:"get_dumpfile_type"

let get_dumpfile_time_range t =
  make_request t ~endpoint:"get_dumpfile_time_range"
  >>| String.lsplit2_exn ~on:','
  >>| Tuple2.map ~f:Int.of_string
;;

let get_all_signals t = make_request t ~endpoint:"get_all_signals" >>| String.split_lines

let get_primary_marker_position t =
  let%map pos = make_request t ~endpoint:"get_marker_position" >>| Int.of_string in
  Option.some_if (pos >= 0) pos
;;

let set_primary_marker_position ~position t =
  make_request_unit
    t
    ~endpoint:"set_marker_position"
    ~args:[ "position", Option.value_map position ~default:"-1" ~f:Int.to_string ]
;;

let marker_index_to_name index =
  if index < 0 || index > 25
  then raise_s [%message "Max 26 markers supported" (index : int)];
  String.get "ABCDEFGHIJKLMNOPQRSTUVWXYZ" index |> String.of_char
;;

let get_named_marker_position ~index t =
  let marker = marker_index_to_name index in
  let%map pos =
    make_request t ~endpoint:"get_named_marker_position" ~args:[ "marker", marker ]
    >>| Int.of_string
  in
  Option.some_if (pos >= 0) pos
;;

let set_named_marker_position ?(comment = "") ~index ~position t =
  let marker = marker_index_to_name index in
  make_request_unit
    t
    ~endpoint:"set_named_marker_position"
    ~args:
      [ "marker", marker
      ; "position", Option.value_map position ~default:"-1" ~f:Int.to_string
      ; "comment", comment
      ]
;;

let set_all_named_markers ~markers t =
  (* (position, optional comment) *)
  if List.length markers > 26
  then raise_s [%message "Maximum number of markers allowed is 26"];
  List.init 26 ~f:Fn.id
  |> Deferred.Or_error.List.iter ~how:`Sequential ~f:(fun i ->
    match List.nth markers i with
    | None -> set_named_marker_position t ~index:i ~position:None
    | Some (position, comment) ->
      set_named_marker_position t ?comment ~index:i ~position:(Some position))
;;

let get_window_time_range t =
  make_request t ~endpoint:"get_window_time_range"
  >>| String.lsplit2_exn ~on:','
  >>| Tuple2.map ~f:Int.of_string
;;

let set_window_time_range ~start ~end_ t =
  make_request_unit
    t
    ~endpoint:"set_window_time_range"
    ~args:[ "start", Int.to_string start; "end", Int.to_string end_ ]
;;

let get_signal_value_at_time ~signal ~time t =
  make_request
    t
    ~endpoint:"get_signal_value_at_time"
    ~args:[ "signal", signal; "time", Int.to_string time ]
  >>| String.chop_prefix_exn ~prefix:"0b"
;;

let get_signal_transitions
  ?(max = 1 lsl 30)
  ?(direction = `Forward)
  ~signal
  ~start_time
  ~end_time
  t
  =
  let direction =
    match direction with
    | `Forward -> "forward"
    | `Backward -> "backward"
  in
  make_request
    t
    ~endpoint:"get_signal_value_at_time"
    ~args:
      [ "signal", signal
      ; "start_time", Int.to_string start_time
      ; "end_time", Int.to_string end_time
      ; "max", Int.to_string max
      ; "direction", direction
      ]
  >>| String.split_lines
  >>| List.map ~f:(String.lsplit2_exn ~on:',')
  >>| List.map ~f:(Tuple2.map_fst ~f:Int.of_string)
  >>| List.map ~f:(Tuple2.map_snd ~f:(String.chop_prefix_exn ~prefix:"0b"))
;;

let reload_file t = make_request_unit t ~endpoint:"reload_file"

let highlight_signal ~signal t =
  make_request_unit t ~endpoint:"highlight_signal" ~args:[ "signal", signal ]
;;

let unhighlight_all t = make_request_unit t ~endpoint:"unhighlight_all"

let set_filter_directory ~path t =
  make_request_unit t ~endpoint:"set_filter_directory" ~args:[ "path", path ]
;;

let load_translate_file ~filename t =
  make_request_unit t ~endpoint:"load_translate_file" ~args:[ "filename", filename ]
;;

let load_translate_process_file ~filename t =
  make_request_unit
    t
    ~endpoint:"load_translate_process_file"
    ~args:[ "filename", filename ]
;;

let load_transaction_process_file ~filename t =
  make_request_unit
    t
    ~endpoint:"load_transaction_process_file"
    ~args:[ "filename", filename ]
;;

let apply_translate_file ~signal ~filename t =
  make_request_unit
    t
    ~endpoint:"apply_translate_file"
    ~args:[ "signal", signal; "filename", filename ]
;;

let apply_translate_process_file ~signal ~filename t =
  make_request_unit
    t
    ~endpoint:"apply_translate_process_file"
    ~args:[ "signal", signal; "filename", filename ]
;;

let apply_transaction_process_file ~signal ~filename t =
  make_request_unit
    t
    ~endpoint:"apply_transaction_process_file"
    ~args:[ "signal", signal; "filename", filename ]
;;
