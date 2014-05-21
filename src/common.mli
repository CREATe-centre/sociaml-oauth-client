module type RANDOM = sig
  val self_init : unit -> unit
  val int : int -> int
  val int32 : int32 -> int32
end

module type CLOCK = sig
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
  val time : unit -> float
  val gmtime : float -> tm
end