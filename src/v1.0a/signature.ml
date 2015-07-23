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
    (Clock : Sociaml_oauth_client.S.CLOCK)
    (MAC : Sociaml_oauth_client.S.MAC)
    (Random : Sociaml_oauth_client.S.RANDOM) : S = struct
  
  open Cohttp
  
  module Util = Sociaml_oauth_client.Util.Make(Random)
  
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
        "oauth_timestamp", Clock.time () |> int_of_float |> string_of_int;
        "oauth_version", "1.0";
      ] |> List.append (match callback with
      | Some callback -> ["oauth_callback", Uri.to_string callback |> Util.pct_encode;]
      | None -> []) |> List.append (match token with
      | Some token -> ["oauth_token", token;]
      | None -> [])    
    in
    
    let uri_without_query = List.fold_left 
        (fun acc (e, _) -> Uri.remove_query_param acc e) uri (Uri.query uri) 
    in
    
    let (|+) = MAC.add_string in 
    let (_, hmac) = (Util.pct_encode consumer_secret) ^ 
        "&" ^ (Util.pct_encode token_secret) |>
      MAC.init |+ 
      (match method' with | `POST -> "POST&" | `GET -> "GET&") |+
    	(Uri.to_string uri_without_query |> Util.pct_encode) |+ "&" |>
		  fun hmac -> Uri.query uri |> List.fold_left 
          (fun acc (key, values) ->             
            match List.length values with
            | 1 -> List.append acc [key, List.hd values]
            | _ -> List.fold_left  
              (fun accc value -> 
                List.append accc [key, value]) [] values |>
                  List.append acc) parameters |>
        List.append oauth_params |> 
        List.map (fun (key, value) -> (Util.pct_encode key, Util.pct_encode value)) |>
        List.sort (fun (key1, _) (key2, _) -> String.compare key1 key2) |>
        List.fold_left (fun (i, hmac) (key, value) ->
          (i + 1, hmac |+ 
          (match i with | 0 -> "" | _ -> Util.pct_encode "&") |+
          key |+ (Util.pct_encode "=") |+ value)) (0, hmac)
    in  
      
    let rbuf = Buffer.create 16 in
    let buf_add = Buffer.add_string rbuf in
    buf_add "OAuth oauth_signature=\"";
    MAC.result hmac |> B64.encode |> Util.pct_encode |> buf_add;
    buf_add "\"";
    List.iter (fun (key, value) ->
        buf_add ",";
        buf_add key;
        buf_add "=\"";
        buf_add value;
        buf_add "\"";     
      ) oauth_params;
    Header.add headers "Authorization" (Buffer.contents rbuf)
  
end