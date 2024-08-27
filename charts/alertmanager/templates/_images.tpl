{{- define "alertmanager.common.images.image" -}}
{{- $registryName := "" }}
{{- if and .global .global.imageRegistry }}
    {{- $registryName = .global.imageRegistry }}
{{- end }}
{{- $repositoryName := .imageRoot.repository -}}
{{- $separator := ":" -}}
{{- $termination := "" -}}
{{- if and .global .global.tag }}
    {{- $termination = .global.tag | toString }}
{{- end }}
{{- if .imageRoot.registry }}
    {{- $registryName = .imageRoot.registry -}}
{{- end -}}
{{- if empty $registryName }}
    {{- if .imageRoot.defaultRegistry }}
        {{- $registryName = .imageRoot.defaultRegistry }}
    {{- end -}}
{{- end -}}
{{- if .imageRoot.tag }}
    {{- $termination = .imageRoot.tag | toString -}}
{{- end -}}
{{- if .imageRoot.digest }}
    {{- $separator = "@" -}}
    {{- $termination = .imageRoot.digest | toString -}}
{{- end -}}
{{- if $registryName }}
    {{- printf "%s/%s%s%s" $registryName $repositoryName $separator $termination -}}
{{- else }}
    {{- printf "%s%s%s" $repositoryName $separator $termination -}}
{{- end }}
{{- end -}}

{{- define "alertmanager.image" -}}
{{- $_dict := (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- if empty $_dict.imageRoot.tag }}
    {{- $_ := set $_dict.imageRoot "tag" .Chart.AppVersion }}
{{- end }}
{{- include "alertmanager.common.images.image" $_dict }}
{{- end -}}

{{- define "alertmanager.configmapReload.image" -}}
{{- $_dict := (dict "imageRoot" .Values.configmapReload.image "global" .Values.global) }}
{{- include "alertmanager.common.images.image" $_dict }}
{{- end -}}

{{- define "alertmanager.imagePullSecrets" -}}
{{- if .Values.imagePullSecrets }}
    {{- toYaml .Values.imagePullSecrets }}
{{- else if and .Values.global .Values.global.imagePullSecrets }}
    {{- toYaml .Values.global.imagePullSecrets }}
{{- end }}
{{- end -}}

{{- define "alertmanager.kubectl.image" -}}
{{- $_dict := (dict "imageRoot" .Values.kubectl.image "global" .Values.global) }}
{{- include "alertmanager.common.images.image" $_dict }}
{{- end -}}