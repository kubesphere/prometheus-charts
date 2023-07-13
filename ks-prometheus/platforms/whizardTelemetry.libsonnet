local whizardTelemetryMixin = import '../components/whizard-telemetry.libsonnet';
local kubesphereMixin =  import '../components/kubesphere.libsonnet';
local etcdMixin = import '../components/etcd.libsonnet';

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
  )+{
  kubesphere: kubesphereMixin(
    {
      namespace: $.values.common.namespace,
      mixin+: { ruleLabels: $.values.common.ruleLabels },
    }
  ),
  etcd: etcdMixin(
    {
      namespace: $.values.common.namespace,
      mixin+: { ruleLabels: $.values.common.ruleLabels },
    }
  ),
  }
}