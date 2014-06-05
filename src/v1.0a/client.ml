module type S = sig
  
  type error = 
    | HttpResponse of int * string
    | Exception of exn
  
  type request_token = {
    consumer_key : string;
    consumer_secret : string;
    token : string;
    token_secret : string;
    callback_confirmed : bool;
    authorization_uri : Uri.t
  }
  
  type access_token = {
    consumer_key : string;
    consumer_secret : string;
    token : string;
    token_secret : string;
  }
  
  val fetch_request_token : 
      ?callback : Uri.t ->
      request_uri : Uri.t ->
      authorization_uri : Uri.t ->
      consumer_key : string ->
      consumer_secret : string ->
      unit ->
      (request_token, error) Core.Result.t Lwt.t
  
  val fetch_access_token :
      access_uri : Uri.t ->
      request_token : request_token ->
      verifier : string ->
      (access_token, error) Core.Result.t Lwt.t
      
  val do_get_request :
      ?uri_parameters : (string * string) list ->
      uri : Uri.t ->
      access_token : access_token ->
      unit ->
      (string, error) Core.Result.t Lwt.t
      
  val do_post_request :
      ?uri_parameters : (string * string) list ->
      ?body_parameters : (string * string) list ->
      uri : Uri.t ->
      access_token : access_token ->
      unit ->
      (string, error) Core.Result.t Lwt.t
  
end

module Make
    (Clock : Oauth_client.S.CLOCK)
    (Client : Cohttp_lwt.Client)
    (MAC : Oauth_client.S.MAC)
    (Random : Oauth_client.S.RANDOM) : S = struct
     
  type error = 
    | HttpResponse of int * string
    | Exception of exn
       
  type request_token = {
    consumer_key : string;
    consumer_secret : string;
    token : string;
    token_secret : string;
    callback_confirmed : bool;
    authorization_uri : Uri.t
  }
  
  type access_token = {
    consumer_key : string;
    consumer_secret : string;
    token : string;
    token_secret : string;
  }
      
  exception Authorization_failed of int * string
      
  module R = Core.Result
  module Sign = Signature.Make(Clock)(MAC)(Random)
  module Util = Oauth_client.Util.Make(Random)
  
  module Code = Cohttp.Code
  module Body = Cohttp_lwt_body
  module Header = Cohttp.Header
  module Response = Client.Response
  
  open Core.Std
  open Lwt
      
  let fetch_request_token 
      ?callback:(callback: Uri.t option)
      ~request_uri
      ~authorization_uri
      ~consumer_key
      ~consumer_secret
      _ =  
    
    let header = Sign.add_authorization_header
        ?callback
        ~consumer_key: consumer_key
        ~consumer_secret: consumer_secret
        ~method': `POST
        ~uri: request_uri
        (Header.init_with "Content-Type" "application/x-www-form-urlencoded")
    in  
    
    Client.post ~headers:header request_uri >>= fun (resp, body) ->
    (match resp.Response.status with
    | `Code c -> c
    | c -> Code.code_of_status c) |> (function
    | 200 -> Body.to_string body >>= fun body_s ->
      let find k = List.Assoc.find_exn (Uri.query_of_encoded body_s) k |>
          List.hd_exn in
      let token = find "oauth_token" in
      return (
        try
          R.Ok ({
            consumer_key = consumer_key;
            consumer_secret = consumer_secret;
            token = token;
            token_secret = find "oauth_token_secret";
            callback_confirmed = find "oauth_callback_confirmed" |> Bool.of_string;
            authorization_uri = Uri.add_query_param' authorization_uri ("oauth_token", token);
          })
        with _ as e -> R.Error(Exception e))
    | c -> Body.to_string body >>= fun b -> 
      return (R.Error(HttpResponse (c, b))))
    
  let fetch_access_token 
      ~access_uri
      ~(request_token:request_token)
      ~verifier =
        
    let header = Sign.add_authorization_header
        ~body_parameters: [("oauth_verifier", verifier)] 
        ~token: request_token.token 
        ~token_secret: request_token.token_secret
        ~consumer_key: request_token.consumer_key
        ~consumer_secret: request_token.consumer_secret
        ~method': `POST
        ~uri: access_uri
        (Header.init_with "Content-Type" "application/x-www-form-urlencoded")
    in
    let body = "oauth_verifier=" ^ (Util.pct_encode verifier) |> Body.of_string in
            
    Client.post ~body:body ~headers:header ~chunked:false access_uri >>= fun (resp, body) ->
    (match resp.Response.status with
    | `Code c -> c
    | c -> Code.code_of_status c) |> (function
    | 200 -> Body.to_string body >>= fun body_s ->
      let find k = List.Assoc.find_exn (Uri.query_of_encoded body_s) k |>
          List.hd_exn in
      return (
        try 
          R.Ok({
            consumer_key = request_token.consumer_key;
            consumer_secret = request_token.consumer_secret;
            token = find "oauth_token";
            token_secret = find "oauth_token_secret";
          })
        with _ as e -> R.Error(Exception e)
      )
    | c -> Body.to_string body >>= fun b -> 
      return (R.Error(HttpResponse (c, b))))
      
  let do_get_request
      ?uri_parameters: (uri_parameters: (string * string) list = []) 
      ~uri
      ~access_token
      _ =
        
    let uri_with_query = (Uri.add_query_params' uri uri_parameters) in
    
    let header = Sign.add_authorization_header
        ~token: access_token.token 
        ~token_secret: access_token.token_secret
        ~consumer_key: access_token.consumer_key
        ~consumer_secret: access_token.consumer_secret
        ~method': `GET
        ~uri: uri_with_query
        (Header.init_with "Content-Type" "application/x-www-form-urlencoded")
    in
    
    Client.get ~headers:header uri_with_query >>= fun (resp, body) ->
    (match resp.Response.status with
    | `Code c -> c
    | c -> Code.code_of_status c) |> (function
    | 200 -> Body.to_string body >>= fun body_s ->
      return (R.Ok(body_s))
    | c -> Body.to_string body >>= fun b -> 
      return (R.Error(HttpResponse (c, b))))
    
  let do_post_request
      ?uri_parameters: (uri_parameters: (string * string) list = []) 
      ?body_parameters: (body_parameters: (string * string) list = []) 
      ~uri
      ~access_token
      _ =
        
    let uri_with_query = (Uri.add_query_params' uri uri_parameters) in
    
    let header = Sign.add_authorization_header
        ~body_parameters: body_parameters
        ~token: access_token.token 
        ~token_secret: access_token.token_secret
        ~consumer_key: access_token.consumer_key
        ~consumer_secret: access_token.consumer_secret
        ~method': `POST
        ~uri: uri_with_query
        (Header.init_with "Content-Type" "application/x-www-form-urlencoded")
    in
    let body = 
      let buf = Buffer.create 16 in
      List.iteri ~f:(fun i (k, v) ->
        (match i with | 0 -> () | _ -> Buffer.add_char buf '&');
        Buffer.add_string buf k;
        Buffer.add_char buf '=';
        Buffer.add_string buf v) body_parameters;
      Buffer.contents buf |> Body.of_string
    in
    
    Client.post ~body:body ~headers:header ~chunked:false uri_with_query >>= fun (resp, body) ->
    (match resp.Response.status with
    | `Code c -> c
    | c -> Code.code_of_status c) |> (function
    | 200 -> Body.to_string body >>= fun body_s ->
      return (R.Ok(body_s))
    | c -> Body.to_string body >>= fun b -> 
      return (R.Error(HttpResponse (c, b))))
    
end