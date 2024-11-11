open! Core

type t =
  | Hex
  | Decimal
  | Signed_decimal
  | Binary
  | Octal
  | Ascii

let to_string = function
  | Hex -> "Hex"
  | Decimal -> "Decimal"
  | Signed_decimal -> "Signed_Decimal"
  | Binary -> "Binary"
  | Octal -> "Octal"
  | Ascii -> "ASCII"
;;
