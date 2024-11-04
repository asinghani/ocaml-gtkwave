open! Core
open! Async
open! Cohttp
open! Cohttp_async

type t = { base_uri : string }

let make_request ~endpoint ?(args = []) { base_uri } =
  let uri = Uri.of_string (base_uri ^ endpoint) in
  let body = Body.of_form (List.map args ~f:(fun (k, v) -> k, [ v ])) in
  let headers = Header.init_with "content-type" "application/x-www-form-urlencoded" in
  let%bind response, body = Client.post ~headers ~body uri in
  let%bind body_text = Body.to_string body in
  match Response.status response with
  | `OK -> Deferred.Or_error.return body_text
  | _ -> Deferred.Or_error.error_string body_text
;;

let create ?(host = "localhost") ~port () =
  { base_uri = [%string "http://%{host}:%{port#Int}/"] }
;;
