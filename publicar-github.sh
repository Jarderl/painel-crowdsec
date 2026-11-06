#!/usr/bin/env bash
# Publica o projeto no GitHub em commits organizados, um por componente.
# Uso, dentro da pasta painel-crowdsec:
#   bash publicar-github.sh https://github.com/SEU_USUARIO/SEU_REPO.git
set -e

URL="${1:-}"
[ -n "$URL" ] || read -rp "URL do repositório (https://github.com/USUARIO/REPO.git): " URL
[ -n "$URL" ] || { echo "Informe a URL do repositório."; exit 1; }

[ -f docker-compose.yml ] && [ -d web ] && [ -d scripts ] || { echo "Rode este script dentro da pasta painel-crowdsec."; exit 1; }
command -v git >/dev/null || { echo "Git não encontrado. Instale: sudo apt install -y git"; exit 1; }
if git rev-parse --verify HEAD >/dev/null 2>&1; then
  echo "Esta pasta já tem commits. Para enviar o que já existe, use: git push -u origin main"
  exit 1
fi

NOME="$(git config user.name || true)"
MAIL="$(git config user.email || true)"
if [ -z "$NOME" ] || [ -z "$MAIL" ]; then
  echo "Configure seu nome e e-mail do Git antes:"
  echo '  git config --global user.name "Seu Nome"'
  echo '  git config --global user.email "ID+usuario@users.noreply.github.com"'
  exit 1
fi
echo "Os commits serão assinados como: $NOME <$MAIL>"
echo "Em repositório público, esse e-mail fica visível para todos."
echo "Prefira o e-mail noreply do GitHub (GitHub > Settings > Emails)."
read -rp "Continuar? [s/N] " R
[ "$R" = "s" ] || [ "$R" = "S" ] || { echo "Cancelado."; exit 0; }

for f in web/alertas.json web/decisoes.json nginx/.htpasswd .env; do
  [ -e "$f" ] && echo "Aviso: $f existe, mas está no .gitignore e não será enviado."
done

git init -q
git checkout -q -b main

c() {
  msg="$1"; shift
  git add -- "$@"
  for f in "$@"; do
    case "$f" in *.sh) git update-index --chmod=+x -- "$f" ;; esac
  done
  git commit -q -m "$msg"
  echo "OK  $msg"
}

c "Adiciona .gitignore para dados reais e senhas" .gitignore
c "Adiciona o dashboard do painel CrowdSec" web/index.html
c "Adiciona compose e configuração do nginx" docker-compose.yml nginx/default.conf .env.example
c "Adiciona scripts de instalação e atualização dos dados" scripts/instalar.sh scripts/atualizar.sh
c "Adiciona autenticação com usuário e senha" docker-compose.auth.yml nginx/auth.conf scripts/criar-senha.sh
c "Adiciona documentação e captura de tela do painel" docs
c "Adiciona guia de instalação do painel" README.md

git remote remove origin 2>/dev/null || true
git remote add origin "$URL"
echo
echo "Enviando para $URL"
git push -u origin main
echo
echo "Pronto. Confira no GitHub."
