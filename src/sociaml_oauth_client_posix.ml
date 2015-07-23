open Sociaml_oauth_client

module Clock : S.CLOCK = struct
  
  type tm = {
      tm_sec : int;
      tm_min : int;
      tm_hour : int;
      tm_mday : int;
      tm_mon : int;
      tm_year : int;
      tm_wday : int;
      tm_yday : int;
      tm_isdst : bool;
    }
    
  let time = Unix.gettimeofday
  
  let gmtime f = 
    let tm = Unix.gmtime f in
    {
      tm_sec = tm.Unix.tm_sec;
      tm_min = tm.Unix.tm_min;
      tm_hour = tm.Unix.tm_hour;
      tm_mday = tm.Unix.tm_mday;
      tm_mon = tm.Unix.tm_mon;
      tm_year = tm.Unix.tm_year;
      tm_wday = tm.Unix.tm_wday;
      tm_yday = tm.Unix.tm_yday;
      tm_isdst = tm.Unix.tm_isdst;
    }
    
end

module MAC_SHA1 : S.MAC = struct
  
  open Cryptokit
  
  type t = Cryptokit.hash
  
  let init = MAC.hmac_sha1
  
  let add_string hmac s = hmac#add_string s; hmac
  
  let result hmac = hmac#result
  
end

module Random : S.RANDOM = struct
  
  let self_init () = Unix.gettimeofday () |> int_of_float |> Random.init
  
  let int = Random.int
  
  let int32 = Random.int32
  
end