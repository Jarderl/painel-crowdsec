#!/usr/bin/env bash
# Cria o usuário e a senha do painel (arquivo nginx/.htpasswd, que não vai para o GitHub).
set -e
cd "$(dirname "$0")"
command -v openssl >/dev/null || { echo "openssl não encontrado."; exit 1; }
read -rp "Usuário: " U
read -rsp "Senha: " P; echo
[ -n "$U" ] && [ -n "$P" ] || { echo "Usuário e senha não podem ficar vazios."; exit 1; }
printf '%s:%s\n' "$U" "$(openssl passwd -apr1 "$P")" > nginx/.htpasswd
chmod 644 nginx/.htpasswd
echo "Senha criada. Para ativar, rode ./instalar.sh (ele detecta a senha sozinho)."
