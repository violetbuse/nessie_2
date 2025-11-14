import gleam/set
import gleeunit
import gleeunit/should
import nessie_2

pub fn main() {
  gleeunit.main()
}

pub fn ipv4_address_to_string_succeeds_test() {
  let r = nessie_2.ip_to_string(nessie_2.IPV4(#(1, 2, 3, 4)))
  should.equal(r, Ok("1.2.3.4"))
}

pub fn ipv4_address_to_string_fails_for_invalid_ip_test() {
  let r = nessie_2.ip_to_string(nessie_2.IPV4(#(1000, 2000, 3000, 4000)))
  should.equal(r, Error("einval"))
}

pub fn ipv6_address_to_string_succeeds_test() {
  let r =
    nessie_2.ip_to_string(
      nessie_2.IPV6(#(100, 200, 300, 0, 500, 600, 700, 800)),
    )
  should.equal(r, Ok("64:c8:12c:0:1f4:258:2bc:320"))
}

pub fn ipv6_address_to_string_fails_for_invalid_ip_test() {
  let r =
    nessie_2.ip_to_string(
      nessie_2.IPV6(#(-1, -2, 100, 20_302_302, 2020, -3, 2, 10)),
    )
  should.equal(r, Error("einval"))
}

pub fn ipv4_string_to_address_succeeds_test() {
  let r = nessie_2.string_to_ip("1.2.3.4")
  should.equal(r, Ok(nessie_2.IPV4(#(1, 2, 3, 4))))
}

pub fn ipv4_string_to_address_fails_for_invalid_ip_test() {
  let r = nessie_2.string_to_ip("1.2.3.256")
  should.equal(r, Error("einval"))
}

pub fn ipv6_string_to_address_succeeds_test() {
  let r = nessie_2.string_to_ip("64:c8:12c:0:1f4:258:2bc:320")
  should.equal(r, Ok(nessie_2.IPV6(#(100, 200, 300, 0, 500, 600, 700, 800))))
}

const nessie_a_record_ips = [#(192, 168, 0, 0), #(192, 168, 0, 1)]

const nessie_aaaa_record_ips = [
  #(18_368, 54_663, 59_813, 54_949, 42_880, 55_456, 53_294, 11_238),
  #(39_681, 18_472, 45_578, 35_827, 32_726, 8062, 7641, 42_895),
]

const ckreiling_dev_ns_records = [
  "ns-cloud-d3.googledomains.com", "ns-cloud-d2.googledomains.com",
  "ns-cloud-d4.googledomains.com", "ns-cloud-d1.googledomains.com",
]

pub fn lookup_ipv4_test() {
  let addrs =
    nessie_2.lookup_ipv4("nessie.ckreiling.dev", nessie_2.In, [
      nessie_2.Nameservers([#(nessie_2.IPV4(#(1, 1, 1, 1)), 53)]),
    ])

  let expected_addrs = set.from_list(nessie_a_record_ips)
  let addrs = set.from_list(addrs)

  should.equal(expected_addrs, addrs)
}

pub fn lookup_ipv6_test() {
  let addrs =
    nessie_2.lookup_ipv6("nessie.ckreiling.dev", nessie_2.In, [
      nessie_2.Retry(2),
    ])

  let expected_addrs = set.from_list(nessie_aaaa_record_ips)
  let addrs = set.from_list(addrs)

  should.equal(expected_addrs, addrs)
}

pub fn lookup_cname_test() {
  let addr_list =
    nessie_2.lookup("cname.nessie.ckreiling.dev", nessie_2.In, nessie_2.CNAME, [
      nessie_2.Recurse(True),
    ])

  should.equal(addr_list, ["nessie.ckreiling.dev"])
}

pub fn lookup_txt_test() {
  let addr_list =
    nessie_2.lookup("nessie.ckreiling.dev", nessie_2.In, nessie_2.TXT, [])

  should.equal(addr_list, ["Hello, Nessie Test!"])
}

pub fn lookup_mx_test() {
  let addr_list = nessie_2.lookup_mx("nessie.ckreiling.dev", nessie_2.In, [])

  should.equal(addr_list, [nessie_2.MXRecord(10, "test.nessie.ckreiling.dev")])
}

pub fn lookup_soa_test() {
  let addr_list = nessie_2.lookup_soa("ckreiling.dev", nessie_2.In, [])

  let assert [
    nessie_2.SOARecord(_, "cloud-dns-hostmaster.google.com", _, _, _, _, _),
  ] = addr_list
}

pub fn lookup_ns_test() {
  let addr_list =
    nessie_2.lookup("ckreiling.dev", nessie_2.In, nessie_2.NS, [
      nessie_2.TimeoutMillis(1000),
    ])

  let expected_servers = set.from_list(ckreiling_dev_ns_records)
  let servers = set.from_list(addr_list)

  should.equal(expected_servers, servers)
}

pub fn getbyname_ns_test() {
  let assert Ok(hostent) =
    nessie_2.getbyname("ckreiling.dev", nessie_2.NS, nessie_2.Timeout(1000))

  let expected_servers = set.from_list(ckreiling_dev_ns_records)
  let servers = set.from_list(hostent.addr_list)

  should.equal(expected_servers, servers)
}

pub fn getbyname_cname_test() {
  let assert Ok(hostent) =
    nessie_2.getbyname(
      "cname.nessie.ckreiling.dev",
      nessie_2.CNAME,
      nessie_2.Timeout(1000),
    )

  should.equal(hostent.addr_list, ["nessie.ckreiling.dev"])
}

pub fn getbyname_txt_test() {
  let assert Ok(hostent) =
    nessie_2.getbyname(
      "nessie.ckreiling.dev",
      nessie_2.TXT,
      nessie_2.Timeout(1000),
    )

  should.equal(hostent.addr_list, ["Hello, Nessie Test!"])
}

pub fn getbyname_ipv4_test() {
  let assert Ok(hostent) =
    nessie_2.getbyname_ipv4("nessie.ckreiling.dev", nessie_2.Timeout(1000))

  let expected_addrs = set.from_list(nessie_a_record_ips)
  let addrs = set.from_list(hostent.addr_list)

  should.equal(expected_addrs, addrs)
}

pub fn getbyname_ipv6_test() {
  let assert Ok(hostent) =
    nessie_2.getbyname_ipv6("nessie.ckreiling.dev", nessie_2.Timeout(1000))

  let expected_addrs = set.from_list(nessie_aaaa_record_ips)
  let addrs = set.from_list(hostent.addr_list)

  should.equal(expected_addrs, addrs)
}

pub fn getbyname_mx_test() {
  let assert Ok(hostent) =
    nessie_2.getbyname_mx("nessie.ckreiling.dev", nessie_2.Timeout(1000))
  should.equal(hostent.addr_list, [
    nessie_2.MXRecord(10, "test.nessie.ckreiling.dev"),
  ])
}

pub fn getbyname_soa_test() {
  let assert Ok(hostent) =
    nessie_2.getbyname_soa("ckreiling.dev", nessie_2.Timeout(1000))

  let assert [
    nessie_2.SOARecord(_, "cloud-dns-hostmaster.google.com", _, _, _, _, _),
  ] = hostent.addr_list
}
