package main

workload_resources = [
  "Deployment",
  "DaemonSet",
  "StatefulSet",
]

# requestsが指定されていること
deny[msg] {
	input.kind = workload_resources[_]
	c := input.spec.template.spec.containers[_]
	not c.resources.requests

	msg = sprintf("%sコンテナにrequestsを指定してください", [c.name])
}

# limitsが指定されていること
deny[msg] {
	input.kind = workload_resources[_]
	c := input.spec.template.spec.containers[_]
	not c.resources.limits

	msg = sprintf("%sコンテナにlimitsを指定してください", [c.name])
}
