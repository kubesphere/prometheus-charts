{{- /*
Generated file. Do not change in-place! In order to change this file first read following link:
https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack/hack
*/ -}}
{{- define "rules.names" }}
rules:
  - "etcd"
  - "k8s.rules"
  - "kube-apiserver-availability.rules"
  - "kube-apiserver-burnrate.rules"
  - "kube-apiserver-histogram.rules"
  - "kube-apiserver-slos"
  - "kube-prometheus-general.rules"
  - "kube-prometheus-node-recording.rules"
  - "kube-scheduler.rules"
  - "kubelet.rules"
  - "node-exporter.rules"
  - "node.rules"
  - "prometheus"
  - "etcd.rules"
  - "etcd_histogram.rules"
  - "cluster.rules"
  - "namespace.rules"
  - "apiserver.rules"
  - "controller_manager.rules"
  - "scheduler.rules"
  - "scheduler_histogram.rules"
  - "coredns.rules"
  - "prometheus.rules"
{{- end }}