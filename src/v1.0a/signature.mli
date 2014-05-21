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

module Make 
    (Clock : Oauth_client.Common.CLOCK)
    (Random : Oauth_client.Common.RANDOM) : S