package main

workload_resources = [
  "Deployment",
  "DaemonSet",
  "StatefulSet",
]

# livenessが指定されていること
deny[msg] {
	input.kind = workload_resources[_]
	c := input.spec.template.spec.containers[_]
	not c.livenessProbe

	msg = sprintf("%sコンテナにlivenessProbeを指定してください", [c.name])
}

# readinessが指定されていること
deny[msg] {
	input.kind = workload_resources[_]
	c := input.spec.template.spec.containers[_]
	not c.readinessProbe

	msg = sprintf("%sコンテナにreadinessProbeを指定してください", [c.name])
}
