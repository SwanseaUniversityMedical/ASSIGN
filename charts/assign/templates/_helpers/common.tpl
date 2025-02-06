{{/*
Construct the `labels.chart` for used by all resources in this chart.
*/}}
{{- define "assign.labels.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
