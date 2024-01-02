{
  _config+:: {
    kubeStateMetricsSelector: 'job="kube-state-metrics"',
    nodeExporterSelector: 'job="node-exporter"',
    kubeApiserverSelector: 'job="apiserver"',
    hostNetworkInterfaceSelector: 'device!~"veth.+"',
    hostFilesystemDeviceSelector: 'device=~"/dev/.*",device!~"/dev/loop\\\\d+"',
    kubeletSelector: 'job="kubelet"',
    nodeLabel: 'node',
    hostIPLabel: 'host_ip',
    clusterLabel: 'cluster',
  },

  prometheusRules+:: {
    groups+: [
      {
        name: 'whizard-telemetry-cluster.rules',
        rules: [
          {
            // pod attribute tuple tuple (cluster, node, workspace, namespace, pod, qos_class, workload, workload_type, node_role, host_ip) ==> 1
            // 
            // must kms version > 2.8.0
            record: 'workspace_workload_node:kube_pod_info:',
            expr: |||
              max by (%(clusterLabel)s, node, workspace, namespace, pod, qos_class, workload, workload_type, role, host_ip) (
                      kube_pod_info * on (cluster, namespace) group_left (workspace) (kube_namespace_labels{%(kubeStateMetricsSelector)s})
                    * on (%(clusterLabel)s, namespace, pod) group_left (workload, workload_type)
                      (
                          label_join(
                            label_join(
                              kube_pod_owner{owner_kind!~"ReplicaSet|DaemonSet|StatefulSet|Job",%(kubeStateMetricsSelector)s},
                              "workload",
                              "$1",
                              "owner_name"
                            ),
                            "workload_type",
                            "$1",
                            "owner_kind"
                          )
                        or
                            kube_pod_owner{owner_kind=~"ReplicaSet|DaemonSet|StatefulSet|Job",%(kubeStateMetricsSelector)s}
                          * on (namespace, pod) group_left (workload_type, workload)
                            namespace_workload_pod:kube_pod_owner:relabel
                      )
                  * on (%(clusterLabel)s, namespace, pod) group_left (qos_class)
                    (kube_pod_status_qos_class{%(kubeStateMetricsSelector)s} > 0)
                * on (%(clusterLabel)s, node) group_left (role)
                  (
                      (kube_node_role{role="worker",%(kubeStateMetricsSelector)s} unless ignoring (role) kube_node_role{role="control-plane",%(kubeStateMetricsSelector)s})
                    or
                      kube_node_role{role="control-plane",%(kubeStateMetricsSelector)s}
                  )
              )
            ||| % $._config
          },
        ],
      },
      {
        name: 'whizard-telemetry-node.rules',
        rules: [
          {
            record: 'node:node_memory_utilisation:ratio',
            expr: |||
              node:node_memory_bytes_used_total:sum / node:node_memory_bytes_total:sum
            ||| % $._config,
          },
          {
            record: 'node:node_memory_bytes_available:sum',
            expr: |||
              node:node_memory_bytes_total:sum - node:node_memory_bytes_used_total:sum
            ||| % $._config,
          },
          {
            record: 'node:node_memory_bytes_used_total:sum',
            expr: |||
              sum by (%(clusterLabel)s, %(nodeLabel)s, instance, %(hostIPLabel)s)(node_memory_MemTotal_bytes{%(nodeExporterSelector)s} -(node_memory_MemAvailable_bytes{%(nodeExporterSelector)s} or (node_memory_Buffers_bytes{%(nodeExporterSelector)s} + node_memory_Cached_bytes{%(nodeExporterSelector)s} + node_memory_MemFree_bytes{%(nodeExporterSelector)s} + node_memory_Slab_bytes{%(nodeExporterSelector)s}))) * on (cluster,node) group_left(role) ((kube_node_role{%(kubeStateMetricsSelector)s, role="worker"} unless ignoring (role) kube_node_role{%(kubeStateMetricsSelector)s, role="control-plane"}) or kube_node_role{%(kubeStateMetricsSelector)s, role="control-plane"})
            ||| % $._config,
          },           
          {
            record: 'node:node_memory_bytes_total:sum',
            expr: |||
              sum by (%(clusterLabel)s, %(nodeLabel)s, instance, %(hostIPLabel)s, role)(node_memory_MemTotal_bytes{%(nodeExporterSelector)s} * on (cluster,node) group_left(role) ((kube_node_role{%(kubeStateMetricsSelector)s, role="worker"} unless ignoring (role) kube_node_role{%(kubeStateMetricsSelector)s, role="control-plane"}) or kube_node_role{%(kubeStateMetricsSelector)s, role="control-plane"}))
            ||| % $._config,
          },
          {
            record: 'node:node_filesystem_utilisation:ratio',
            expr: |||
              node:node_filesystem_bytes_used_total:sum / node:node_filesystem_bytes_total:sum
            ||| % $._config,
          },
          {
            record: 'node:node_filesystem_avaliable_bytes_total:sum',
            expr: |||
              node:node_filesystem_bytes_total:sum - node:node_filesystem_bytes_used_total:sum
            ||| % $._config,
          },
          {
            record: 'node:node_filesystem_bytes_used_total:sum',
            expr: |||
              sum by (%(clusterLabel)s, %(nodeLabel)s, instance, %(hostIPLabel)s, role) (
                max by (%(clusterLabel)s, %(nodeLabel)s, instance, %(hostIPLabel)s, device) (
                    node_filesystem_size_bytes{%(hostFilesystemDeviceSelector)s, %(nodeExporterSelector)s} -
                    node_filesystem_avail_bytes{%(hostFilesystemDeviceSelector)s, %(nodeExporterSelector)s}
                ) * on (cluster,node) group_left(role) ((kube_node_role{%(kubeStateMetricsSelector)s, role="worker"} unless ignoring (role) kube_node_role{%(kubeStateMetricsSelector)s, role="control-plane"}) or kube_node_role{%(kubeStateMetricsSelector)s, role="control-plane"})
              )
            ||| % $._config,
          },
          {
            record: 'node:node_filesystem_bytes_total:sum',
            expr: |||
              sum by (%(clusterLabel)s, %(nodeLabel)s, instance, %(hostIPLabel)s, role) (
                max by (%(clusterLabel)s, %(nodeLabel)s, instance, %(hostIPLabel)s, device) (
                    node_filesystem_size_bytes{%(hostFilesystemDeviceSelector)s, %(nodeExporterSelector)s}
                ) * on (cluster,node) group_left(role) ((kube_node_role{%(kubeStateMetricsSelector)s, role="worker"} unless ignoring (role) kube_node_role{%(kubeStateMetricsSelector)s, role="control-plane"}) or kube_node_role{%(kubeStateMetricsSelector)s, role="control-plane"})
              )
            ||| % $._config,
          },
          {
            record: 'node:node_pod_utilisation:ratio',
            expr: |||
              node:node_pod_total:sum / node:node_pod_quota:sum
            ||| % $._config,
          },   
          {
            record: 'node:node_pod_total:sum',
            expr: |||
              sum by(cluster,node,host_ip,role)(kube_pod_status_scheduled{%(kubeStateMetricsSelector)s, condition="true"} * on(cluster,namespace,pod) group_left(node,host_ip,role) workspace_workload_node:kube_pod_info:)
            ||| % $._config,
          },
          {
            record: 'node:node_pod_quota:sum',
            expr: |||
              sum by (cluster,node,host_ip,role)(kube_node_status_allocatable{%(kubeStateMetricsSelector)s,resource="pods"} * on (cluster, node) (kube_node_status_condition{%(kubeStateMetricsSelector)s, condition="Ready",status="true"}) * on(node, cluster) group_left(host_ip, role) max by(node, host_ip, role, cluster) (workspace_workload_node:kube_pod_info:{node!="",host_ip!=""}))
            ||| % $._config,
          },
          {
            record: 'node:pod_abnormal:ratio',
            expr: |||
              count by (node, host_ip, role, cluster) (node_namespace_pod:kube_pod_info:{node!=""} unless on (pod, namespace, cluster)(kube_pod_status_phase{%(kubeStateMetricsSelector)s, phase="Succeeded"} > 0)unless on (pod, namespace, cluster)((kube_pod_status_ready{%(kubeStateMetricsSelector)s, condition="true"} > 0)and on (pod, namespace, cluster)(kube_pod_status_phase{%(kubeStateMetricsSelector)s, phase="Running"} > 0))unless on (pod, namespace, cluster)kube_pod_container_status_waiting_reason{%(kubeStateMetricsSelector)s, reason="ContainerCreating"} > 0)/count by (node, host_ip, role, cluster) (node_namespace_pod:kube_pod_info:{node!=""}unless on (pod, namespace, cluster)kube_pod_status_phase{%(kubeStateMetricsSelector)s, phase="Succeeded"}> 0)
            ||| % $._config,
          },
          {
            record: 'node:node_load1_per_cpu:ratio',
            expr: |||
              sum by (cluster,node)(node_load1 / on(cluster,node) node:node_num_cpu:sum) *  on(node, cluster) group_left(host_ip, role) max by(node, host_ip, role, cluster) (workspace_workload_node:kube_pod_info:{node!="",host_ip!=""})
            ||| % $._config,
          },
          {
            record: 'node:node_load5_per_cpu:ratio',
            expr: |||
              sum by (cluster,node)(node_load5 / on(cluster,node) node:node_num_cpu:sum) *  on(node, cluster) group_left(host_ip, role) max by(node, host_ip, role, cluster) (workspace_workload_node:kube_pod_info:{node!="",host_ip!=""})
            ||| % $._config,
          },
          {
            record: 'node:node_load15_per_cpu:ratio',
            expr: |||
              sum by (cluster,node)(node_load15 / on(cluster,node) node:node_num_cpu:sum) *  on(node, cluster) group_left(host_ip, role) max by(node, host_ip, role, cluster) (workspace_workload_node:kube_pod_info:{node!="",host_ip!=""})
            ||| % $._config,
          },
          {
            record: 'node:data_volume_iops_reads:sum',
            expr: |||
              sum by (node, %(clusterLabel)s)(irate(node_disk_reads_completed_total{%(nodeExporterSelector)s}[5m])) *  on(node, cluster) group_left(host_ip, role) max by(node, host_ip, role, cluster) (workspace_workload_node:kube_pod_info:{node!="",host_ip!=""})
            ||| % $._config,
          },
          {
            record: 'node:data_volume_iops_writes:sum',
            expr: |||
              sum by (node, %(clusterLabel)s)(irate(node_disk_writes_completed_total{%(nodeExporterSelector)s}[5m])) *  on(node, cluster) group_left(host_ip, role) max by(node, host_ip, role, cluster) (workspace_workload_node:kube_pod_info:{node!="",host_ip!=""})
            ||| % $._config,
          },
          {
            record: 'node:data_volume_throughput_bytes_read:sum',
            expr: |||
              sum by (node, %(clusterLabel)s)(irate(node_disk_read_bytes_total{%(nodeExporterSelector)s}[5m])) *  on(node, cluster) group_left(host_ip, role) max by(node, host_ip, role, cluster) (workspace_workload_node:kube_pod_info:{node!="",host_ip!=""})
            ||| % $._config,
          },
          {
            record: 'node:data_volume_throughput_bytes_written:sum',
            expr: |||
              sum by (node, %(clusterLabel)s)(irate(node_disk_written_bytes_total{%(nodeExporterSelector)s}[5m])) *  on(node, cluster) group_left(host_ip, role) max by(node, host_ip, role, cluster) (workspace_workload_node:kube_pod_info:{node!="",host_ip!=""})
            ||| % $._config,
          },
          {
            record: 'node:node_inodes_utilisation:ratio',
            expr: |||
              node:node_inodes_used_total:sum / node:node_inodes_total:sum
            ||| % $._config,
          }, 
          {
            record: 'node:node_inodes_total:sum',
            expr: |||
              sum by (node, %(clusterLabel)s)(node_filesystem_files{%(nodeExporterSelector)s, %(hostFilesystemDeviceSelector)s}) *  on(node, cluster) group_left(host_ip, role) max by(node, host_ip, role, cluster) (workspace_workload_node:kube_pod_info:{node!="",host_ip!=""})
            ||| % $._config,
          },
          {
            record: 'node:node_inodes_used_total:sum',
            expr: |||
              sum by (node, %(clusterLabel)s)(node_filesystem_files{%(nodeExporterSelector)s, %(hostFilesystemDeviceSelector)s} - node_filesystem_files_free{%(nodeExporterSelector)s, %(hostFilesystemDeviceSelector)s}) *  on(node, cluster) group_left(host_ip, role) max by(node, host_ip, role, cluster) (workspace_workload_node:kube_pod_info:{node!="",host_ip!=""})
            ||| % $._config,
          },
          {
            record: 'node:node_net_bytes_transmitted:sum_irate',
            expr: |||
              sum by (node, %(clusterLabel)s) (irate(node_network_transmit_bytes_total{%(nodeExporterSelector)s,device!~"veth.+"}[5m]))* on(node, cluster) group_left(host_ip, role) max by(node, host_ip, role, cluster) (workspace_workload_node:kube_pod_info:{node!="",host_ip!=""})
            ||| % $._config,
          },
          {
            record: 'node:node_net_bytes_received:sum_irate',
            expr: |||
              sum by (node, %(clusterLabel)s) (irate(node_network_receive_bytes_total{%(nodeExporterSelector)s,device!~"veth.+"}[5m]))* on(node, cluster) group_left(host_ip, role) max by(node, host_ip, role, cluster) (workspace_workload_node:kube_pod_info:{node!="",host_ip!=""})
            ||| % $._config,
          },
        ],
      },
      {
        name: 'whizard-telemetry-namespace.rules',
        rules: [
          {
            record: 'namespace:workload_cpu_usage:sum',
            expr: |||
              sum by(cluster,namespace,workload,workload_type)(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate{} * on(cluster,namespace,pod)group_left(workload,workload_type) workspace_workload_node:kube_pod_info:{})
            ||| % $._config,
          },
          {
            record: 'namespace:workload_memory_usage:sum',
            expr: |||
              sum by(cluster,namespace,workload,workload_type)(container_memory_usage_bytes{image!="",job="kubelet",metrics_path="/metrics/cadvisor"} * on (cluster, namespace, pod) group_left (node) topk by (cluster, namespace, pod) (1, max by (cluster, namespace, pod, node) (kube_pod_info{node!=""}))* on(cluster,namespace,pod)group_left(workload,workload_type) workspace_workload_node:kube_pod_info:{})
            ||| % $._config,
          },
          {
            record: 'namespace:workload_memory_wo_cache_usage:sum',
            expr: |||
              sum by (cluster, namespace,workload,workload_type) (node_namespace_pod_container:container_memory_working_set_bytes{} * on(cluster,namespace,pod)group_left(workload,workload_type) workspace_workload_node:kube_pod_info:{})
            ||| % $._config,
          },
          {
            record: 'namespace:workload_net_bytes_received:sum_irate',
            expr: |||
              sum by (cluster, namespace,workload,workload_type) (irate(container_network_receive_bytes_total{namespace!="", pod!=""}[5m]) * on(cluster,namespace,pod)group_left(workload,workload_type) workspace_workload_node:kube_pod_info:{})
            ||| % $._config,
          },
          {
            record: 'namespace:workload_net_bytes_transmitted:sum_irate',
            expr: |||
              sum by (cluster, namespace,workload,workload_type) (irate(container_network_transmit_bytes_total{namespace!="", pod!=""}[5m]) * on(cluster,namespace,pod)group_left(workload,workload_type) workspace_workload_node:kube_pod_info:{})
            ||| % $._config,
          },
          {
            record: 'namespace:workload_unavailable_replicas:ratio',
            expr: |||
              label_replace(sum(kube_daemonset_status_number_unavailable{%(kubeStateMetricsSelector)s}) by (daemonset, namespace, %(clusterLabel)s) / sum(kube_daemonset_status_desired_number_scheduled{%(kubeStateMetricsSelector)s}) by (daemonset, namespace,%(clusterLabel)s), "workload", "$1", "daemonset", "(.*)")
            ||| % $._config,
            labels: {
              workload_type: 'daemonset',
            },
          },
          {
            record: 'namespace:workload_unavailable_replicas:ratio',
            expr: |||
              label_replace(sum(kube_deployment_status_replicas_unavailable{%(kubeStateMetricsSelector)s}) by (deployment, namespace, %(clusterLabel)s) / sum(kube_deployment_spec_replicas{%(kubeStateMetricsSelector)s}) by (deployment, namespace, %(clusterLabel)s), "workload", "$1", "deployment", "(.*)")
            ||| % $._config,
            labels: {
              workload_type: 'deployment',
            },
          },
          {
            record: 'namespace:workload_unavailable_replicas:ratio',
            expr: |||
              label_replace(1 - sum(kube_statefulset_status_replicas_ready{%(kubeStateMetricsSelector)s}) by (statefulset, namespace, %(clusterLabel)s) / sum(kube_statefulset_status_replicas{%(kubeStateMetricsSelector)s}) by (statefulset, namespace, %(clusterLabel)s), "workload", "$1", "statefulset", "(.*)")
            ||| % $._config,
            labels: {
              workload_type: 'statefulset',
            },
          },
        ]
      },
      {
        name: 'whizard-telemetry-apiserver.rules',
        rules: [
          {
            record: 'apiserver:apiserver_request_total:sum_irate',
            expr: |||
              sum by(%(clusterLabel)s) (irate(apiserver_request_total{%(kubeApiserverSelector)s}[5m]))
            ||| % $._config,
          },
          {
            record: 'apiserver:apiserver_request_total:sum_verb_irate',
            expr: |||
              sum(irate(apiserver_request_total{%(kubeApiserverSelector)s}[5m])) by (verb, %(clusterLabel)s)
            ||| % $._config,
          },
          {
            record: 'apiserver:apiserver_request_duration:avg',
            expr: |||
              sum by(%(clusterLabel)s) (irate(apiserver_request_duration_seconds_sum{%(kubeApiserverSelector)s,subresource!="log", verb!~"LIST|WATCH|WATCHLIST|PROXY|CONNECT"}[5m])) / sum by(%(clusterLabel)s) (irate(apiserver_request_duration_seconds_count{%(kubeApiserverSelector)s, subresource!="log",verb!~"LIST|WATCH|WATCHLIST|PROXY|CONNECT"}[5m]))
            ||| % $._config,
          },
          {
            record: 'apiserver:apiserver_request_duration:avg_by_verb',
            expr: |||
              sum(irate(apiserver_request_duration_seconds_sum{%(kubeApiserverSelector)s,subresource!="log", verb!~"LIST|WATCH|WATCHLIST|PROXY|CONNECT"}[5m])) by (verb, %(clusterLabel)s) / sum(irate(apiserver_request_duration_seconds_count{%(kubeApiserverSelector)s, subresource!="log",verb!~"LIST|WATCH|WATCHLIST|PROXY|CONNECT"}[5m])) by (verb, %(clusterLabel)s)
            ||| % $._config,
          },
        ],
      },
    ],
  },
}
