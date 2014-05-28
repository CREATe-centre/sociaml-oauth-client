module type RANDOM = S.RANDOM

module type S = sig
  
  (** Percent encode a string according to RFC 3986, Section 2.1
  http://tools.ietf.org/html/rfc3986#section-2.1 *)
  val pct_encode : string -> string

  val generate_nonce : int -> string
  
end

module Make (Random : RANDOM) : S = struct

  open Core.Std
  
  let pct_encode src = 
    let dst = String.length src |> Buffer.create in
    String.iter ~f:(function 
      | c when 
        (c >= '0' && c <= '9') 
        || (c >= 'A' && c <= 'Z')
        || (c >= 'a' && c <= 'z')
        || c = '-'
        || c = '.'
        || c = '_'
        || c = '~' -> Buffer.add_char dst c
      | c -> Char.to_int c |>
        Printf.sprintf "%%%X" |>
        Buffer.add_string dst) src; 
    Buffer.contents dst
  
  let generate_nonce =
    let forbid = Re2.Regex.create_exn "[^0-9a-zA-Z]+" in
    let max_char = Char.max_value |> Char.to_int in 
    Random.self_init ();
    fun length ->
      let buf = Buffer.create length in
      let rec loop = function
        | i when i = length -> ()
        | i ->
          Random.int max_char |> Char.of_int_exn |> Buffer.add_char buf; 
          loop (i + 1)
      in
      loop 0;
      Buffer.contents buf |> 
      Cohttp.Base64.encode |>
      Re2.Regex.rewrite_exn forbid ~template:""

end