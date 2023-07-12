local defaults = {
  local defaults = self,
  // Convention: Top-level fields related to CRDs are public, other fields are hidden
  // If there is no CRD for the component, everything is hidden in defaults.
  name:: 'whizard-telemetry',
  namespace:: error 'must provide namespace',
  commonLabels:: {
    'app.kubernetes.io/name': 'whizard-telemetry',
    'app.kubernetes.io/part-of': 'whizard-telemetry',
  },

  mixin:: {
    ruleLabels: {},
    _config: {
      runbookURLPattern: 'https://runbooks.prometheus-operator.dev/runbooks/node/%s',
    },
  },
};


function(params) {
  local ne = self,
  _config:: defaults + params,
  // Safety check
  assert std.isObject(ne._config.mixin._config),
  _metadata:: {
    name: ne._config.name,
    namespace: ne._config.namespace,
    labels: ne._config.commonLabels,
  },

  mixin:: (import './whizard-telemetry-mixin/mixin.libsonnet') +
          (import 'github.com/kubernetes-monitoring/kubernetes-mixin/lib/add-runbook-links.libsonnet') {
            _config+:: ne._config.mixin._config,
          },

  prometheusRule: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'PrometheusRule',
    metadata: ne._metadata {
      labels+: ne._config.mixin.ruleLabels,
      name: ne._config.name + '-rules',
    },
    spec: {
      local r = if std.objectHasAll(ne.mixin, 'prometheusRules') then ne.mixin.prometheusRules.groups else [],
      local a = if std.objectHasAll(ne.mixin, 'prometheusAlerts') then ne.mixin.prometheusAlerts.groups else [],
      groups: a + r,
    },
  },





}