module type S = sig
  val add_authorization_header : 
      ?body_parameters : (string * string) list ->
      ?callback : Uri.t  ->
      ?token : string ->
      ?token_secret : string ->
      consumer_key : string ->
      consumer_secret : string ->
      method' : [ | `POST | `GET ] ->
      uri : Uri.t ->
      Cohttp.Header.t ->
      Cohttp.Header.t
end

module Make 
    (Clock : Oauth_client.S.CLOCK)
    (MAC : Oauth_client.S.MAC)
    (Random : Oauth_client.S.RANDOM) : S = struct
  
  open Cohttp
  open Core.Std
  
  module Util = Oauth_client.Util.Make(Random)
  
  let add_authorization_header
      ?body_parameters: (parameters: (string * string) list = [])
      ?callback: (callback: Uri.t option)
      ?token: (token: string option)
      ?token_secret: (token_secret: string = "")
      ~consumer_key: consumer_key
      ~consumer_secret: consumer_secret
      ~method': (method': [ | `POST | `GET ])
      ~uri: uri
      headers = 
 
    let oauth_params = [
        "oauth_consumer_key", consumer_key;
        "oauth_nonce", Util.generate_nonce 32;
        "oauth_signature_method", "HMAC-SHA1";
        "oauth_timestamp", Clock.time () |> Float.to_int |> string_of_int;
        "oauth_version", "1.0";
      ] |> List.append (match callback with
      | Some callback -> ["oauth_callback", Uri.to_string callback |> Util.pct_encode;]
      | None -> []) |> List.append (match token with
      | Some token -> ["oauth_token", token;]
      | None -> [])    
    in
  
    let (|+) = MAC.add_string in 
    let hmac = (Util.pct_encode consumer_secret) ^ 
        "&" ^ (Util.pct_encode token_secret) |>
      MAC.init |+ 
      (match method' with | `POST -> "POST&" | `GET -> "GET&") |+
    	(Uri.to_string uri |> Util.pct_encode) |+ 
      "&" |>
		  fun hmac -> Uri.query uri |> List.fold 
          ~init:parameters
          ~f:(fun acc (key, values) -> 
            match List.length values with
            | 1 -> List.append acc [key, match List.hd values with | Some v -> v | None -> ""]
            | _ -> List.fold ~init:[] 
              ~f:(fun accc value -> 
                List.append accc [key, value]) values |>
                  List.append acc) |>
        List.append oauth_params |> 
        List.map ~f:(fun (key, value) -> (Util.pct_encode key, Util.pct_encode value)) |>
        List.sort ~cmp:(fun (key1, _) (key2, _) -> String.compare key1 key2) |>
        List.foldi ~init:hmac ~f:(fun i hmac (key, value) ->
          hmac |+
          (match i with | 0 -> "" | _ -> Util.pct_encode "&") |+
          key |+ (Util.pct_encode "=") |+ value)
    in  
      
    let rbuf = Buffer.create 16 in
    let buf_add = Buffer.add_string rbuf in
    buf_add "OAuth oauth_signature=\"";
    MAC.result hmac |> Cohttp.Base64.encode |> Util.pct_encode |> buf_add;
    buf_add "\"";
    List.iter ~f:(fun (key, value) ->
        buf_add ",";
        buf_add key;
        buf_add "=\"";
        buf_add value;
        buf_add "\"";     
      ) oauth_params;
    print_endline (Buffer.contents rbuf);
    Header.add headers "Authorization" (Buffer.contents rbuf)
  
end