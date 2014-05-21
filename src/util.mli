(** Utility functions *)

(** Percent encode a string according to RFC 3986, Section 2.1
  http://tools.ietf.org/html/rfc3986#section-2.1 *)
val pct_encode : string -> string

type rng = unit -> char

val generate_nonce : rng -> int -> string 