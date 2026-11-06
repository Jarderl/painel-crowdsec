#!/usr/bin/env bash
# Instala o painel neste servidor: gera os dados, agenda a atualização e sobe o container.
# Rode como usuário normal (ele pede sudo quando precisa):  ./instalar.sh
set -e
cd "$(dirname "$0")"
DIR="$(pwd)"

[ "$(id -u)" -ne 0 ] || { echo "Rode como usuário normal, sem sudo."; exit 1; }
command -v docker >/dev/null || { echo "Docker não encontrado. Instale: curl -fsSL https://get.docker.com | sh"; exit 1; }
command -v cscli  >/dev/null || { echo "cscli não encontrado. O CrowdSec está instalado neste servidor?"; exit 1; }
command -v jq     >/dev/null || sudo apt install -y jq

# usa sudo no Docker só se o usuário ainda não estiver no grupo docker
DC="docker compose"
docker info >/dev/null 2>&1 || DC="sudo docker compose"

[ -f .env ] || cp .env.example .env

FILES="-f docker-compose.yml"
if [ -f nginx/.htpasswd ]; then
  FILES="$FILES -f docker-compose.auth.yml"
  echo "Senha encontrada: o painel vai pedir usuário e senha."
else
  echo "Aviso: sem senha. Qualquer pessoa na sua rede abre o painel. Para proteger, rode ./criar-senha.sh e depois ./instalar.sh de novo."
fi

chmod +x atualizar.sh
echo "*/2 * * * * root $DIR/atualizar.sh" | sudo tee /etc/cron.d/painel-crowdsec >/dev/null
sudo chmod 644 /etc/cron.d/painel-crowdsec
sudo "$DIR/atualizar.sh"

$DC $FILES up -d

PORT=$(grep -E '^PORT=' .env | cut -d= -f2)
echo
echo "Pronto. Abra: http://$(hostname -I | awk '{print $1}'):${PORT:-8083}"
echo "Os dados atualizam a cada 2 minutos."
