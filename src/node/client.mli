(* Client.mli *)

open Types;;
open Message;;
open Core;;
open Core.Unix;;

module type CLIENT = sig
  type t;;
  val new_client : unit -> t;;
  val add_replica_uri : Uri.t -> t -> unit;;  
  val send_request_message : t -> operation -> unit;;
end;;

module Client : CLIENT;;






