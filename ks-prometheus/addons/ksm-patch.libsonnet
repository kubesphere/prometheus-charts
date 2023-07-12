local addArgs(args, name, containers) = std.map(
  function(c) if c.name == name then
    c {
      args+: args,
    }
  else c,
  containers,
);

{
  kubeStateMetrics+: {
    deployment+: {
      spec+: {
        template+: {
          spec+: {
            containers: addArgs(
              [
              '--metric-annotations-allowlist=clusterroles=[kubesphere.io/creator]',
              '--metric-labels-allowlist=namespaces=[kubesphere.io/workspace]',
              |||
                --custom-resource-state-config=spec:
                  resources:
                    - groupVersionKind:
                        group: iam.kubesphere.io
                        kind: "User"
                        version: "v1alpha2"
                      metricNamePrefix: ""
                      metrics:
                        - name: "kubesphere_user_info"
                          help: "information about iam.kubesphere.io/user."
                          each:
                            type: Info
                            info: 
                              labelsFromPath:
                                user: [metadata, name]
                    - groupVersionKind:
                        group: cluster.kubesphere.io
                        kind: "Cluster"
                        version: "v1alpha1"
                      metricNamePrefix: ""
                      metrics:
                        - name: "kubesphere_cluster_info"
                          help: "information about cluster.kubesphere.io/cluster."
                          each:
                            type: Info
                            info: 
                              labelsFromPath:
                                cluster_name: [metadata, name]
                    - groupVersionKind:
                        group: tenant.kubesphere.io
                        kind: "WorkspaceTemplate"
                        version: "v1alpha2"
                      metricNamePrefix: ""
                      metrics:
                        - name: "kubesphere_workspace_template_info"
                          help: "information about tenant.kubesphere.io/workspacetemplate."
                          each:
                            type: Info
                            info: 
                              labelsFromPath:
                                workspace_template: [metadata, name]
                                manager: [spec, template, spec, manager]
              |||],
              'kube-state-metrics',
              super.containers
            ),
          },
        },
      },
    },

    clusterRole+: {
      rules: super.rules+
      [
        {
            apiGroups: ['iam.kubesphere.io'],
            resources: [
            'users',
            ],
            verbs: ['list', 'watch'],
        },
        {
            apiGroups: ['cluster.kubesphere.io'],
            resources: [
            'clusters',
            ],
            verbs: ['list', 'watch'],
        },
        {
            apiGroups: ['tenant.kubesphere.io'],
            resources: [
            'workspacetemplates',
            ],
            verbs: ['list', 'watch'],
        },
      ]

    },

    serviceMonitor+: {
      spec+: {
        endpoints: std.map(
          function(eps)
            if eps.port != 'https-main' then eps
            else eps + {
              metricRelabelings+: [{
                action: 'replace',
                replacement: '$1',
                targetLabel: 'workspace',
                sourceLabels: ['label_kubesphere_io_workspace'],
                regex: '(.*)',
              }],
            },
        super.endpoints),
      },
    },
  },
}
