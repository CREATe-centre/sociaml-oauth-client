open Core.Std
open Oauth_client

module Rnd = Random

module Random : Common.RANDOM = struct
  
  let self_init () = Unix.gettimeofday () |> Int.of_float |> Rnd.init
  
  let int = Rnd.int
  
  let int32 = Rnd.int32
  
end

module Clock : Common.CLOCK = struct
  
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