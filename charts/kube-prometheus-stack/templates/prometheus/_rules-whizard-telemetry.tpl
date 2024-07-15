{{- /*
Generated file. Do not change in-place! In order to change this file first read following link:
https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack/hack
*/ -}}
{{- define "rules-whizard-telemetry.names" }}
rules:
  - "whizard-telemetry-apiserver.rules"
  - "whizard-telemetry-cluster.rules"
  - "whizard-telemetry-namespace.rules"
  - "whizard-telemetry-node.rules"
  - "whizard-telemetry-etcd.rules"
  - "whizard-telemetry-kube-scheduler.rules"
{{- end }}