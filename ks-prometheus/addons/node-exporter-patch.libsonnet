

{
  nodeExporter+: {
    serviceMonitor+: {
      spec+: {
        endpoints: std.map(
          function(eps)
            if eps.port != 'https' then eps
            else eps +  {
              relabelings: [
                {
                    action: 'replace',
                    regex: '(.*)',
                    replacement: '$1',
                    sourceLabels: ['__meta_kubernetes_pod_node_name'],
                    targetLabel: 'instance', 
                },
                {
                    action: 'replace',
                    regex: '(.*)',
                    replacement: '$1',
                    sourceLabels: ['__meta_kubernetes_pod_node_name'],
                    targetLabel: 'node', 
                },
                {
                    action: 'replace',
                    regex: '(.*)',
                    replacement: '$1',
                    sourceLabels: ['__meta_kubernetes_pod_host_ip'],
                    targetLabel: 'host_ip', 
                }
              ],
            },
        super.endpoints),
      },
    },
  }
}