open! Core

type t =
  | Hex
  | Decimal
  | Signed_decimal
  | Binary
  | Octal
  | Ascii

val to_string : t -> string
