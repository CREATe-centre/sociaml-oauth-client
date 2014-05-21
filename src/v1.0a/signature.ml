open Core.Std
open Cryptokit
open Oauth_client

module type S = sig
  val get_authorization_header : 
      ?parameters : (string * string) list ->
      ?callback : Uri.t  ->
      ?token : string ->
      ?token_secret : string ->
      string ->
      string ->
      [ | `POST | `GET ] ->
      Uri.t ->
      string * string
end

module Make (Clock : Common.CLOCK) (Random : Common.RANDOM) : S = struct
  
  let get_time () =
    Clock.time () |> Float.to_int |> string_of_int
  
  let generate_nonce () =
    let max_char = Char.max_value |> Char.to_int in 
    Random.self_init ();
    Util.generate_nonce (fun () -> Random.int max_char |> Char.of_int_exn) 32
  
  let get_authorization_header
      ?parameters: (parameters: (string * string) list = [])
      ?callback: (callback: Uri.t option)
      ?token: (token: string option)
      ?token_secret: (token_secret: string = "")
      consumer_key
      consumer_secret
      (method':[ | `POST | `GET ])
      uri = 
 
    let oauth_params = [
        "oauth_consumer_key", consumer_key;
        "oauth_nonce", generate_nonce ();
        "oauth_signature_method", "HMAC-SHA1";
        "oauth_timestamp", get_time ();
        "oauth_version", "1.0";
      ] |> List.append (match callback with
      | Some callback -> ["oauth_callback", Uri.to_string callback |> Util.pct_encode;]
      | None -> []) |> List.append (match token with
      | Some token -> ["oauth_token", token;]
      | None -> [])    
    in
  
  let signing_key = (Util.pct_encode consumer_secret) ^ 
      "&" ^ (Util.pct_encode token_secret) in
  let hmac = MAC.hmac_sha1 signing_key in
  hmac#add_string (match method' with | `POST -> "POST&" | `GET -> "GET&");
  hmac#add_string (Uri.to_string uri |> Util.pct_encode);
  hmac#add_string "&";
    
  Uri.query uri |> List.fold 
    ~init:parameters
    ~f:(fun acc (key, values) -> 
      match List.length values with
      | 1 -> List.append acc [key, List.hd_exn values]
      | _ -> List.fold ~init:[] 
        ~f:(fun accc value -> 
          List.append accc [key, value]) values |>
            List.append acc) |>
  List.append oauth_params |> 
  List.map ~f:(fun (key, value) -> (Util.pct_encode key, Util.pct_encode value)) |>
  List.sort ~cmp:(fun (key1, _) (key2, _) -> String.compare key1 key2) |>
  List.iteri ~f:(fun i (key, value) ->
    (match i with | 0 -> () | _ -> hmac#add_string (Util.pct_encode "&"));
    hmac#add_string key;
    hmac#add_string (Util.pct_encode "=");
    hmac#add_string value);  
    
  let rbuf = Buffer.create 16 in
  let buf_add = Buffer.add_string rbuf in
  buf_add "OAuth oauth_signature=\"";
  hmac#result |> Cohttp.Base64.encode |> Util.pct_encode |> buf_add;
  buf_add "\"";
  List.iter ~f:(fun (key, value) ->
      buf_add ",";
      buf_add key;
      buf_add "=\"";
      buf_add value;
      buf_add "\"";     
    ) oauth_params;
  ("Authorization", Buffer.contents rbuf)
  
end