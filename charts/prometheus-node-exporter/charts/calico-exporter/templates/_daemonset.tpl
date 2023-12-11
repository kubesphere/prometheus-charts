{{/*
# Containers for the calico-exporter daemonset.
*/}}
{{- define "calico-exporter.daemonset.containers" -}}
- args:
    - --logtostderr
    - --secure-listen-address=0.0.0.0:{{ .Values.CalicoExporter.service.targetPort }}
    - --tls-cipher-suites=TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305
    - --upstream=http://127.0.0.1:{{ .Values.CalicoExporter.service.innerPort }}/
  image: "{{ .Values.CalicoExporter.kubeRbacProxy.image }}:{{ .Values.CalicoExporter.kubeRbacProxy.tag }}"
  name: kube-rbac-proxy-calico-exporter
  ports:
    - containerPort: {{ .Values.CalicoExporter.service.targetPort }}
      name: https-metrics
  resources:
{{ toYaml .Values.CalicoExporter.kubeRbacProxy.resources | indent 12 }}
  securityContext:
    runAsGroup: 65532
    runAsNonRoot: true
    runAsUser: 65532
- name: calico-exporter
  env:
    - name: NODENAME
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName
  image: "{{ .Values.CalicoExporter.image.repository }}:{{ .Values.CalicoExporter.image.tag }}"
  imagePullPolicy: {{ .Values.CalicoExporter.image.pullPolicy }}
  args:
    - --web.listen-address=127.0.0.1:{{ .Values.CalicoExporter.service.innerPort }}
    - --collector.enable-collectors=bgp
  resources:
{{ toYaml .Values.CalicoExporter.resources | indent 12 }}
  volumeMounts:
    - name: var-run-calico
      mountPath: /var/run/calico
{{- end }}

{{/*
# Volumes for the calico-exporter daemonset.
*/}}
{{- define "calico-exporter.daemonset.volumes" -}}
- name: var-run-calico
  hostPath:
    path: /var/run/calico
{{- end }}
