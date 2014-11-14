0.5.0 / 2014-11-14
==================

  * Removed dependency on Core (now Core\_kernel).
  * Package name change: 
    * Oauth\_client -> Sociaml\_oauth\_client.
    * Oauth\_client\_posix -> Sociaml\_oauth\_client\_posix.
    * Oauth\_client\_v1\_0a -> Sociaml\_oauth\_client\_v1\_0a.
  * Licence change to GPL-V3.
  * Require cohttp >= 0.12.0.

0.4.1 / 2014-06-18
==================

  * Amended correct package name in \_oasis.
  
0.4.0 / 2014-06-18
==================

  * Package rename.
  * Fixe bug where percent encoded values weren't being padded correctly.

0.3.0 / 2014-06-05
==================

  * Added functions to client.ml for signing/performing GET/POST requests.

0.2.0 / 2014-05-28
==================

  * V1.0a api tidied up.
  * Dependency on Cryptokit removed, default MAC implementation provided
    by Cryptokit in the oauth-client.posix package.

0.1.0 / 2014-05-21
==================

  * Initial commit, v1.0 of the oauth protocol is supported.