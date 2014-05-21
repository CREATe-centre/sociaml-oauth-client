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
    (Clock : Oauth_client.Common.CLOCK)
    (Random : Oauth_client.Common.RANDOM)
    (Cohttp_client : Cohttp_lwt.Client) : S