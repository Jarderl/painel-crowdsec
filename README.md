
![Gráfico de domínios atacados](docs/painel-dominios.png)

# Painel CrowdSec

Dashboard em português para acompanhar o que o CrowdSec está detectando no seu servidor: alertas ao longo do tempo, **domínios atacados**, cenários de ataque, países e IPs de origem, horários e bloqueios ativos.

É uma página estática servida por nginx em um container. Nada sai do seu servidor.

## Requisitos

- Linux com **CrowdSec** instalado (`cscli` funcionando)
- **Docker** com o plugin `docker compose`
- Para o gráfico de domínios: o CrowdSec precisa ler os logs do Nginx Proxy Manager (coleção `crowdsecurity/nginx-proxy-manager`)

## Instalação rápida

```bash
git clone https://github.com/SEU_USUARIO/SEU_REPO.git painel-crowdsec
cd painel-crowdsec
./instalar.sh
```

O `instalar.sh` gera os dados, agenda a atualização a cada 2 minutos (cron) e sobe o container. No fim ele mostra o endereço, por padrão `http://IP-DO-SERVIDOR:8083`.

## Usar só o Docker Compose

Se você prefere não usar o instalador:

```bash
cp .env.example .env        # ajuste a porta, se quiser
sudo ./atualizar.sh         # gera web/alertas.json e web/decisoes.json
docker compose up -d
```

Para os dados continuarem atualizando, agende o `atualizar.sh` (como root):

```bash
echo "*/2 * * * * root $PWD/atualizar.sh" | sudo tee /etc/cron.d/painel-crowdsec
```

## Porta

Edite `PORT` no arquivo `.env` (padrão `8083`) e rode `docker compose up -d` de novo.

## Usuário e senha

```bash
./criar-senha.sh
./instalar.sh        # detecta a senha e liga a autenticação
```

Ou, sem o instalador:

```bash
docker compose -f docker-compose.yml -f docker-compose.auth.yml up -d
```

A senha fica em `nginx/.htpasswd`, que o `.gitignore` já impede de ir para o GitHub. Em `http://` a senha viaja sem criptografia pela rede. Para acesso de fora, ponha o painel atrás do Nginx Proxy Manager com SSL.

## Estrutura

```
docker-compose.yml        container nginx do painel
docker-compose.auth.yml   complemento que liga a senha
nginx/default.conf        configuração sem senha
nginx/auth.conf           configuração com senha
web/index.html            o dashboard
atualizar.sh              gera os dados a partir do CrowdSec
instalar.sh               instala tudo com um comando
criar-senha.sh            cria usuário e senha
```

## O que nunca subir para o GitHub

`web/alertas.json`, `web/decisoes.json` (contêm IPs reais e domínios do seu servidor), `nginx/.htpasswd` e `.env`. O `.gitignore` já cobre os quatro. Confira com `git status` antes do primeiro `git push`.

## Problemas comuns

- **`permission denied` no Docker:** adicione seu usuário ao grupo com `sudo usermod -aG docker $USER`, saia e entre de novo no SSH.
- **`address already in use`:** a porta já está ocupada. Troque `PORT` no `.env`.
- **Painel mostra "Dados de exemplo":** os arquivos de dados ainda não foram gerados. Rode `sudo ./atualizar.sh` e aperte `Ctrl+F5`.
- **Gráfico de domínios vazio:** confira se há domínio nos eventos:
  ```bash
  sudo cscli alerts list -o json -l 50 | jq '[.[].events[]?.meta[]? | select(.key=="target_fqdn")] | length'
  ```
  Se der `0`, verifique se a coleção `crowdsecurity/nginx-proxy-manager` está ativa (`sudo cscli collections list`).
