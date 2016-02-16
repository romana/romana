import httplib
import requests
import sys
import simplejson
import subprocess

url = 'http://192.168.0.10:8080/apis/romana.io/demo/v1/namespaces/default/networkpolicys/?watch=true'
tenant_url = 'http://192.168.0.10:9602/tenants'


def _make_rule(chain_name, text):
    """
    Returns "-A <chain_name> <text>"

    """
    return "-A %s %s" % (chain_name, text)

def _make_u32_match(addr_scheme,
                    from_tenant, from_segment, to_tenant, to_segment):
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


def make_rules(addr_scheme, policy_def):
    """
    Return dictionary with rules that should be pre-pended to given chains.

    The chain names are the keys to the dict, the values are lists of rules.

    """
    rules = {}
    tenant         = policy_def['owner_tenant_id']
    target_segment = policy_def['target_segment_id']
    from_segment   = policy_def['allowFrom']['segment_id']

    # The name for the new policy's chain(s). Need to include the tenant ID to
    # avoid name conflicts.
    policy_chain_name = "ROMANA-T%dP-%s_" % \
        (policy_def['owner_tenant_id'], policy_def['policy_name'])

    # This policy needs to be processed in the forward chain of both interfaces
    # that are involved.
    target_segment_forward_chain = "pani-T%sS%s-FORWARD" % \
        (tenant, target_segment)
    from_segment_forward_chain = "pani-T%sS%s-FORWARD" % \
        (tenant, from_segment)

    rules[target_segment_forward_chain] = [
        _make_rule(target_segment_forward_chain, "-j %s" % policy_chain_name)
    ]
    rules[from_segment_forward_chain] = [
        _make_rule(from_segment_forward_chain, "-j %s" % policy_chain_name)
    ]

    # Assemble the rules for the top-level policy chain. These rules look at
    # the IP addresses (source and dest) and figure out whether this is
    # incoming our outgoing traffic.
    u32_in_match  = _make_u32_match(addr_scheme, tenant, from_segment,
                                    tenant, target_segment)
    u32_out_match = _make_u32_match(addr_scheme, tenant, target_segment,
                                    tenant, from_segment)

    in_chain_name  = policy_chain_name[:-1] + "-IN_"
    out_chain_name = policy_chain_name[:-1] + "-OUT_"

    rules[policy_chain_name] = [
        _make_rule(policy_chain_name, '-m u32 --u32 "%s" -j %s' %
                                           (u32_in_match, in_chain_name)),
        _make_rule(policy_chain_name, '-m u32 --u32 "%s" -j %s' %
                                           (u32_out_match, out_chain_name)),
        _make_rule(policy_chain_name, '-j RETURN')
    ]

    # Assemble the rules for the port/protocol portion of the policy.
    # Note! We currently only support TCP with a given port. No ICMP and no
    # UDP!

    rules[in_chain_name] = [
        _make_rule(in_chain_name,
                   '-p tcp --dport %d --tcp-flags SYN SYN -j ACCEPT' %
                   policy_def['allowFrom']['port']),
        _make_rule(in_chain_name,
                   '-m state --state ESTABLISHED -j ACCEPT'),
        _make_rule(in_chain_name, '-j RETURN')
    ]

    rules[out_chain_name] = [
        _make_rule(out_chain_name,
                   '-p tcp --sport %d --tcp-flags SYN,ACK SYN,ACK -j ACCEPT' %
                   policy_def['allowFrom']['port']),
        _make_rule(out_chain_name,
                   '-m state --state ESTABLISHED -j ACCEPT'),
        _make_rule(out_chain_name, '-j RETURN')
    ]

    return rules

def get_current_iptables():
    """
    Return the current iptables.

    """
    rules = subprocess.check_output(["iptables-save"]).split("\n")
    return rules

def delete_all_rules_for_policy(iptables_rules, policy_name, tenant_id):
    """
    Specify the policy name, such as 'foo'. This will delete all the rules that
    refer to anything related to this rule, such as 'ROMANA-P-foo_',
    'ROMANA-P-foo-IN_', etc.

    """
    full_names = [ 'ROMANA-T%dP-%s%s_' % (tenant_id, policy_name, p)
                        for p in [ "", "-IN", "-OUT" ] ]

    # Only transcribe those lines that don't mention any of the chains
    # related to the policy.
    clean_rules = [ r for r in iptables_rules if not
                            any([ p in r for p in full_names ]) ]

    return clean_rules


def make_new_full_ruleset(current_rules, new_rules):
    """
    Prepends the specified rules in the given chains, if they exist.

    If not, creates the chains.

    Return a new, augmented list of rules, ready to replace the old rules.

    """
    # Start by creating the chains. They are all in the 'filter' section.  The
    # only rules we need to define are the policy rules, which all end with a
    # '_'. The other entries are for existing chains (such as
    # 'ROMANA-T1S2-FORWARD'), so we don't need to define them again.
    new_chains_to_declare = [ k for k in new_rules.keys() if k.endswith('_') ]
    existing_chains = [ k for k in new_rules.keys() if not k.endswith('_') ]

    rules = []
    new_chains_declared = False
    new_rules_defined   = False

    for r in current_rules:
        # The definition of the new chains happens first, towards the top of
        # the rules in the '*filter' section.
        if not new_chains_declared:
            rules.append(r)
            if r == "*filter":
                for c in new_chains_to_declare:
                    rules.append(":%s - [0:0]" % c)
                new_chains_declared = True
            continue

        # Now continue and find the entries of those rules that
        # existed already (such as 'ROMANA-T1S2-FORWARD').
        for i, c in enumerate(existing_chains):
            if r.startswith("-A %s" % c):
                # This is a good place to define the rules for the new chains,
                # if this wasn't done already.
                if not new_rules_defined:
                    for nc in new_chains_to_declare:
                        # For each of the new chains we have a list of rules we
                        # need to define.
                        for nr in new_rules[nc]:
                            rules.append(nr)
                    new_rules_defined = True
                # We pre-pend the rules we have for the existing rule.
                for nr in new_rules[c]:
                    rules.append(nr)
                # We only need to perform any rule insertion at the first
                # occurrence of the chain, so we keep track of whether we
                # dealt with it already or not and skip if we have.
                existing_chains.pop(i)  # We dealt with this chain already
                break

        rules.append(r)

    return rules


