
(* copy of a valid packet that didn't go too well *)
(* 10:11:56.610358 00:16:3e:01:00:e7 > 00:16:3e:2c:5a:99, ethertype IPv4
   (0x0800), length 62: (tos 0x0, ttl 38, id 56798, offset 0, flags [none],
   proto TCP (6), length 48)
       192.168.252.20.16645 > 5.153.225.51.80: Flags [S], cksum 0x83b4
       (correct), seq 466479086, win 5840, options [mss 1460,wscale 2,eol],
       length 0
    0x0000:  4500 0030 ddde 0000 2606 1360 c0a8 fc14  E..0....&..`....
    0x0010:  0599 e133 4105 0050 1bcd e7ee 0000 0000  ...3A..P........
    0x0020:  7002 16d0 83b4 0000 0204 05b4 0303 0200  p...............
*)
let tcp_syn () =
  let syn = Cstruct.create 62 in 
  (* ethernet layer *)
  let ethernet_dst = Macaddr.of_string_exn "00:16:3e:2c:5a:99" in
  let ethernet_src = Macaddr.of_string_exn "00:16:3e:01:00:e7" in
  Wire_structs.set_ethernet_dst (Macaddr.to_bytes ethernet_dst) 0 syn;
  Wire_structs.set_ethernet_src (Macaddr.to_bytes ethernet_src) 0 syn;
  Wire_structs.set_ethernet_ethertype syn 0x0800;
  (* ip layer *)
  let ipv4 = Cstruct.shift syn Wire_structs.sizeof_ethernet in
  Wire_structs.Ipv4_wire.set_ipv4_proto ipv4 6;
  Wire_structs.Ipv4_wire.set_ipv4_src ipv4 (Ipaddr.V4.to_int32
                                              (Ipaddr.V4.of_string_exn
                                              "192.168.252.20"));
  Wire_structs.Ipv4_wire.set_ipv4_dst ipv4 (Ipaddr.V4.to_int32
                                              (Ipaddr.V4.of_string_exn
                                              "5.153.225.51"));
  Wire_structs.Ipv4_wire.set_ipv4_hlen_version ipv4 ((4 lsl 4) + 5);
  Wire_structs.Ipv4_wire.set_ipv4_len ipv4 0x30;
  Wire_structs.Ipv4_wire.set_ipv4_id ipv4 0x1d96;
  Wire_structs.Ipv4_wire.set_ipv4_ttl ipv4 38;
  Wire_structs.Ipv4_wire.set_ipv4_csum ipv4 0xd3a8;
  (* tcp layer *)
  let tcp = Cstruct.shift ipv4 Wire_structs.Ipv4_wire.sizeof_ipv4 in
  Wire_structs.Tcp_wire.set_tcp_src_port tcp 16645;
  Wire_structs.Tcp_wire.set_tcp_dst_port tcp 80;
  Wire_structs.Tcp_wire.set_tcp_dataoff tcp 0x70;
  Wire_structs.Tcp_wire.set_tcp_ack_number tcp 0l;
  Wire_structs.Tcp_wire.set_tcp_urg_ptr tcp 0;
  Wire_structs.Tcp_wire.set_tcp_flags tcp 0x02;
  Wire_structs.Tcp_wire.set_tcp_sequence tcp 466479086l;
  Wire_structs.Tcp_wire.set_tcp_window tcp 5840;
  Wire_structs.Tcp_wire.set_tcp_checksum tcp 0x83b4;
  (* tcp options *)
  let options = Cstruct.shift tcp Wire_structs.Tcp_wire.sizeof_tcp in
  Cstruct.set_uint8 options 0 0x02;
  Cstruct.set_uint8 options 1 0x04;
  Cstruct.set_uint8 options 2 0x05;
  Cstruct.set_uint8 options 3 0xb4;
  Cstruct.set_uint8 options 4 0x03;
  Cstruct.set_uint8 options 5 0x03;
  Cstruct.set_uint8 options 6 0x02;
  Cstruct.set_uint8 options 7 0x00;
  match Nat_decompose.layers syn with
  | None ->
    Cstruct.hexdump syn;
    OUnit.assert_failure "Nat_decompose failed to parse a TCP SYN packet"
  | Some (ethernet, ip, transport, payload) ->
    OUnit.assert_equal ~cmp:Cstruct.equal payload (Cstruct.create 0)

let tests = [
  "tcp_syn", `Quick, tcp_syn;
]

let () = Alcotest.run "Mirage_nat.Nat_decompose" [ "tests", tests ]
