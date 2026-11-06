#!/usr/bin/env bash
# Gera web/alertas.json e web/decisoes.json a partir do CrowdSec.
# Precisa rodar no servidor onde o CrowdSec está instalado (como root, via cron).
set -euo pipefail
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

cd "$(dirname "$0")/web"

# Remove os logs brutos e guarda só os domínios (target_fqdn) de cada alerta
cscli alerts list -o json --since 30d -l 0 \
  | jq '(. // []) | map(. + {domains: ([.events[]? | .meta[]? | select(.key=="target_fqdn") | .value] | group_by(.) | map({d: .[0], n: length}))} | del(.events))' \
  > alertas.json.tmp
mv alertas.json.tmp alertas.json

cscli decisions list -o json > decisoes.json.tmp
mv decisoes.json.tmp decisoes.json

chmod 644 alertas.json decisoes.json
