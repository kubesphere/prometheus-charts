local kp =
  (import 'kube-prometheus/main.libsonnet') +
  (import './platforms/platforms.libsonnet') +
  (import 'kube-prometheus/addons/anti-affinity.libsonnet') +
  // Uncomment the following imports to enable its patches
  // (import 'kube-prometheus/addons/anti-affinity.libsonnet') +
  // (import 'kube-prometheus/addons/managed-cluster.libsonnet') +
  // (import 'kube-prometheus/addons/node-ports.libsonnet') +
  // (import 'kube-prometheus/addons/static-etcd.libsonnet') +
  // (import 'kube-prometheus/addons/custom-metrics.libsonnet') +
  // (import 'kube-prometheus/addons/external-metrics.libsonnet') +
  // (import 'kube-prometheus/addons/pyrra.libsonnet') +
  {
    values+:: {
      common+: {
        namespace: 'kubesphere-monitoring-system',
        platform:  'whizardTelemetry',
      },
    },
  };

/*
{ 'setup/0namespace-namespace': kp.kubePrometheus.namespace } +
{
  ['setup/prometheus-operator-' + name]: kp.prometheusOperator[name]
  for name in std.filter((function(name) name != 'serviceMonitor' && name != 'prometheusRule'), std.objectFields(kp.prometheusOperator))
} +
// { 'setup/pyrra-slo-CustomResourceDefinition': kp.pyrra.crd } +
// serviceMonitor and prometheusRule are separated so that they can be created after the CRDs are ready
{ 'prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor } +
{ 'prometheus-operator-prometheusRule': kp.prometheusOperator.prometheusRule } +
{ 'kube-prometheus-prometheusRule': kp.kubePrometheus.prometheusRule } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['blackbox-exporter-' + name]: kp.blackboxExporter[name] for name in std.objectFields(kp.blackboxExporter) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) } +
// { ['pyrra-' + name]: kp.pyrra[name] for name in std.objectFields(kp.pyrra) if name != 'crd' } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['kubernetes-' + name]: kp.kubernetesControlPlane[name] for name in std.objectFields(kp.kubernetesControlPlane) } +
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['kubesphere-' + name]: kp.whizardTelemetry.kubesphere[name] for name in std.objectFields(kp.whizardTelemetry.kubesphere)} +
{ ['thanos-ruler-' + name]: kp.whizardTelemetry.thanosRuler[name] for name in std.objectFields(kp.whizardTelemetry.thanosRuler)} +
{ 'etcd-prometheusRule': kp.whizardTelemetry.etcd.prometheusRule } +
{ 'whizard-telemetry-prometheusRule': kp.whizardTelemetry.prometheusRule}
// { ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) }
*/

{ 'grafana-dashboardDefinitions': kp.grafana.dashboardDefinitions } + 
// { 'prometheus-operator-prometheusRule': kp.prometheusOperator.prometheusRule } +
{ 'kube-prometheus-prometheusRule': kp.kubePrometheus.prometheusRule } +
// { 'alertmanager-prometheusRule': kp.alertmanager.prometheusRule } +
{ 'kube-state-metrics-prometheusRule': kp.kubeStateMetrics.prometheusRule } + 
{ 'kubernetes-prometheusRule': kp.kubernetesControlPlane.prometheusRule } +
{ 'node-exporter-prometheusRule': kp.nodeExporter.prometheusRule } +
// { 'prometheus-prometheusRule': kp.prometheus.prometheusRule }+
{ 'whizard-telemetry-prometheusRule': kp.whizardTelemetry.prometheusRule} 
