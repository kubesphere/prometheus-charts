local whizardTelemetryMixin = import '../components/whizard-telemetry.libsonnet';

(import 'kube-prometheus/platforms/kubeadm.libsonnet')+
(import 'kube-prometheus/addons/all-namespaces.libsonnet') +
(import 'kube-prometheus/addons/networkpolicies-disabled.libsonnet') +
(import 'kube-prometheus/addons/static-etcd.libsonnet') +
{
  
  values+:: {
    common+: {
    },
    etcd+:: {
      ips+: [],
      clientCA: '',
      clientKey: '',
      clientCert: '',
    },
  },
  
  whizardTelemetry: whizardTelemetryMixin(
    {
      namespace: $.values.common.namespace,
      mixin+: { ruleLabels: $.values.common.ruleLabels },
    }
  )
}