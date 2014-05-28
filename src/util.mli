module type RANDOM = S.RANDOM

module type S = sig
  
  (** Percent encode a string according to RFC 3986, Section 2.1
  http://tools.ietf.org/html/rfc3986#section-2.1 *)
  val pct_encode : string -> string

  val generate_nonce : int -> string
  
end

module Make (Random : RANDOM) : S 