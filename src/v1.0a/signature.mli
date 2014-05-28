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
    (Random : Oauth_client.S.RANDOM) : S