def apply_new_ruleset(rules):
    """
    Uses iptables-restore to apply a full, new ruleset.

    """
    p = subprocess.Popen(["iptables-restore"],
                         stdout=subprocess.PIPE, stdin=subprocess.PIPE,
                         stderr=subprocess.PIPE)
    out, err = p.communicate('\n'.join(rules))
    if err:
        print "@@@ ERROR applying these rules..."
        for i, r in enumerate(rules):
            print "%3d: %s" % (i+1, r)
        print
        print "@@@ ERROR applying iptables: ", err
        return False
    else:
        print "@@@ iptables rules successfully applied."
        return True



def policy_update(romana_address_scheme, policy_definition, delete_policy=False):
    """
    Using the romana address scheme and a policy definition as input,
    create a new set of iptables rules and apply them.

    NOTE! Since we do get/edit/write in separate steps, it would be possible
    for someone else to clobber the rules before we have a chance to write
    this. A lock of of some sort, or an otherwise atomic operation needs to be
    implemented here. TODO!

    """

    # Create the new rules, based on the Romana addressing scheme and the
    # policy definition.
    new_rules = make_rules(romana_address_scheme, policy_definition)
    """
    pp = pprint.PrettyPrinter(indent=4)
    pp.pprint(new_rules)
    """

    # LOCK SECTION SHOULD START HERE...
    # Get what iptables currently has
    iptables_rules = get_current_iptables()

    # Remove ALL rules relating in any way to a policy of the specified name.
    clean_rules = \
        delete_all_rules_for_policy(iptables_rules,
                                    policy_definition['policy_name'],
                                    policy_definition['owner_tenant_id'])

    if delete_policy:
        apply_new_ruleset(clean_rules)
        return


    # Create a new rule set that can be applied to iptables
    rules = make_new_full_ruleset(clean_rules, new_rules)

    apply_new_ruleset(rules)

    # LOCK SECTION SHOULD END HERE...


def parse_rule_specs(obj):
    try:
        rule = {}
        rule["src_tenant"] = obj["object"]["metadata"]["labels"]["owner"]
        rule["dst_tenant"] = rule["src_tenant"]
        rule["dst_segment"] = obj["object"]["spec"]["podSelector"]["tier"]
        rule["src_segment"] = obj["object"]["spec"]["allowIncoming"]["from"][0]["pods"]["tier"]
        rule["port"] = obj["object"]["spec"]["allowIncoming"]["toPorts"][0]["port"]
        rule["protocol"] = obj["object"]["spec"]["allowIncoming"]["toPorts"][0]["protocol"]
        return rule
    except Exception, e:
        print "Cannot parse %s: %s" % (obj, e)
        return None

def get_tenants():
    r = requests.get(tenant_url)
    print 'Tenants service returned %s' % r.content
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


def process(s):
    try:
        obj = simplejson.loads(s)
    except Exception as e:
        print "====== could not parse:"
        print s
        print "@@@@ Error: ", str(e)
        return
    op = obj["type"]
    rule = parse_rule_specs(obj)
    if not rule:
        return
    tenants = get_tenants()
    print "Discovered tenants = %s" % tenants
    tenant_id = get_tenant_id_by_name(rule['src_tenant'], tenants)
    print "Discovered tenant_id = %s" % tenant_id
    if not tenant_id:
        print "Tenant %s not found" % rule['src_tenant']
        return
    segments = get_segments(tenant_id)
    print "Discovered segments = %s" % segments
    src_segment_id = get_segment_id_by_name(rule['src_segment'], segments)
    print "Discovered src_segment_id = %s" % src_segment_id
    dst_segment_id = get_segment_id_by_name(rule['dst_segment'], segments)
    print "Discovered dst_segment_id = %s" % dst_segment_id

    policy_definition = {
        "policy_name" : obj['object']['metadata']['name'],
        "owner_tenant_id" : tenant_id,
        "target_segment_id" : dst_segment_id,
        "allowFrom" : {
            "segment_id" : src_segment_id,
            "protocol" : "tcp",
            "port" : obj['object']['spec']['allowIncoming']['toPorts'][0]['port']
        }
    }

    if op == 'ADDED':
        print "Adding policy: ", obj['object']['metadata']['name']
        policy_update(addr_scheme, policy_definition)
    elif op == 'DELETED':
        print "Deleting policy: ", obj['object']['metadata']['name']
        policy_update(addr_scheme, policy_definition, delete_policy=True)
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
