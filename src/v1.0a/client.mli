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
      (request_token, error) Sociaml_oauth_client.Result.t Lwt.t
  
  val fetch_access_token :
      access_uri : Uri.t ->
      request_token : request_token ->
      verifier : string ->
      (access_token, error) Sociaml_oauth_client.Result.t Lwt.t
      
  val do_get_request :
      ?uri_parameters : (string * string) list ->
      ?expect : Cohttp.Code.status_code ->
      uri : Uri.t ->
      access_token : access_token ->
      unit ->
      (string, error) Sociaml_oauth_client.Result.t Lwt.t
      
  val do_post_request :
      ?uri_parameters : (string * string) list ->
      ?body_parameters : (string * string) list ->
      ?expect : Cohttp.Code.status_code ->
      uri : Uri.t ->
      access_token : access_token ->
      unit ->
      (string, error) Sociaml_oauth_client.Result.t Lwt.t
  
end

module Make
    (Clock : Sociaml_oauth_client.S.CLOCK)
    (Cohttp_client : Cohttp_lwt.Client)
    (MAC : Sociaml_oauth_client.S.MAC)
    (Random : Sociaml_oauth_client.S.RANDOM) : S