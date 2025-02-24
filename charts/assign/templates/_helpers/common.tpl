{{/*
Construct the `labels.chart` for used by all resources in this chart.
*/}}
{{- define "assign.labels.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Construct the name of the ydb auth secret.
*/}}
{{- define "assign.ydb.auth.secret" -}}
{{- printf "%s" (or .Values.assign.auth.secret "ydb-uprn-auth-secret") -}}
{{- end -}}
