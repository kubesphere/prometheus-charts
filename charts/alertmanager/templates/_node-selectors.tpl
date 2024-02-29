{{- define "alertmanager.common.nodeSelectors.nodeSelector" -}}
{{- if and .global .global.nodeSelector }}
    {{- $nodeSelector := .global.nodeSelector -}}
    {{- if .nodeSelector }}
        {{- $nodeSelector = merge .nodeSelector $nodeSelector -}}
    {{- end -}}
    {{- toYaml $nodeSelector }}
{{- else }}
    {{- toYaml .nodeSelector }}
{{- end }}
{{- end -}}

{{- define "alertmanager.nodeSelector" -}}
{{- $_dict := (dict "nodeSelector" .Values.nodeSelector "global" .Values.global) }}
{{- include "alertmanager.common.nodeSelectors.nodeSelector" $_dict }}
{{- end -}}
