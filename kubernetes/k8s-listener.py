import httplib
import requests
import sys
import simplejson
from subprocess import call

def hook(r, *args, **kwargs):
    print r

url = 'http://192.168.0.10:8080/apis/romana.io/demo/v1/namespaces/default/networkpolicys/?watch=true'
tenant_url = 'http://192.168.0.10:9602/tenants'

def parse_rule_specs(obj):
    rule = {}
    rule["src_tenant"] = obj["object"]["metadata"]["labels"]["owner"]
    rule["dst_tenant"] = rule["src_tenant"]
    rule["dst_segment"] = obj["object"]["spec"]["podSelector"]["tier"]
    rule["src_segment"] = obj["object"]["spec"]["allowIncoming"]["from"][0]["pods"]["tier"]
    rule["port"] = obj["object"]["spec"]["allowIncoming"]["toPorts"][0]["port"]
    rule["protocol"] = obj["object"]["spec"]["allowIncoming"]["toPorts"][0]["protocol"]
    return rule

def get_tenants():
    r = requests.get(tenant_url)
    return simplejson.loads(r.content)

def get_tenant_id_by_name(name, tenants):
    for tenant in tenants:
        if tenant['Name'] == name:
            return tenant['Id']

def get_segments(tenant_id):
    r = requests.get(tenant_url + '/' + str(tenant_id) + '/segments')
    return simplejson.loads(r.content)

def get_segment_id_by_name(name, segments):
    for segment in segments:
        if segment['Name'] == name:
            return segment['Seq']

addr_scheme = {
    "network_width" : 8,
    "host_width" : 8,
    "tenant_width" : 4,
    "segment_width" : 4,
    "endpoint_width" : 8,

    "network_value" : 10,
}

def _make_u32_match(from_tenant, from_segment, to_tenant, to_segment):
    """
    Creates the obscure u32 match string with bitmasks and all that's needed.

    Something like this:

    "0xc&0xff00ff00=0xa001200&&0x10&0xff00ff00=0xa001200"

    """
    mask = src = dst = 0

    # Full match on net portion.
    mask = ((1<<addr_scheme['network_width'])-1) << 24
    src  = addr_scheme['network_value'] << 24
    dst  = addr_scheme['network_value'] << 24

    # Leaving the host portion empty...

    # Adding the mask and values for tenant
    shift_by = addr_scheme['segment_width'] + addr_scheme['endpoint_width']
    mask |= ((1<<addr_scheme['tenant_width'])-1) << shift_by
    src  |= from_tenant << shift_by
    dst  |= to_tenant << shift_by

    # Adding the mask and values for segment
    shift_by = addr_scheme['endpoint_width']
    mask |= ((1<<addr_scheme['segment_width'])-1) << shift_by
    src  |= from_segment << shift_by
    dst  |= to_segment << shift_by

    return "0xc&0x%(mask)x=0x%(src)x&&0x10&0x%(mask)x=0x%(dst)x" % \
        { "mask" : mask, "src" : src, "dst" : dst }

def makeU32rule(tenant_id, segment_id):
    net = 10
    host_bits = 8
    tenant_bits = 4
    segment_bits = 4
    endpoint_bits = 8
    return "stub"

def make_forward_name(tenant_id, segment_id):
    name = 'ROMANA-T%sS%s-FORWARD' % (tenant_id, segment_id)
    return name

def make_base_rules(firewall_policy_name, src_mask, dst_mask):
    base_rules=[]
    base_rules.append('-A %s -m u32 --u32 %s -j %s-OUT' % (firewall_policy_name, dst_mask, firewall_policy_name))
    base_rules.append('-A %s -m u32 --u32 %s -j %s-IN' % (firewall_policy_name, src_mask, firewall_policy_name))
    base_rules.append('-A %s -j RETURN' % firewall_policy_name)
    return base_rules

def make_out_rules(firewall_policy_name, port):
    out_rules=[]
    out_rules.append('-A %s-OUT -p tcp --dport %s --tcp-flags SYN SYN -j ACCEPT' % (firewall_policy_name, port))
    out_rules.append('-A %s-OUT -m state --state ESTABLISHED -j ACCEPT' % firewall_policy_name)
    out_rules.append('-A %s-OUT -j RETURN' % firewall_policy_name)
    return out_rules

