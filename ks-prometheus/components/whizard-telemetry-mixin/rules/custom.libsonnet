{
  _config+:: {
    kubeStateMetricsSelector: 'job="kube-state-metrics"',
    nodeExporterSelector: 'job="node-exporter"',
    kubeApiserverSelector: 'job="apiserver"',
    kubeletSelector: 'job="kubelet"',
    cadvisorSelector: 'job="kubelet", metrics_path="/metrics/cadvisor"',
    hostNetworkInterfaceSelector: 'device!~"veth.+"',
    hostFilesystemDeviceSelector: 'device=~"/dev/.*",device!~"/dev/loop\\\\d+"',
    clusterLabel: 'cluster',
    podLabel: 'pod',
    etcd_selector: 'job=~".*etcd.*"',
    etcd_instance_labels: 'instance',
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
                        kube_pod_info{%(kubeStateMetricsSelector)s}
                      * on (%(clusterLabel)s, namespace) group_left (workspace)
                        max by (%(clusterLabel)s, namespace, workspace) (kube_namespace_labels{%(kubeStateMetricsSelector)s})
                    * on (%(clusterLabel)s, namespace, pod) group_left (workload, workload_type)
                      max by (%(clusterLabel)s, namespace, pod, workload, workload_type) (
                          label_join(
                            label_join(
                              kube_pod_owner{%(kubeStateMetricsSelector)s,owner_kind!~"ReplicaSet|DaemonSet|StatefulSet|Job"},
                              "workload",
                              "$1",
                              "owner_name"
                            ),
                            "workload_type",
                            "$1",
                            "owner_kind"
                          )
                        or
                            kube_pod_owner{%(kubeStateMetricsSelector)s,owner_kind=~"ReplicaSet|DaemonSet|StatefulSet|Job"}
                          * on (namespace, pod) group_left (workload_type, workload)
                            namespace_workload_pod:kube_pod_owner:relabel
                      )
                  * on (%(clusterLabel)s, namespace, pod) group_left (qos_class)
                    max by (%(clusterLabel)s, namespace, pod, qos_class) (
                      kube_pod_status_qos_class{%(kubeStateMetricsSelector)s} > 0
                    )
                * on (%(clusterLabel)s, node) group_left (role)
                  max by (%(clusterLabel)s, node, role) (
                        kube_node_info{%(kubeStateMetricsSelector)s}
                      * on (%(clusterLabel)s, node) group_left (role)
                        max by (%(clusterLabel)s, node, role) (
                            (
                                kube_node_role{%(kubeStateMetricsSelector)s,role="worker"}
                              unless ignoring (role)
                                kube_node_role{%(kubeStateMetricsSelector)s,role="control-plane"}
                            )
                          or
                            kube_node_role{%(kubeStateMetricsSelector)s,role="control-plane"}
                        )
                    or
                      kube_node_info{%(kubeStateMetricsSelector)s} unless on(%(clusterLabel)s,node) kube_node_role{%(kubeStateMetricsSelector)s}
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
            record: 'node:node_cpu_utilization:ratio',
            expr: |||
              sum by (%(clusterLabel)s, node) (
                  avg by (%(clusterLabel)s, instance, namespace, pod) (
                    sum without (mode) (
                      rate(node_cpu_seconds_total{job="node-exporter",mode!="idle",mode!="iowait",mode!="steal"}[5m])
                    )
                  )
                * on (%(clusterLabel)s, namespace, %(podLabel)s) group_left (node)
                  topk by (%(clusterLabel)s, namespace, %(podLabel)s) (1, node_namespace_pod:kube_pod_info:)
              )
            ||| % $._config,
          },
          {
            record: 'node:node_cpu_utilization:sum',
            expr: |||
              node:node_cpu_utilization:ratio * node:node_num_cpu:sum
            ||| % $._config,
          },        
          {
            record: 'node:node_memory_utilisation:ratio',
            expr: |||
              node:node_memory_used_bytes:sum / node:node_memory_bytes_total:sum
            ||| % $._config,
          },
          {
            record: 'node:node_memory_available_bytes:sum',
            expr: |||
              node:node_memory_bytes_total:sum - node:node_memory_used_bytes:sum
            ||| % $._config,
          },
          {
            record: 'node:node_memory_used_bytes:sum',
            expr: |||
              sum by (%(clusterLabel)s, node) (
                  (
                      node_memory_MemTotal_bytes{%(nodeExporterSelector)s}
                    -
                      (
                          node_memory_MemAvailable_bytes{%(nodeExporterSelector)s}
                        or
                          (
                                node_memory_Buffers_bytes{%(nodeExporterSelector)s} + node_memory_Cached_bytes{%(nodeExporterSelector)s}
                              +
                                node_memory_MemFree_bytes{%(nodeExporterSelector)s}
                            +
                              node_memory_Slab_bytes{%(nodeExporterSelector)s}
                          )
                      )
                  )
                * on (%(clusterLabel)s, namespace, %(podLabel)s) group_left (node)
                  topk by (%(clusterLabel)s, namespace, %(podLabel)s) (1, node_namespace_pod:kube_pod_info:)
              )
            ||| % $._config,
          },           
          {
            record: 'node:node_memory_bytes_total:sum',
            expr: |||
              sum by (%(clusterLabel)s, node) (
                  node_memory_MemTotal_bytes{%(nodeExporterSelector)s}
                * on (%(clusterLabel)s, namespace, %(podLabel)s) group_left (node)
                  topk by (%(clusterLabel)s, namespace, %(podLabel)s) (1, node_namespace_pod:kube_pod_info:)
              )
            ||| % $._config,
          },
          {
            record: 'node:node_device_filesystem_utilisation:ratio',
            expr: |||
              node:node_device_filesystem_used_bytes:sum / node:node_device_filesystem_bytes_total:sum
            ||| % $._config,
          },
          {
            record: 'node:node_device_filesystem_available_bytes:sum',
            expr: |||
              sum by (%(clusterLabel)s, node, device) (
                    max by (%(clusterLabel)s, namespace, %(podLabel)s, instance, device) (
                        node_filesystem_avail_bytes{%(hostFilesystemDeviceSelector)s, %(nodeExporterSelector)s}
                    )
                * on (%(clusterLabel)s, namespace, %(podLabel)s) group_left (node)
                  topk by (%(clusterLabel)s, namespace, %(podLabel)s) (1, node_namespace_pod:kube_pod_info:)
              )
            ||| % $._config,
          },
          {
            record: 'node:node_device_filesystem_used_bytes:sum',
            expr: |||
              sum by (%(clusterLabel)s, node, device) (
                    max by (%(clusterLabel)s, namespace, %(podLabel)s, instance, device) (
                        node_filesystem_size_bytes{%(hostFilesystemDeviceSelector)s, %(nodeExporterSelector)s}
                      -
                        node_filesystem_avail_bytes{%(hostFilesystemDeviceSelector)s, %(nodeExporterSelector)s}
                    )
                * on (%(clusterLabel)s, namespace, %(podLabel)s) group_left (node)
                  topk by (%(clusterLabel)s, namespace, %(podLabel)s) (1, node_namespace_pod:kube_pod_info:)
              )
            ||| % $._config,
          },
          {
            record: 'node:node_device_filesystem_bytes_total:sum',
            expr: |||
              sum by (%(clusterLabel)s, node, device) (
                    max by (%(clusterLabel)s, namespace, %(podLabel)s, instance, device) (
                        node_filesystem_size_bytes{%(hostFilesystemDeviceSelector)s, %(nodeExporterSelector)s}
                    )
                * on (%(clusterLabel)s, namespace, %(podLabel)s) group_left (node)
                  topk by (%(clusterLabel)s, namespace, %(podLabel)s) (1, node_namespace_pod:kube_pod_info:)
              )
            ||| % $._config,
          },
          {
            record: 'node:node_filesystem_utilisation:ratio',
            expr: |||
              node:node_filesystem_used_bytes:sum / node:node_filesystem_bytes_total:sum
            ||| % $._config,
          },
          {
            record: 'node:node_filesystem_available_bytes:sum',
            expr: |||
              sum by (%(clusterLabel)s, node)(node:node_device_filesystem_available_bytes:sum)
            ||| % $._config,
          },
          {
            record: 'node:node_filesystem_used_bytes:sum',
            expr: |||
              sum by (%(clusterLabel)s, node)(node:node_device_filesystem_used_bytes:sum)
            ||| % $._config,
          },
          {
            record: 'node:node_filesystem_bytes_total:sum',
            expr: |||
              sum by (%(clusterLabel)s, node)(node:node_device_filesystem_bytes_total:sum)
            ||| % $._config,
          },
          {
            record: 'node:node_pod_utilisation:ratio',
            expr: |||
              node:node_pod_running_total:sum / node:node_pod_quota:sum
            ||| % $._config,
          },
          {
            record: 'node:node_pod_running_total:sum',
            expr: |||
              count by(%(clusterLabel)s, node) (
                  node_namespace_pod:kube_pod_info:
                  unless on (%(clusterLabel)s, namespace, %(podLabel)s)
                  (kube_pod_status_phase{%(kubeStateMetricsSelector)s, phase=~"Failed|Pending|Unknown|Succeeded"} > 0)
              )
            ||| % $._config,
          },   
          {
            record: 'node:node_pod_total:sum',
            expr: |||
              sum by (%(clusterLabel)s, node) (
                  sum by (%(clusterLabel)s, namespace, %(podLabel)s) (kube_pod_status_scheduled{%(kubeStateMetricsSelector)s} > 0)
                * on (%(clusterLabel)s, namespace, %(podLabel)s) group_left (node)
                  node_namespace_pod:kube_pod_info:
              )
            ||| % $._config,
          },
          {
            record: 'node:node_pod_quota:sum',
            expr: |||
              sum by (%(clusterLabel)s, node) (kube_node_status_allocatable{job="kube-state-metrics",resource="pods"})
            ||| % $._config,
          },
          {
            record: 'node:pod_abnormal_utilisation:ratio',
            expr: |||
              count by (%(clusterLabel)s, node) (
                        node_namespace_pod:kube_pod_info:{node!=""}
                      unless on (%(podLabel)s, namespace, %(clusterLabel)s)
                        (kube_pod_status_phase{job="kube-state-metrics",phase="Succeeded"} > 0)
                    unless on (%(podLabel)s, namespace, %(clusterLabel)s)
                      (
                          (kube_pod_status_ready{condition="true",job="kube-state-metrics"} > 0)
                        and on (%(podLabel)s, namespace, %(clusterLabel)s)
                          (kube_pod_status_phase{job="kube-state-metrics",phase="Running"} > 0)
                      )
                  unless on (%(clusterLabel)s, %(podLabel)s, namespace)
                    kube_pod_container_status_waiting_reason{job="kube-state-metrics",reason="ContainerCreating"} > 0
              )
              /
              count by (%(clusterLabel)s, node) (
                    node_namespace_pod:kube_pod_info:{node!=""}
                  unless on (%(podLabel)s, namespace, %(clusterLabel)s)
                    kube_pod_status_phase{job="kube-state-metrics",phase="Succeeded"} > 0
              )
            ||| % $._config,
          },
          {
            record: 'node:node_load1_per_cpu:ratio',
            expr: |||
              sum by (%(clusterLabel)s, node)(node_load1{%(nodeExporterSelector)s} * on (%(clusterLabel)s, namespace, %(podLabel)s) group_left (node) topk by (%(clusterLabel)s, namespace, %(podLabel)s) (1, node_namespace_pod:kube_pod_info:)) / node:node_num_cpu:sum
            ||| % $._config,
          },
          {
            record: 'node:node_load5_per_cpu:ratio',
            expr: |||
              sum by (%(clusterLabel)s, node)(node_load5{%(nodeExporterSelector)s} * on (%(clusterLabel)s, namespace, %(podLabel)s) group_left (node) topk by (%(clusterLabel)s, namespace, %(podLabel)s) (1, node_namespace_pod:kube_pod_info:)) / node:node_num_cpu:sum
            ||| % $._config,
          },
          {
            record: 'node:node_load15_per_cpu:ratio',
            expr: |||
              sum by (%(clusterLabel)s, node)(node_load15{%(nodeExporterSelector)s} * on (%(clusterLabel)s, namespace, %(podLabel)s) group_left (node) topk by (%(clusterLabel)s, namespace, %(podLabel)s) (1, node_namespace_pod:kube_pod_info:)) / node:node_num_cpu:sum
            ||| % $._config,
          },
          {
            record: 'node:data_volume_iops_reads:sum',
            expr: |||
              sum by (%(clusterLabel)s, node) (
                  sum by (%(clusterLabel)s, instance, namespace, %(podLabel)s) (
                    irate(node_disk_read_bytes_total{%(nodeExporterSelector)s}[5m])
                  )
                * on (%(clusterLabel)s, namespace, %(podLabel)s) group_left (node)
                  topk by (%(clusterLabel)s, namespace, %(podLabel)s) (1, node_namespace_pod:kube_pod_info:)
              )
            ||| % $._config,
          },
          {
            record: 'node:data_volume_iops_writes:sum',
            expr: |||
              sum by (%(clusterLabel)s, node) (
                  sum by (%(clusterLabel)s, instance, namespace, %(podLabel)s) (
                    irate(node_disk_writes_completed_total{%(nodeExporterSelector)s}[5m])
                  )
                * on (%(clusterLabel)s, namespace, %(podLabel)s) group_left (node)
                  topk by (%(clusterLabel)s, namespace, %(podLabel)s) (1, node_namespace_pod:kube_pod_info:)
              )
            ||| % $._config,
          },
          {
            record: 'node:data_volume_throughput_read_bytes:sum_irate',
            expr: |||
              sum by (%(clusterLabel)s, node) (
                  sum by (%(clusterLabel)s, instance, namespace, %(podLabel)s) (
                    irate(node_disk_read_bytes_total{%(nodeExporterSelector)s}[5m])
                  )
                * on (%(clusterLabel)s, namespace, %(podLabel)s) group_left (node)
                  topk by (%(clusterLabel)s, namespace, %(podLabel)s) (1, node_namespace_pod:kube_pod_info:)
              )
            ||| % $._config,
          },
          {
            record: 'node:data_volume_throughput_written_bytes:sum_irate',
            expr: |||
              sum by (%(clusterLabel)s, node) (
                  sum by (%(clusterLabel)s, instance, namespace, %(podLabel)s) (
                    irate(node_disk_written_bytes_total{%(nodeExporterSelector)s}[5m])
                  )
                * on (%(clusterLabel)s, namespace, %(podLabel)s) group_left (node)
                  topk by (%(clusterLabel)s, namespace, %(podLabel)s) (1, node_namespace_pod:kube_pod_info:)
              )
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
              sum by (%(clusterLabel)s, node) (
                  sum by (%(clusterLabel)s, instance, namespace, %(podLabel)s) (
                    node_filesystem_files{%(nodeExporterSelector)s, %(hostFilesystemDeviceSelector)s}
                  )
                * on (%(clusterLabel)s, namespace, %(podLabel)s) group_left (node)
                  topk by (%(clusterLabel)s, namespace, %(podLabel)s) (1, node_namespace_pod:kube_pod_info:)
              )
            ||| % $._config,
          },
          {
            record: 'node:node_inodes_used_total:sum',
            expr: |||
              sum by (%(clusterLabel)s, node) (
                  sum by (%(clusterLabel)s, instance, namespace, %(podLabel)s) (
                    node_filesystem_files{%(nodeExporterSelector)s, %(hostFilesystemDeviceSelector)s} - node_filesystem_files_free{%(nodeExporterSelector)s, %(hostFilesystemDeviceSelector)s}
                  )
                * on (%(clusterLabel)s, namespace, %(podLabel)s) group_left (node)
                  topk by (%(clusterLabel)s, namespace, %(podLabel)s) (1, node_namespace_pod:kube_pod_info:)
              )
            ||| % $._config,
          },
          {
            record: 'node:node_net_transmit_bytes:sum_irate',
            expr: |||
              sum by (%(clusterLabel)s, node) (
                  sum by (%(clusterLabel)s, instance, namespace, %(podLabel)s) (
                    irate(node_network_transmit_bytes_total{%(nodeExporterSelector)s, %(hostNetworkInterfaceSelector)s}[5m])
                  )
                * on (%(clusterLabel)s, namespace, %(podLabel)s) group_left (node)
                  topk by (%(clusterLabel)s, namespace, %(podLabel)s) (1, node_namespace_pod:kube_pod_info:)
              )
            ||| % $._config,
          },
          {
            record: 'node:node_net_receive_bytes:sum_irate',
            expr: |||
              sum by (%(clusterLabel)s, node) (
                  sum by (%(clusterLabel)s, instance, namespace, %(podLabel)s) (
                    irate(node_network_receive_bytes_total{%(nodeExporterSelector)s, %(hostNetworkInterfaceSelector)s}[5m])
                  )
                * on (%(clusterLabel)s, namespace, %(podLabel)s) group_left (node)
                  topk by (%(clusterLabel)s, namespace, %(podLabel)s) (1, node_namespace_pod:kube_pod_info:)
              )
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
              sum by (%(clusterLabel)s, namespace, workload, workload_type) (
                  sum by (%(clusterLabel)s, namespace, pod) (
                    node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate
                  )
                * on (%(clusterLabel)s, namespace, pod) group_left (workload, workload_type)
                  workspace_workload_node:kube_pod_info:
              )
            ||| % $._config,
          },
          {
            record: 'namespace:workload_memory_usage:sum',
            expr: |||
              sum by (%(clusterLabel)s, namespace, workload, workload_type) (
                  sum by (%(clusterLabel)s, namespace, pod) (
                    container_memory_usage_bytes{%(cadvisorSelector)s, image!=""}
                  )
                * on (%(clusterLabel)s, namespace, pod) group_left (workload, workload_type)
                  workspace_workload_node:kube_pod_info:
              )
            ||| % $._config,
          },
          {
            record: 'namespace:workload_memory_wo_cache_usage:sum',
            expr: |||
              sum by (%(clusterLabel)s, namespace, workload, workload_type) (
                  sum by (%(clusterLabel)s, namespace, pod) (
                    node_namespace_pod_container:container_memory_working_set_bytes
                  )
                * on (%(clusterLabel)s, namespace, pod) group_left (workload, workload_type)
                  workspace_workload_node:kube_pod_info:
              )
            ||| % $._config,
          },
          {
            record: 'namespace:workload_net_receive_bytes:sum_irate',
            expr: |||
              sum by (%(clusterLabel)s, namespace, workload, workload_type) (
                  sum by (%(clusterLabel)s, namespace, pod) (
                    irate(container_network_receive_bytes_total{%(cadvisorSelector)s, image!=""}[5m])
                  )
                * on (%(clusterLabel)s, namespace, pod) group_left (workload, workload_type)
                  workspace_workload_node:kube_pod_info:
              )
            ||| % $._config,
          },
          {
            record: 'namespace:workload_net_transmit_bytes:sum_irate',
            expr: |||
              sum by (%(clusterLabel)s, namespace, workload, workload_type) (
                  sum by (%(clusterLabel)s, namespace, pod) (
                    irate(container_network_transmit_bytes_total{%(cadvisorSelector)s, image!=""}[5m])
                  )
                * on (%(clusterLabel)s, namespace, pod) group_left (workload, workload_type)
                  workspace_workload_node:kube_pod_info:
              )
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
              sum by (%(clusterLabel)s, verb)(irate(apiserver_request_total{%(kubeApiserverSelector)s}[5m]))
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
              sum by (%(clusterLabel)s, verb)(irate(apiserver_request_duration_seconds_sum{%(kubeApiserverSelector)s,subresource!="log", verb!~"LIST|WATCH|WATCHLIST|PROXY|CONNECT"}[5m]))  / sum by (%(clusterLabel)s, verb)(irate(apiserver_request_duration_seconds_count{%(kubeApiserverSelector)s, subresource!="log",verb!~"LIST|WATCH|WATCHLIST|PROXY|CONNECT"}[5m])) 
            ||| % $._config,
          },
        ],
      },
      {
        name: 'whizard-telemetry-etcd.rules',
        rules: [
          {
            expr: |||
              sum by(%(clusterLabel)s) (up{%(etcd_selector)s} == 1)
            ||| % $._config,
            record: 'etcd:up:sum',
          },
          {
            expr: |||
              sum(label_replace(sum(changes(etcd_server_leader_changes_seen_total{%(etcd_selector)s}[1h])) by (%(etcd_instance_labels)s, %(clusterLabel)s), "node", "$1", "%(etcd_instance_labels)s", "(.*):.*")) by (node, %(clusterLabel)s)
            ||| % $._config,
            record: 'etcd:etcd_server_leader_changes_seen:sum_changes',
          },
          {
            expr: |||
              sum(label_replace(sum(irate(etcd_server_proposals_failed_total{%(etcd_selector)s}[5m])) by (%(etcd_instance_labels)s, %(clusterLabel)s), "node", "$1", "%(etcd_instance_labels)s", "(.*):.*")) by (node, %(clusterLabel)s)
            ||| % $._config,
            record: 'etcd:etcd_server_proposals_failed:sum_irate',
          },
          {
            expr: |||
              sum(label_replace(sum(irate(etcd_server_proposals_applied_total{%(etcd_selector)s}[5m])) by (%(etcd_instance_labels)s, %(clusterLabel)s), "node", "$1", "%(etcd_instance_labels)s", "(.*):.*")) by (node, %(clusterLabel)s)
            ||| % $._config,
            record: 'etcd:etcd_server_proposals_applied:sum_irate',
          },
          {
            expr: |||
              sum(label_replace(sum(irate(etcd_server_proposals_committed_total{%(etcd_selector)s}[5m])) by (%(etcd_instance_labels)s, %(clusterLabel)s), "node", "$1", "%(etcd_instance_labels)s", "(.*):.*")) by (node, %(clusterLabel)s)
            ||| % $._config,
            record: 'etcd:etcd_server_proposals_committed:sum_irate',
          },
          {
            expr: |||
              sum(label_replace(sum(etcd_server_proposals_pending{%(etcd_selector)s}) by (%(etcd_instance_labels)s, %(clusterLabel)s), "node", "$1", "%(etcd_instance_labels)s", "(.*):.*")) by (node, %(clusterLabel)s)
            ||| % $._config,
            record: 'etcd:etcd_server_proposals_pending:sum',
          },
          {
            expr: |||
              sum(label_replace(etcd_mvcc_db_total_size_in_bytes{%(etcd_selector)s},"node", "$1", "%(etcd_instance_labels)s", "(.*):.*")) by (node, %(clusterLabel)s)
            ||| % $._config,
            record: 'etcd:etcd_mvcc_db_total_size:sum',
          },
          {
            expr: |||
              sum(label_replace(sum(irate(etcd_network_client_grpc_received_bytes_total{%(etcd_selector)s}[5m])) by (%(etcd_instance_labels)s, %(clusterLabel)s), "node", "$1", "%(etcd_instance_labels)s", "(.*):.*")) by (node, %(clusterLabel)s)
            ||| % $._config,
            record: 'etcd:etcd_network_client_grpc_received_bytes:sum_irate',
          },
          {
            expr: |||
              sum(label_replace(sum(irate(etcd_network_client_grpc_sent_bytes_total{%(etcd_selector)s}[5m])) by (%(etcd_instance_labels)s, %(clusterLabel)s), "node", "$1", "%(etcd_instance_labels)s", "(.*):.*")) by (node, %(clusterLabel)s)
            ||| % $._config,
            record: 'etcd:etcd_network_client_grpc_sent_bytes:sum_irate',
          },
          {
            expr: |||
              sum(label_replace(sum(irate(grpc_server_started_total{%(etcd_selector)s,grpc_type="unary"}[5m])) by (%(etcd_instance_labels)s, %(clusterLabel)s), "node", "$1", "%(etcd_instance_labels)s", "(.*):.*")) by (node, %(clusterLabel)s)
            ||| % $._config,
            record: 'etcd:grpc_server_started:sum_irate',
          },
          {
            expr: |||
              sum(label_replace(sum(irate(grpc_server_handled_total{%(etcd_selector)s,grpc_type="unary",grpc_code!="OK"}[5m])) by (%(etcd_instance_labels)s, %(clusterLabel)s), "node", "$1", "%(etcd_instance_labels)s", "(.*):.*")) by (node, %(clusterLabel)s)
            ||| % $._config,
            record: 'etcd:grpc_server_handled:sum_irate',
          },
          {
            expr: |||
              sum(label_replace(sum(irate(grpc_server_msg_received_total{%(etcd_selector)s}[5m])) by (%(etcd_instance_labels)s, %(clusterLabel)s), "node", "$1", "%(etcd_instance_labels)s", "(.*):.*")) by (node, %(clusterLabel)s)
            ||| % $._config,
            record: 'etcd:grpc_server_msg_received:sum_irate',
          },
          {
            expr: |||
              sum(label_replace(sum(irate(grpc_server_msg_sent_total{%(etcd_selector)s}[5m])) by (%(etcd_instance_labels)s, %(clusterLabel)s), "node", "$1", "%(etcd_instance_labels)s", "(.*):.*")) by (node, %(clusterLabel)s)
            ||| % $._config,
            record: 'etcd:grpc_server_msg_sent:sum_irate',
          },
          {
            expr: |||
              sum(label_replace(sum(irate(etcd_disk_wal_fsync_duration_seconds_sum{%(etcd_selector)s}[5m])) by (%(etcd_instance_labels)s, %(clusterLabel)s) / sum(irate(etcd_disk_wal_fsync_duration_seconds_count{%(etcd_selector)s}[5m])) by (%(etcd_instance_labels)s, %(clusterLabel)s), "node", "$1", "%(etcd_instance_labels)s", "(.*):.*")) by (node, %(clusterLabel)s)
            ||| % $._config,
            record: 'etcd:etcd_disk_wal_fsync_duration:avg',
          },
          {
            expr: |||
              sum(label_replace(sum(irate(etcd_disk_backend_commit_duration_seconds_sum{%(etcd_selector)s}[5m])) by (%(etcd_instance_labels)s, %(clusterLabel)s) / sum(irate(etcd_disk_backend_commit_duration_seconds_count{%(etcd_selector)s}[5m])) by (%(etcd_instance_labels)s, %(clusterLabel)s), "node", "$1", "%(etcd_instance_labels)s", "(.*):.*")) by (node, %(clusterLabel)s)
            ||| % $._config,
            record: 'etcd:etcd_disk_backend_commit_duration:avg',
          },
                    {
            expr: |||
              histogram_quantile(0.99, sum(label_replace(sum(irate(etcd_disk_wal_fsync_duration_seconds_bucket{%(etcd_selector)s}[5m])) by (instance, le, %(clusterLabel)s), "node", "$1", "%(etcd_instance_labels)s", "(.*):.*")) by (node, le, %(clusterLabel)s))
            ||| % $._config,
            labels: {
              quantile: "0.99",
            },
            record: 'etcd:etcd_disk_wal_fsync_duration:histogram_quantile',
          },
          {
            expr: |||
              histogram_quantile(0.9, sum(label_replace(sum(irate(etcd_disk_wal_fsync_duration_seconds_bucket{%(etcd_selector)s}[5m])) by (instance, le, %(clusterLabel)s), "node", "$1", "%(etcd_instance_labels)s", "(.*):.*")) by (node, le, %(clusterLabel)s))
            ||| % $._config,
            labels: {
              quantile: "0.9",
            },
            record: 'etcd:etcd_disk_wal_fsync_duration:histogram_quantile',
          },
          {
            expr: |||
              histogram_quantile(0.5, sum(label_replace(sum(irate(etcd_disk_wal_fsync_duration_seconds_bucket{%(etcd_selector)s}[5m])) by (instance, le, %(clusterLabel)s), "node", "$1", "%(etcd_instance_labels)s", "(.*):.*")) by (node, le, %(clusterLabel)s))
            ||| % $._config,
            labels: {
              quantile: "0.5",
            },
            record: 'etcd:etcd_disk_wal_fsync_duration:histogram_quantile',
          },
          {
            expr: |||
              histogram_quantile(0.99, sum(label_replace(sum(irate(etcd_disk_backend_commit_duration_seconds_bucket{%(etcd_selector)s}[5m])) by (instance, le, %(clusterLabel)s), "node", "$1", "%(etcd_instance_labels)s", "(.*):.*")) by (node, le, %(clusterLabel)s))
            ||| % $._config,
            labels: {
              quantile: "0.99",
            },
            record: 'etcd:etcd_disk_backend_commit_duration:histogram_quantile',
          },
          {
            expr: |||
              histogram_quantile(0.9, sum(label_replace(sum(irate(etcd_disk_backend_commit_duration_seconds_bucket{%(etcd_selector)s}[5m])) by (instance, le, %(clusterLabel)s), "node", "$1", "%(etcd_instance_labels)s", "(.*):.*")) by (node, le, %(clusterLabel)s))
            ||| % $._config,
            labels: {
              quantile: "0.9",
            },
            record: 'etcd:etcd_disk_backend_commit_duration:histogram_quantile',
          },
          {
            expr: |||
              histogram_quantile(0.5, sum(label_replace(sum(irate(etcd_disk_backend_commit_duration_seconds_bucket{%(etcd_selector)s}[5m])) by (instance, le, %(clusterLabel)s), "node", "$1", "%(etcd_instance_labels)s", "(.*):.*")) by (node, le, %(clusterLabel)s))
            ||| % $._config,
            labels: {
              quantile: "0.5",
            },
            record: 'etcd:etcd_disk_backend_commit_duration:histogram_quantile',
          },

        ],
      },
    ],
  },
}
