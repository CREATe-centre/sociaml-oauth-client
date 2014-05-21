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
  
type rng = unit -> char

let generate_nonce rng length =
  let r = Re2.Regex.create_exn "[^0-9a-zA-Z]+" in
  let buf = Buffer.create length in
  let rec loop = function
    | i when i = length -> ()
    | i ->
      rng () |> Buffer.add_char buf; 
      loop (i + 1)
  in
  loop 0;
  Buffer.contents buf |> 
  Cohttp.Base64.encode |>
  Re2.Regex.rewrite_exn r ~template:""