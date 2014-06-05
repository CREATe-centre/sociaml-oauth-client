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
    (Cohttp_client : Cohttp_lwt.Client)
    (MAC : Oauth_client.S.MAC)
    (Random : Oauth_client.S.RANDOM) : S