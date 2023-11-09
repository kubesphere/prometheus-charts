{{- /*
Generated file. Do not change in-place! In order to change this file first read following link:
https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack/hack
*/ -}}
{{- define "rules.names" }}
rules:
  - "kube-prometheus-general.rules"
  - "kube-prometheus-node-recording.rules"
  - "kube-apiserver-availability.rules"
  - "kube-apiserver-burnrate.rules"
  - "kube-apiserver-histogram.rules"
  - "k8s.rules"
  - "kube-scheduler.rules"
  - "node.rules"
  - "kubelet.rules"
  - "node-exporter.rules"
  - "whizard-apiserver-recording.rules"
  - "whizard-cluster-recording.rules"
  - "whizard-node-recording.rules"
{{- end }}