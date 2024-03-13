{{- define "calico-exporter.common.image" -}}
{{- if .Values.image.digest }}
{{- if .Values.image.registry }}
{{- printf "%s/%s:%s@%s" .Values.image.registry .Values.image.repository .Values.image.tag .Values.image.digest }}
{{- else if .Values.global.imageRegistry }}
{{- printf "%s/%s:%s@%s" .Values.global.imageRegistry .Values.image.repository .Values.image.tag .Values.image.digest }}
{{- else if .Values.image.defaultRegistry }}
{{- printf "%s/%s:%s@%s" .Values.image.defaultRegistry .Values.image.repository .Values.image.tag .Values.image.digest }}
{{- else }}
{{- printf "%s:%s@%s" .Values.image.repository .Values.image.tag .Values.image.digest }}
{{- end }}
{{- else }}
{{- if .Values.image.registry }}
{{- printf "%s/%s:%s" .Values.image.registry .Values.image.repository .Values.image.tag }}
{{- else if .Values.global.imageRegistry }}
{{- printf "%s/%s:%s" .Values.global.imageRegistry .Values.image.repository .Values.image.tag }}
{{- else if .Values.image.defaultRegistry }}
{{- printf "%s/%s:%s" .Values.image.defaultRegistry .Values.image.repository .Values.image.tag }}
{{- else }}
{{- printf "%s:%s" .Values.image.repository .Values.image.tag }}
{{- end }}
{{- end }}
{{- end }}

{{- define "calico-exporter.kubeRbacProxy.image" }}
    {{- $imageDict := dict "Values" (dict "image" .Values.kubeRbacProxy.image "global" .Values.global) }}
    {{- include "calico-exporter.common.image" $imageDict }}
{{- end }}

{{- define "calico-exporter.imagePullSecrets" -}}
{{- if .Values.imagePullSecrets }}
    {{- toYaml .Values.imagePullSecrets }}
{{- else if and .Values.global .Values.global.imagePullSecrets }}
    {{- toYaml .Values.global.imagePullSecrets }}
{{- end }}
{{- end -}}