{
  _config+:: {
    cambriconMLUMonitoringSelector: 'job="mlu-monitoring"',
    nvidiaGPUMonitoringSelector: 'job="nvidia-dcgm-exporter"',
    ascendNPUMonitoringSelector: 'job="npu-exporter"',
    kubeStateMetricsSelector: 'job="kube-state-metrics"',
    clusterLabel: 'cluster',
  },

  prometheusRules+:: {
    groups+: [
      {
        name: "whizard-telemetry-cambricon-mlu.rules",
        rules: [
          {
            record: 'node_namespace_pod_container:container_gpu_utilization',
            expr: |||
                sum by (%(clusterLabel)s, node, namespace, pod, container) (
                    mlu_utilization{%(cambriconMLUMonitoringSelector)s} / 100
                  * on (%(clusterLabel)s, uuid) group_left (namespace, pod, container, node)
                    mlu_container{%(cambriconMLUMonitoringSelector)s}
                )
            ||| % $._config,
          },
          {
            record: 'node_namespace_pod_container:container_gpu_memory_usage',
            expr: |||
                sum by (%(clusterLabel)s, node, namespace, pod, container) (
                    mlu_memory_used{%(cambriconMLUMonitoringSelector)s}
                  * on (%(clusterLabel)s, uuid) group_left (namespace, pod, container, node)
                    mlu_container{%(cambriconMLUMonitoringSelector)s}
                )
            ||| % $._config,
          },
          {
            record: 'node:gpu_device:gpu_temperature',
            expr: |||
                label_replace(
                  label_replace(mlu_temperature{%(cambriconMLUMonitoringSelector)s}, "device_num", "mlu${1}", "mlu", "(.*)"),
                  "device_name",
                  "$1",
                  "model",
                  "(.*)"
                )
            ||| % $._config,
          },
          {
            record: 'node:gpu_device:gpu_power_usage',
            expr: |||
                label_replace(
                  label_replace(mlu_power_usage{%(cambriconMLUMonitoringSelector)s}, "device_num", "mlu${1}", "mlu", "(.*)"),
                  "device_name",
                  "$1",
                  "model",
                  "(.*)"
                )
            ||| % $._config,
          },
          {
            record: 'node:gpu_device:gpu_memory_used_bytes',
            expr: |||
                label_replace(
                  label_replace(mlu_memory_used{%(cambriconMLUMonitoringSelector)s}, "device_num", "mlu${1}", "mlu", "(.*)"),
                  "device_name",
                  "$1",
                  "model",
                  "(.*)"
                )
            ||| % $._config,
          },
          {
            record: 'node:gpu_device:gpu_memory_total_bytes',
            expr: |||
                label_replace(
                  label_replace(mlu_memory_total{%(cambriconMLUMonitoringSelector)s}, "device_num", "mlu${1}", "mlu", "(.*)"),
                  "device_name",
                  "$1",
                  "model",
                  "(.*)"
                )
            ||| % $._config,
          },
          {
            record: 'node:gpu_device:gpu_memory_utilization',
            expr: |||
                label_replace(
                  label_replace(mlu_memory_utilization{%(cambriconMLUMonitoringSelector)s} / 100, "device_num", "mlu${1}", "mlu", "(.*)"),
                  "device_name",
                  "$1",
                  "model",
                  "(.*)"
                )
            ||| % $._config,
          },
          {
            record: 'node:gpu_device:gpu_utilization',
            expr: |||
                label_replace(
                  label_replace(mlu_utilization{%(cambriconMLUMonitoringSelector)s} / 100, "device_num", "mlu${1}", "mlu", "(.*)"),
                  "device_name",
                  "$1",
                  "model",
                  "(.*)"
                )
            ||| % $._config,
          },
          {
            record: 'node:node_gpu_allocated_num:sum',
            expr: |||
              sum by (%(clusterLabel)s, node) (
                kube_pod_container_resource_requests{%(kubeStateMetricsSelector)s,resource="cambricon_com_mlu370"}
              )
            ||| % $._config,
          },
          {
            record: 'node:node_gpu_num:sum',
            expr: |||
              sum by(%(clusterLabel)s, node) (
                  kube_node_status_allocatable{%(kubeStateMetricsSelector)s,resource="cambricon_com_mlu370"}
              )
            ||| % $._config,
          },
        ],
      },
      {
        name: "whizard-telemetry-nvidia-gpu.rules",
        rules: [
          {
            record: 'node_namespace_pod_container:container_gpu_utilization',
            expr: |||
                sum by (%(clusterLabel)s, namespace, name, pod, container, node) (
                  label_replace(
                      DCGM_FI_DEV_GPU_UTIL{%(nvidiaGPUMonitoringSelector)s, exported_namespace="",exported_pod=""} / 100
                    or
                      label_replace(
                        label_replace(
                          DCGM_FI_DEV_GPU_UTIL{%(nvidiaGPUMonitoringSelector)s, exported_namespace!="",exported_pod!=""} / 100,
                          "namespace",
                          "$1",
                          "exported_namespace",
                          "(.*)"
                        ),
                        "pod",
                        "$1",
                        "exported_pod",
                        "(.*)"
                      ),
                    "node",
                    "$1",
                    "Hostname",
                    "(.*)"
                  )
                )
            ||| % $._config,
          },
          {
            record: 'node_namespace_pod_container:container_gpu_memory_usage',
            expr: |||
                sum by (%(clusterLabel)s, namespace, name, pod, container, node) (
                  label_replace(
                      DCGM_FI_DEV_FB_USED{%(nvidiaGPUMonitoringSelector)s, exported_namespace="",exported_pod=""} * 1024 * 1024
                    or
                      label_replace(
                        label_replace(
                          DCGM_FI_DEV_FB_USED{%(nvidiaGPUMonitoringSelector)s, exported_namespace!="",exported_pod!=""} * 1024 * 1024,
                          "namespace",
                          "$1",
                          "exported_namespace",
                          "(.*)"
                        ),
                        "pod",
                        "$1",
                        "exported_pod",
                        "(.*)"
                      ),
                    "node",
                    "$1",
                    "Hostname",
                    "(.*)"
                  )
                )
            ||| % $._config,
          },
          {
            record: 'node:gpu_device:gpu_temperature',
            expr: |||
                label_replace(
                  label_replace(
                    label_replace(
                      DCGM_FI_DEV_GPU_TEMP{%(nvidiaGPUMonitoringSelector)s},
                      "device_num",
                      "gpu${1}",
                      "gpu",
                      "(.*)"
                    ),
                    "device_name",
                    "$1",
                    "DCGM_FI_DEV_NAME",
                    "(.*)"
                  ),
                  "node",
                  "$1",
                  "Hostname",
                  "(.*)"
                )
            ||| % $._config,
          },
          {
            record: 'node:gpu_device:gpu_power_usage',
            expr: |||
                label_replace(
                  label_replace(
                    label_replace(
                      DCGM_FI_DEV_POWER_USAGE{%(nvidiaGPUMonitoringSelector)s},
                      "device_num",
                      "gpu${1}",
                      "gpu",
                      "(.*)"
                    ),
                    "device_name",
                    "$1",
                    "DCGM_FI_DEV_NAME",
                    "(.*)"
                  ),
                  "node",
                  "$1",
                  "Hostname",
                  "(.*)"
                )
            ||| % $._config,
          },
          {
            record: 'node:gpu_device:gpu_memory_used_bytes',
            expr: |||
                label_replace(
                  label_replace(
                    label_replace(
                      DCGM_FI_DEV_FB_USED{%(nvidiaGPUMonitoringSelector)s} * 1024 * 1024,
                      "device_num",
                      "gpu${1}",
                      "gpu",
                      "(.*)"
                    ),
                    "device_name",
                    "$1",
                    "DCGM_FI_DEV_NAME",
                    "(.*)"
                  ),
                  "node",
                  "$1",
                  "Hostname",
                  "(.*)"
                )
            ||| % $._config,
          },
          {
            record: 'node:gpu_device:gpu_memory_total_bytes',
            expr: |||
                label_replace(
                  label_replace(
                    label_replace(
                      (DCGM_FI_DEV_FB_USED{%(nvidiaGPUMonitoringSelector)s} + DCGM_FI_DEV_FB_FREE{%(nvidiaGPUMonitoringSelector)s}) * 1024 * 1024,
                      "device_num",
                      "gpu${1}",
                      "gpu",
                      "(.*)"
                    ),
                    "device_name",
                    "$1",
                    "DCGM_FI_DEV_NAME",
                    "(.*)"
                  ),
                  "node",
                  "$1",
                  "Hostname",
                  "(.*)"
                )
            ||| % $._config,
          },
          {
            record: 'node:gpu_device:gpu_memory_utilization',
            expr: |||
                label_replace(
                  label_replace(
                    label_replace(
                      (DCGM_FI_DEV_FB_USED{%(nvidiaGPUMonitoringSelector)s} / (DCGM_FI_DEV_FB_USED{%(nvidiaGPUMonitoringSelector)s} + DCGM_FI_DEV_FB_FREE{%(nvidiaGPUMonitoringSelector)s})),
                      "device_num",
                      "gpu${1}",
                      "gpu",
                      "(.*)"
                    ),
                    "device_name",
                    "$1",
                    "DCGM_FI_DEV_NAME",
                    "(.*)"
                  ),
                  "node",
                  "$1",
                  "Hostname",
                  "(.*)"
                )
            ||| % $._config,
          },
          {
            record: 'node:gpu_device:gpu_utilization',
            expr: |||
                label_replace(
                  label_replace(
                    label_replace(
                      DCGM_FI_DEV_GPU_UTIL{%(nvidiaGPUMonitoringSelector)s} / 100,
                      "device_num",
                      "gpu${1}",
                      "gpu",
                      "(.*)"
                    ),
                    "device_name",
                    "$1",
                    "DCGM_FI_DEV_NAME",
                    "(.*)"
                  ),
                  "node",
                  "$1",
                  "Hostname",
                  "(.*)"
                )
            ||| % $._config,
          },
          {
            record: 'node:node_gpu_allocated_num:sum',
            expr: |||
              sum by (%(clusterLabel)s, node) (
                kube_pod_container_resource_requests{%(kubeStateMetricsSelector)s,resource="nvidia_com_gpu"}
              )
            ||| % $._config,
          },
          {
            record: 'node:node_gpu_num:sum',
            expr: |||
              sum by(%(clusterLabel)s, node) (
                  kube_node_status_allocatable{%(kubeStateMetricsSelector)s,resource="nvidia_com_gpu"}
              )
            ||| % $._config,
          },
        ],
      }
      {
        name: "whizard-telemetry-ascend-npu.rules",
        rules: [
          {
            record: 'node_namespace_pod_container:container_gpu_utilization',
            expr: |||
                sum by (%(clusterLabel)s, namespace, pod, container, node) (
                  label_replace(
                    label_replace(
                      label_replace(
                        container_npu_utilization{container_name!="",exported_namespace!="",%(ascendNPUMonitoringSelector)s,pod_name!=""} / 100,
                        "container",
                        "$1",
                        "container_name",
                        "(.*)"
                      ),
                      "pod",
                      "$1",
                      "pod_name",
                      "(.*)"
                    ),
                    "namespace",
                    "$1",
                    "exported_namespace",
                    "(.*)"
                  )
                )
            ||| % $._config,
          },
          {
            record: 'node_namespace_pod_container:container_gpu_memory_usage',
            expr: |||
                sum by (%(clusterLabel)s, namespace, pod, container, node) (
                  label_replace(
                    label_replace(
                      label_replace(
                        container_npu_used_memory{container_name!="",exported_namespace!="",%(ascendNPUMonitoringSelector)s,pod_name!=""} * 1024 * 1024,
                        "container",
                        "$1",
                        "container_name",
                        "(.*)"
                      ),
                      "pod",
                      "$1",
                      "pod_name",
                      "(.*)"
                    ),
                    "namespace",
                    "$1",
                    "exported_namespace",
                    "(.*)"
                  )
                )
            ||| % $._config,
          },
          {
            record: 'node:gpu_device:gpu_temperature',
            expr: |||
                label_replace(
                  label_replace(npu_chip_info_temperature{%(ascendNPUMonitoringSelector)s}, "device_num", "npu${1}", "id", "(.*)"),
                  "device_name",
                  "$1",
                  "model_name",
                  "(.*)"
                )
            ||| % $._config,
          },
          {
            record: 'node:gpu_device:gpu_power_usage',
            expr: |||
                label_replace(
                  label_replace(npu_chip_info_power{%(ascendNPUMonitoringSelector)s}, "device_num", "npu${1}", "id", "(.*)"),
                  "device_name",
                  "$1",
                  "model_name",
                  "(.*)"
                )
            ||| % $._config,
          },
          {
            record: 'node:gpu_device:gpu_memory_used_bytes',
            expr: |||
                label_replace(
                  label_replace(npu_chip_info_hbm_used_memory{%(ascendNPUMonitoringSelector)s}, "device_num", "npu${1}", "id", "(.*)") * 1024 * 1024,
                  "device_name",
                  "$1",
                  "model_name",
                  "(.*)"
                )
            ||| % $._config,
          },
          {
            record: 'node:gpu_device:gpu_memory_total_bytes',
            expr: |||
                label_replace(
                  label_replace(npu_chip_info_hbm_total_memory{%(ascendNPUMonitoringSelector)s}, "device_num", "npu${1}", "id", "(.*)") * 1024 * 1024,
                  "device_name",
                  "$1",
                  "model_name",
                  "(.*)"
                )
            ||| % $._config,
          },
          {
            record: 'node:gpu_device:gpu_memory_utilization',
            expr: |||
                label_replace(
                  label_replace(
                    npu_chip_info_hbm_used_memory{%(ascendNPUMonitoringSelector)s} / npu_chip_info_hbm_total_memory{%(ascendNPUMonitoringSelector)s},
                    "device_num",
                    "npu${1}",
                    "id",
                    "(.*)"
                  ),
                  "device_name",
                  "$1",
                  "model_name",
                  "(.*)"
                )
            ||| % $._config,
          },
          {
            record: 'node:gpu_device:gpu_utilization',
            expr: |||
                label_replace(
                  label_replace(npu_chip_info_utilization{%(ascendNPUMonitoringSelector)s}, "device_num", "npu${1}", "id", "(.*)") / 100,
                  "device_name",
                  "$1",
                  "model_name",
                  "(.*)"
                )
            ||| % $._config,
          },
          {
            record: 'node:node_gpu_allocated_num:sum',
            expr: |||
              sum by (%(clusterLabel)s, node) (
                kube_pod_container_resource_requests{%(kubeStateMetricsSelector)s,resource="huawei_com_Ascend910"}
              )
            ||| % $._config,
          },
          {
            record: 'node:node_gpu_num:sum',
            expr: |||
              sum by(%(clusterLabel)s, node) (
                  kube_node_status_allocatable{%(kubeStateMetricsSelector)s,resource="huawei_com_Ascend910"}
              )
            ||| % $._config,
          },
        ],
      },
    ],
  },
}
