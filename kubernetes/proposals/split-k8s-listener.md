# This is a design proposal for changes in k8s-listener.

Roadmap outlined by Juergen suggests we split k8s-listener.py into 2 standalone components.
First component is to run on Kubernetess master node and dispatch orders to second component,
running on every kube-node.

* Proposed change is to replace `policy_update` call found in `process` function with
`dispatch_orders` call that will retrieve ip addresses of all hosts from romana topology
service, then loop over this addresses and send policy object with romana metadata to
each host via  HTTP POST.
* Introduce optional commadline parameter that would trigger `ListenAndServe` function in `main`
instead of kube-api listener. The only HTTP handler for `ListenAndServe` will accept POST requests,
parse out `policy_definition` from request and call `policy_update`.

# Open questions
* I haven't got final response about starting this in Golang right away. Feedback was positive 
during last meeting but last email from Juergen emphasizes using python to save time. Need final decision.
* Should we relay on romana topology as a source of nodes ip addresses or on kube api? Both have required
information and in any observable future that shouldn't change.
