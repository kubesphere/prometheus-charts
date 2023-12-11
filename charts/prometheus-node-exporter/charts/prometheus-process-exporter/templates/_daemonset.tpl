{{/*
# Containers for the prometheus-process-exporter daemonset.
*/}}
{{- define "prometheus-process-exporter.daemonset.containers" -}}
- name: kube-rbac-proxy-process-exporter
  args:
    - --logtostderr
    - --secure-listen-address=0.0.0.0:{{ .Values.ProcessExporter.service.targetPort }}
    - --tls-cipher-suites=TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305
    - --upstream=http://127.0.0.1:{{ .Values.ProcessExporter.service.innerPort }}/

  image: "{{ .Values.ProcessExporter.kubeRbacProxy.image }}:{{ .Values.ProcessExporter.kubeRbacProxy.tag }}"
  ports:
    - containerPort: {{ .Values.ProcessExporter.service.targetPort }}
      name: https-metrics
  resources:
{{ toYaml .Values.ProcessExporter.kubeRbacProxy.resources | indent 12 }}
  securityContext:
    runAsGroup: 65532
    runAsNonRoot: true
    runAsUser: 65532
- name: process-exporter
  image: "{{ .Values.ProcessExporter.image.repository }}:{{ .Values.ProcessExporter.image.tag }}"
  imagePullPolicy: {{ .Values.ProcessExporter.image.pullPolicy }}
  args:
    - --procfs=/host/proc
    - --config.path=/var/process-exporter/config.yml
    - --web.listen-address=0.0.0.0:{{ .Values.ProcessExporter.service.innerPort }}
{{- if .Values.ProcessExporter.extraArgs }}
{{ toYaml .Values.ProcessExporter.extraArgs | indent 12 }}
{{- end }}
  resources:
{{ toYaml .Values.ProcessExporter.resources | indent 12 }}
  volumeMounts:
    - name: proc
      mountPath: /host/proc
      readOnly:  true
    - name: config
      mountPath: /var/process-exporter
          {{- if .Values.ProcessExporter.extraHostVolumeMounts }}
          {{- range $_, $mount := .Values.ProcessExporter.extraHostVolumeMounts }}
    - name: {{ $mount.name }}
      mountPath: {{ $mount.mountPath }}
      readOnly: {{ $mount.readOnly }}
          {{- if $mount.mountPropagation }}
      mountPropagation: {{ $mount.mountPropagation }}
          {{- end }}
          {{- end }}
          {{- end }}
{{- end -}}

{{/*
# Volumes for the prometheus-process-exporter daemonset.
*/}}
{{- define "prometheus-process-exporter.daemonset.volumes" -}}
- name: config
  configMap:
    name: {{ template "prometheus-process-exporter.fullname" . }}
{{- if .Values.ProcessExporter.extraHostVolumeMounts }}
{{- range $_, $mount := .Values.ProcessExporter.extraHostVolumeMounts }}
- name: {{ $mount.name }}
  hostPath:
    path: {{ $mount.hostPath }}
{{- end }}
{{- end }}
{{- end -}}
