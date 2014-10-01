## OAuth Client Library for OCaml

A very basic OAuth client library for OCaml.  Currently supports
Version 1.0a of the OAuth protocol and has been tested against
the Twitter and Tumblr APIs.

### Installation

The simplest way to install the package is through the 
[OPAM package manager](http://opam.ocamlpro.com/), e.g.: 

    opam install sociaml-oauth-client
    
Installing the package registers 3 findlib libraries:

* *oauth-client* - Common code used by different OAuth implementations, this is mostly
for internal use.
* *oauth-client.v1_0a* - Client code for V1.0a of the OAuth specification.
* *oauth-client.posix* - Standard implementations of different module types 
(Clock, Random, MAC) for use on Posix systems.

### Usage

#### V1.0a

Construct a Client module, e.g.:

    open Oauth_client_v1_0a
    open Oauth_client_posix
    module Client = Client.Make(Clock)(Cohttp_lwt_posix.Client)(MAC_SHA1)(Random)
    
Use your consumer key and secret to fetch a request token, e,g.:

    Client.fetch_request_token
        (Uri.of_string "http://www.example.com/oauth/request_token")
        (Uri.of_string "http://www.example.com/oauth/authorize")
        "YOUR CONSUMER KEY"
        "YOUR CONSUMER SECRET"

Direct the user to the returned authorization URL so that they can authenticate
themselves with the remote service.  You will need to extract the token verifier
from the response.  Then exchange the request token for an access token, e.g.:

    Client.fetch_access_token
        (Uri.of_string "http://www.example.com/oauth/access_token")
        request_token
        "TOKEN VERIFIER"
        
Once you have the access token you can use the *do_get_request* and *do_post_request* 
functions in *Client* to add the perform signed GET/POST requests.  For
a good introduction to the OAuth authentication flow, Twitter 
[maintain a very good guide](https://dev.twitter.com/docs/auth).