def make_in_rules(firewall_policy_name, port):
    in_rules=[]
    in_rules.append('-A %s-IN -p tcp --sport %s --tcp-flags SYN SYN -j ACCEPT' % (firewall_policy_name, port))
    in_rules.append('-A %s-IN -m state --state ESTABLISHED -j ACCEPT' % firewall_policy_name)
    in_rules.append('-A %s-IN -j RETURN' % firewall_policy_name)
    return in_rules

def make_policy_name(policy_name):
    return 'ROMANA-P-%s' % policy_name

def install_chains(firewall_policy_name):
    base_policy = "iptables -N %s" % firewall_policy_name
    in_policy  = "iptables -N %s-IN" % firewall_policy_name
    out_policy = "iptables -N %s-OUT" % firewall_policy_name
    print base_policy.split()
    print in_policy.split()
    print out_policy.split()
    call(base_policy.split())
    call(in_policy.split())
    call(out_policy.split())

def install_rules(rules):
    for rule in rules:
        full_rule = "iptables %s" % rule
        print full_rule.split()
        call(full_rule.split())

def install_first_jump(forward_chain, firewall_policy_name):
    cmd = "iptables -I  %s 1 -j %s" % (forward_chain.replace("ROMANA","pani"), firewall_policy_name)
    print cmd
    call(cmd.split())

def process(s):
    obj = simplejson.loads(s)
    op = obj["type"]
    details = obj["object"]["spec"]
    if op == 'ADDED':
        rule = parse_rule_specs(obj)
        tenants = get_tenants()
        print "Discovered tenants = %s" % tenants
        tenant_id = get_tenant_id_by_name(rule['src_tenant'], tenants)
        print "Discovered tenant_id = %s" % tenant_id
        segments = get_segments(tenant_id)
        print "Discovered segments = %s" % segments
        src_segment_id = get_segment_id_by_name(rule['src_segment'], segments)
        print "Discovered src_segment_id = %s" % src_segment_id
        dst_segment_id = get_segment_id_by_name(rule['dst_segment'], segments)
        print "Discovered dst_segment_id = %s" % dst_segment_id
        #src_mask = makeU32rule(tenant_id, src_segment_id)
        src_mask = _make_u32_match(tenant_id, src_segment_id, tenant_id, dst_segment_id)
        print "Discovered src_mask = %s" % src_mask
        #dst_mask = makeU32rule(tenant_id, dst_segment_id)
        dst_mask = _make_u32_match(tenant_id, dst_segment_id, tenant_id, src_segment_id)
        print "Discovered dst_mask = %s" % dst_mask
        policy_name = obj["object"]["metadata"]["name"]
        print "Discovered policy_name = %s" % policy_name
        src_fw_name = make_forward_name(tenant_id, src_segment_id)
        print "Discovered src_fw_name = %s" % src_fw_name
        dst_fw_name = make_forward_name(tenant_id, dst_segment_id)
        print "Discovered dst_fw_name = %s" % dst_fw_name
        firewall_policy_name = make_policy_name(policy_name)
        print "Discovered firewall_policy_name = %s" % firewall_policy_name
        base_rules = make_base_rules(firewall_policy_name, src_mask, dst_mask)
        print "Discovered base_rules = %s" % base_rules
        in_rules = make_in_rules(firewall_policy_name, rule['port'])
        print "Discovered in_rules = %s" % in_rules
        out_rules = make_out_rules(firewall_policy_name, rule['port'])
        print "Discovered out_rules = %s" % out_rules
        install_chains(firewall_policy_name)
        install_rules(base_rules)
        install_rules(in_rules)
        install_rules(out_rules)
        install_first_jump(src_fw_name, firewall_policy_name)
        install_first_jump(dst_fw_name, firewall_policy_name)

        print "Added: %s" % rule
    elif op == 'DELETED':
        print "Deleted: %s" % details
    else:
        print "Unknown operation: %s" % op

def main():
    r = requests.get(url, stream=True)
    iter = r.iter_content(1)
    while True:
        len_buf = ""
        while True:
            c = iter.next()
            if c == "\r":
                c2 = iter.next()
                if c2 != "\n":
                    raise "Unexpected %c after \\r" % c2
                break
            else:
                len_buf += c
        len = int(len_buf, 16)
        #        print "Chunk %s" % len
        buf = ""
        for i in range(len):
            buf += iter.next()
        process(buf)
        c = iter.next()
        c2 = iter.next()
        if c != '\r' or c2 != '\n':
            raise "Expected CRLF, got %c%c" % (c, c2)


if __name__ == "__main__":
    main()
