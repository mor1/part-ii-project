(* message.ml *)

open Types;;
open Capnp_rpc_lwt;;
open Lwt.Infix;;

(* Exceptions resulting in undefined values being sent in Capnp unions *)
exception Undefined_oper;;
exception Undefined_result;;

(* Exception arising from the wrong kind of response being received *)
exception Invalid_response;;

(* Expose the API service for the RPC system *)
module Api = Message_api.MakeRPC(Capnp_rpc_lwt);;

let local (some_f : (command -> unit) option) (some_g : (proposal -> unit) option) =
  let module Message = Api.Service.Message in
  Message.local @@ object
    inherit Message.service

    method client_response_impl params release_param_caps =
      let open Message.ClientResponse in
      let module Params = Message.ClientResponse.Params in

      (* Pull out all the information from the parameters *)

      (Lwt_io.printl "Look we made it!") |> Lwt.ignore_result;
      
      (* Do some callback *)

      (* Release capabilities, doesn't matter for us *)
      release_param_caps ();

      (* Return an empty response *)
      Service.return_empty ();

    method send_proposal_impl params release_param_caps =
      let open Message.SendProposal in
      let module Params = Message.SendProposal.Params in

      (* Pull out all the slot number from params *)
      let slot_number = Params.slot_number_get params in
    
      (* Get an API reader for the command, since its a nested struct *)
      let cmd_reader  = Params.command_get params in
      
      (* Retrieve the fields from the command struct passed in decision *)
      let open Api.Reader.Message in
    
      (* Retrieve the client id and command id fields from the struct *)
      let client_id = Command.client_id_get cmd_reader in
      let command_id = Command.command_id_get cmd_reader in
        
      (* Operation is more difficult as it is a nested struct *)
      let op_reader = Command.operation_get cmd_reader in
      
      (* Operations are a union type in Capnp so match over the variant *)
      let operation = (match Command.Operation.get op_reader with
      | Command.Operation.Nop -> Types.Nop
      | Command.Operation.Create c_struct ->
        let k = Command.Operation.Create.key_get c_struct in
        let v = Command.Operation.Create.value_get c_struct in
        Types.Create(k,v)
      | Command.Operation.Read r_struct -> 
        let k = Command.Operation.Read.key_get r_struct in
        Types.Read(k)
      | Command.Operation.Update u_struct ->
        let k = Command.Operation.Update.key_get u_struct in
        let v = Command.Operation.Update.value_get u_struct in
        Types.Update(k,v)
      | Command.Operation.Remove r_struct ->
        let k = Command.Operation.Remove.key_get r_struct in
        Types.Remove(k)
      | Command.Operation.Undefined(_) -> raise Undefined_oper) in
      
      (* Form the proposal from the message parameters *)
      let proposal = (slot_number, (Core.Uuid.of_string client_id, command_id, operation)) in
      
      (* Do something with the proposal here *)
      (* This is nonsense at the moment *)
      (match some_g with
      | None -> ()
      | Some g -> g(proposal) );
      
      (* Release capabilities, doesn't matter for us *)
      release_param_caps ();

      (* Return an empty response *)
      Service.return_empty ();

    method decision_impl params release_param_caps = 
      let open Message.Decision in
      let module Params = Message.Decision.Params in
    
      (* Get slot number *)
      let slot_number = Params.slot_number_get params in

      (* Get an API reader for the command, since its a nested struct *)
      let cmd_reader  = Params.command_get params in
      

      (* Retrieve the fields from the command struct passed in decision *)
      let open Api.Reader.Message in
    
      (* Retrieve the client id and command id fields from the struct *)
      let client_id = Command.client_id_get cmd_reader in
      let command_id = Command.command_id_get cmd_reader in
        
      (* Operation is more difficult as it is a nested struct *)
      let op_reader = Command.operation_get cmd_reader in
      
      (* Operations are a union type in Capnp so match over the variant *)
      let operation = (match Command.Operation.get op_reader with
      | Command.Operation.Nop -> Types.Nop
      | Command.Operation.Create c_struct ->
        let k = Command.Operation.Create.key_get c_struct in
        let v = Command.Operation.Create.value_get c_struct in
        Types.Create(k,v)
      | Command.Operation.Read r_struct -> 
        let k = Command.Operation.Read.key_get r_struct in
        Types.Read(k)
      | Command.Operation.Update u_struct ->
        let k = Command.Operation.Update.key_get u_struct in
        let v = Command.Operation.Update.value_get u_struct in
        Types.Update(k,v)
      | Command.Operation.Remove r_struct ->
        let k = Command.Operation.Remove.key_get r_struct in
        Types.Remove(k)
      | Command.Operation.Undefined(_) -> raise Undefined_oper) in
      
      (* Form the proposal from the message parameters *)
      let proposal = (slot_number, (Core.Uuid.of_string client_id, command_id, operation)) in
      
      (* Call the callback function that will process the decision *)
      (match some_g with
      | None -> ()
      | Some g -> g(proposal) );
 
      (* Release capabilities, doesn't matter for us *)
      release_param_caps ();

      (* Return an empty response *)
      Service.return_empty ();

    method client_request_impl params release_param_caps =
      let open Message.ClientRequest in
      let module Params = Message.ClientRequest.Params in
      (* Retrieve the fields from the command struct passed in request *)
      let cmd_reader = Params.command_get params in
        let open Api.Reader.Message in
        
        (* Retrieve the client id and command id fields from the struct *)
        let client_id = Command.client_id_get cmd_reader in
        let command_id = Command.command_id_get cmd_reader in
        
        (* Operation is more difficult as it is a nested struct *)
        let op_reader = Command.operation_get cmd_reader in
        (* Operations are a union type in Capnp so match over the variant *)
        let operation = (match Command.Operation.get op_reader with
          | Command.Operation.Nop -> Types.Nop
          | Command.Operation.Create c_struct ->
              let k = Command.Operation.Create.key_get c_struct in
              let v = Command.Operation.Create.value_get c_struct in
              Types.Create(k,v)
          | Command.Operation.Read r_struct -> 
              let k = Command.Operation.Read.key_get r_struct in
              Types.Read(k)
          | Command.Operation.Update u_struct ->
              let k = Command.Operation.Update.key_get u_struct in
              let v = Command.Operation.Update.value_get u_struct in
              Types.Update(k,v)
          | Command.Operation.Remove r_struct ->
              let k = Command.Operation.Remove.key_get r_struct in
              Types.Remove(k)
          | Command.Operation.Undefined(_) -> raise Undefined_oper) in

        (* Get back response for request *)
        (* Note here there is a temporay Nop passed *)
        (* This pattern matching is not exhaustive but
           we always want some callback f here 

           So it is suitable to raise an exception
           if one is not passed in this case
        *)
        match some_f with | Some f ->
          f (Core.Uuid.of_string client_id, command_id, operation);
      
        (* Releases capabilities, doesn't matter for us *)
        release_param_caps ();
        
        (* Return an empty response *)
        Service.return_empty ();
        
  end;;

(*---------------------------------------------------------------------------*)

let client_request_rpc t (cmd : Types.command) =
  let open Api.Client.Message.ClientRequest in
  let request, params = Capability.Request.create Params.init_pointer in
  let open Api.Builder.Message in
    (* Create an empty command type as recognised by Capnp *)
    let cmd_rpc = (Command.init_root ()) in
    
    (* Construct a command struct for Capnp from the cmd argument given *)
    let (client_id, command_id, operation) = cmd in
      Command.client_id_set cmd_rpc (Core.Uuid.to_string client_id);
      Command.command_id_set_exn cmd_rpc command_id;
      
      (* Construct an operation struct here *)
      let oper_rpc = (Command.Operation.init_root ()) in
      
      (* Populate the operation struct with the correct values *)
      (match operation with
      | Nop         -> 
        Command.Operation.nop_set oper_rpc
      | Create(k,v) ->
        let create = (Command.Operation.create_init oper_rpc) in
        Command.Operation.Create.key_set_exn create k;
        Command.Operation.Create.value_set create v;
      | Read  (k)   -> 
        let read = Command.Operation.read_init oper_rpc in
        Command.Operation.Read.key_set_exn read k;
      | Update(k,v) ->
        let update = Command.Operation.update_init oper_rpc in
        Command.Operation.Update.key_set_exn update k;
        Command.Operation.Update.value_set update v;
      | Remove(k)   -> 
        let remove = Command.Operation.remove_init oper_rpc in
        Command.Operation.Remove.key_set_exn remove k);

      (Command.operation_set_builder cmd_rpc oper_rpc |> ignore);

      (* Constructs the command struct and associates with params *)
      (Params.command_set_reader params (Command.to_reader cmd_rpc) |> ignore);

      (* Send the message and ignore the response *)
      Capability.call_for_unit_exn t method_id request;;

let client_response_rpc t (command_id : Types.command_id) (result : Types.result) =
  let open Api.Client.Message.ClientResponse in
  let request, params = Capability.Request.create Params.init_pointer in
  let open Api.Builder.Message in

    (* Create an empty result as recognised by Capnp *)
    let result_rpc = Result.init_root () in

    (* Construct the result from the result argument given *)
    (match result with
    | Failure ->
      Result.failure_set result_rpc
    | Success ->
      Result.success_set result_rpc
    | ReadSuccess v ->
      Result.read_set result_rpc v);

    (* Construct the result and associate with params *)
    (Params.result_set_reader params (Result.to_reader result_rpc) |> ignore);

    (* Set the command id in parameters equal to argument *)
    Params.command_id_set_exn params command_id;

    (* Send the message and ignore the response *)
    Capability.call_for_unit_exn t method_id request;;  

let decision_rpc t (p : Types.proposal) =
  let open Api.Client.Message.Decision in
  let request, params = Capability.Request.create Params.init_pointer in
  let open Api.Builder.Message in

    (* Create an empty command type as recognised by Capnp *)
    let cmd_rpc = Command.init_root () in
    
    (* Construct a command struct for Capnp from the cmd argument given *)
    let (slot_number, (client_id, command_id, operation)) = p in
      Command.client_id_set cmd_rpc (Core.Uuid.to_string client_id);
      Command.command_id_set_exn cmd_rpc command_id;
      
      (* Construct an operation struct here *)
      let oper_rpc = (Command.Operation.init_root ()) in
      
      (* Populate the operation struct with the correct values *)
      (match operation with
      | Nop         -> 
        Command.Operation.nop_set oper_rpc
      | Create(k,v) ->
        let create = (Command.Operation.create_init oper_rpc) in
        Command.Operation.Create.key_set_exn create k;
        Command.Operation.Create.value_set create v;
      | Read  (k)   -> 
        let read = Command.Operation.read_init oper_rpc in
        Command.Operation.Read.key_set_exn read k;
      | Update(k,v) ->
        let update = Command.Operation.update_init oper_rpc in
        Command.Operation.Update.key_set_exn update k;
        Command.Operation.Update.value_set update v;
      | Remove(k)   -> 
        let remove = Command.Operation.remove_init oper_rpc in
        Command.Operation.Remove.key_set_exn remove k);

      (Command.operation_set_builder cmd_rpc oper_rpc |> ignore);

      (* Constructs the command struct and associates with params *)
      (Params.command_set_reader params (Command.to_reader cmd_rpc) |> ignore);
      
      (* Add the given slot number argument to the message parameters *)
      Params.slot_number_set_exn params slot_number;

      (* Send the message and ignore the response *)
      Capability.call_for_unit_exn t method_id request;;

let proposal_rpc t (p : Types.proposal) =
  let open Api.Client.Message.SendProposal in
  let request, params = Capability.Request.create Params.init_pointer in
  let open Api.Builder.Message in
   (* Create an empty command type as recognised by Capnp *)
    let cmd_rpc = Command.init_root () in
    
    (* Construct a command struct for Capnp from the cmd argument given *)
    let (slot_number, (client_id, command_id, operation)) = p in
      Command.client_id_set cmd_rpc (Core.Uuid.to_string client_id);
      Command.command_id_set_exn cmd_rpc command_id;
      
      (* Construct an operation struct here *)
      let oper_rpc = (Command.Operation.init_root ()) in
      
      (* Populate the operation struct with the correct values *)
      (match operation with
      | Nop         -> 
        Command.Operation.nop_set oper_rpc
      | Create(k,v) ->
        let create = (Command.Operation.create_init oper_rpc) in
        Command.Operation.Create.key_set_exn create k;
        Command.Operation.Create.value_set create v;
      | Read  (k)   -> 
        let read = Command.Operation.read_init oper_rpc in
        Command.Operation.Read.key_set_exn read k;
      | Update(k,v) ->
        let update = Command.Operation.update_init oper_rpc in
        Command.Operation.Update.key_set_exn update k;
        Command.Operation.Update.value_set update v;
      | Remove(k)   -> 
        let remove = Command.Operation.remove_init oper_rpc in
        Command.Operation.Remove.key_set_exn remove k);

      (Command.operation_set_builder cmd_rpc oper_rpc |> ignore);

      (* Constructs the command struct and associates with params *)
      (Params.command_set_reader params (Command.to_reader cmd_rpc) |> ignore);
      
      (* Add the given slot number argument to the message parameters *)
      Params.slot_number_set_exn params slot_number;

      (* Send the message and ignore the response *)
      Capability.call_for_unit_exn t method_id request;;

  
(*---------------------------------------------------------------------------*)

(* Types of message that can be passed between nodes:
      - This represents the application-level representation of a message.
      - These can be passed to the RPC api to be prepared for transport etc. *)
type message = ClientRequestMessage of command
             | ClientResponseMessage of command_id * result
             | ProposalMessage of proposal
             | DecisionMessage of proposal;;
          (* | ... further messages will be added *) 

(* Takes a Capnp URI for a service and returns the lwt capability of that
   service *)
(* This should probably be optimised - maybe store a reference to the
   instantiated service in the client once a connection has been
   established.

   This may even be necessary in order to preserve the ordering semantics
   we want with RPC delivery *)
let service_from_uri uri =
  let client_vat = Capnp_rpc_unix.client_only_vat () in
  let sr = Capnp_rpc_unix.Vat.import_exn client_vat uri in
  Sturdy_ref.connect_exn sr >>= fun proxy_to_service ->
  Lwt.return proxy_to_service;;

let hostport_to_uri host port =
  let loc = Capnp_rpc_unix.Network.Location.tcp host port in
  let dig = Capnp_rpc_lwt.Auth.Digest.insecure in
  let id = Capnp_rpc_lwt.Restorer.Id.derived "" (host ^ (string_of_int port)) in
  Capnp_rpc_unix.Network.Address.to_uri ((loc,dig), Capnp_rpc_lwt.Restorer.Id.to_string id);;


let service_from_hostport host port =
  let loc = Capnp_rpc_unix.Network.Location.tcp host port in
  let dig = Capnp_rpc_lwt.Auth.Digest.insecure in
  let id = Capnp_rpc_lwt.Restorer.Id.derived "" (host ^ (string_of_int port)) in
  let uri = Capnp_rpc_unix.Network.Address.to_uri ((loc,dig), Capnp_rpc_lwt.Restorer.Id.to_string id) in
  service_from_uri uri;;

(* Accepts as input a message and prepares it for RPC transport,
   given the URI of the service to which it will be sent*)
let send_request message uri =
  (* Get the service for the given URI *)
  service_from_uri uri >>= fun service ->
  match message with
  | ClientRequestMessage cmd ->
    client_request_rpc service cmd;
  | ClientResponseMessage (cid, result) ->
    client_response_rpc service cid result;
  | DecisionMessage p ->
    decision_rpc service p;
  | ProposalMessage p ->
    proposal_rpc service p;
