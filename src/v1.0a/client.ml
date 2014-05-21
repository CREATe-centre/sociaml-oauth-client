open Core.Std
open Oauth_client

module type S = sig
  
  val request_token : 
      ?callback:Uri.t ->
      Uri.t ->
      Uri.t ->
      string ->
      string ->
      (string * string * bool * Uri.t) Lwt.t
  
  val access_token :
      Uri.t ->
      string ->
      string ->
      string ->
      string ->
      string ->
      (string * string) Lwt.t
  
end

module Make
    (Clock : Common.CLOCK)
    (Random : Common.RANDOM)
    (Cohttp_client : Cohttp_lwt.Client) : S = struct
      
  exception Authorization_failed of int * string
      
  module Sign = Signature.Make(Clock)(Random)
  
  open Lwt
  
  module Client = Cohttp_client
  module Header = Cohttp.Header
  module Body = Cohttp_lwt_body
  module Code = Cohttp.Code
  module Response = Client.Response
      
  let request_token 
      ?callback:(callback: Uri.t option)
      request_uri
      authorization_uri
      consumer_key
      consumer_secret =  
    
    let auth_key, auth_value = Sign.get_authorization_header
        ?callback consumer_key consumer_secret `POST request_uri
    in
    let header = Header.add (Header.init ()) auth_key auth_value in  
    
    Client.post ~headers:header request_uri >>= fun (resp, body) ->
    (match resp.Response.status with
    | `Code c -> c
    | c -> Code.code_of_status c) |> (function
    | 200 -> Body.to_string body >>= fun body_s ->
      let find k = List.Assoc.find_exn (Uri.query_of_encoded body_s) k |>
          List.hd_exn in
      let token = find "oauth_token" in
      let auth_uri = Uri.add_query_param' authorization_uri ("oauth_token", token) in
      return (token, find "oauth_token_secret",
          find "oauth_callback_confirmed" |> Bool.of_string, auth_uri)
    | c -> Body.to_string body >>= fun body_s -> 
      raise (Authorization_failed (c, body_s)))
    
  let access_token 
      access_uri
      token
      token_secret 
      verifier
      consumer_key
      consumer_secret =
    let body_params = [("oauth_verifier", verifier)] in
    let auth_key, auth_value = Sign.get_authorization_header
        ~parameters: body_params ~token: token ~token_secret:token_secret
        consumer_key consumer_secret `POST access_uri
    in
    let header = Header.add (Header.init_with "Content-Type" "application/x-www-form-urlencoded" )
        auth_key auth_value in
    let body = "oauth_verifier=" ^ (Util.pct_encode verifier) |> Body.of_string in
            
    Client.post ~body:body ~headers:header ~chunked:false access_uri >>= fun (resp, body) ->
    (match resp.Response.status with
    | `Code c -> c
    | c -> Code.code_of_status c) |> (function
    | 200 -> Body.to_string body >>= fun body_s ->
      let find k = List.Assoc.find_exn (Uri.query_of_encoded body_s) k |>
          List.hd_exn in
      return (find "oauth_token", find "oauth_token_secret")
    | c -> Body.to_string body >>= fun body_s -> 
      raise (Authorization_failed (c, body_s)))
    
end