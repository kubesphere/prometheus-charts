local kp =
  (import 'kube-prometheus/main.libsonnet') +
  (import './platforms/platforms.libsonnet') +
  // (import 'kube-prometheus/addons/anti-affinity.libsonnet') +
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

// recording rules filter
local prometheusRulesWithoutAlerting(prometheusRule) = if prometheusRule.kind != 'PrometheusRule' then null
  else {
    apiVersion: prometheusRule.apiVersion,
    kind: prometheusRule.kind,
    metadata: prometheusRule.metadata,
    spec: {
      groups: [
        {
          name: group.name,
          rules: [
            rule for rule in group.rules if !("alert" in rule)
          ],

        } for group in prometheusRule.spec.groups
      ],
    },
  };

local prometheusRulesRemoveNullGroup(prometheusRule) = if prometheusRule.kind != 'PrometheusRule' then null
  else {
    apiVersion: prometheusRule.apiVersion,
    kind: prometheusRule.kind,
    metadata: prometheusRule.metadata,
    spec: {
      groups: [
        group for group in prometheusRule.spec.groups if group.rules != []
      ],
    },
  };


    
// { 'prometheus-operator-prometheusRule': prometheusRulesRemoveNullGroup(prometheusRulesWithoutAlerting(kp.prometheusOperator.prometheusRule)) } +
// { 'kube-prometheus-prometheusRule': prometheusRulesRemoveNullGroup(prometheusRulesWithoutAlerting(kp.kubePrometheus.prometheusRule)) } +
// { 'alertmanager-prometheusRule': prometheusRulesRemoveNullGroup(prometheusRulesWithoutAlerting(kp.alertmanager.prometheusRule)) } +
// { 'kube-state-metrics-prometheusRule': prometheusRulesRemoveNullGroup(prometheusRulesWithoutAlerting(kp.kubeStateMetrics.prometheusRule)) } + 
// { 'kubernetes-prometheusRule': prometheusRulesRemoveNullGroup(prometheusRulesWithoutAlerting(kp.kubernetesControlPlane.prometheusRule)) } +
// { 'node-exporter-prometheusRule': prometheusRulesRemoveNullGroup(prometheusRulesWithoutAlerting(kp.nodeExporter.prometheusRule)) } +
// { 'prometheus-prometheusRule': prometheusRulesRemoveNullGroup(prometheusRulesWithoutAlerting(kp.prometheus.prometheusRule)) }+
{ 'whizard-telemetry-prometheusRule': prometheusRulesRemoveNullGroup(prometheusRulesWithoutAlerting(kp.whizardTelemetry.prometheusRule)) }


