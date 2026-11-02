#!/usr/bin/env bash
# Prepara a máquina para o finix: instala o Nix e o Docker (e o acesso ao
# Docker sem sudo). Alvo: Ubuntu/Debian. Idempotente.
#
# Uso:
#   ./bootstrap.sh            instala o Nix e o Docker
#   ./bootstrap.sh --bashrc   também faz o ~/.bashrc iniciar o fish
#                             (o chsh não funciona com o authd)
set -euo pipefail

NIX_PROFILE_SCRIPT=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
MARK_BEGIN="# >>> finix: fish >>>"
MARK_END="# <<< finix: fish <<<"

BASHRC_FISH=0
case "${1:-}" in
  "") ;;
  --bashrc) BASHRC_FISH=1 ;;
  -h | --help)
    sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
  *)
    echo "Opção desconhecida: $1 (use --bashrc ou --help)" >&2
    exit 2
    ;;
esac

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

[ "$(id -u)" -ne 0 ] || { echo "Não execute como root; o script usa sudo quando necessário." >&2; exit 1; }
command -v apt-get >/dev/null || { echo "Este script suporta apenas Ubuntu/Debian." >&2; exit 1; }

load_nix() {
  command -v nix >/dev/null && return 0
  # shellcheck disable=SC1090
  [ -r "$NIX_PROFILE_SCRIPT" ] && . "$NIX_PROFILE_SCRIPT"
  command -v nix >/dev/null
}

in_docker_group() {
  getent group docker | cut -d: -f4 | tr ',' '\n' | grep -qxF "$USER"
}

# 1. Nix (já com flakes habilitados pelo instalador da Determinate Systems)
if load_nix; then
  log "Nix já instalado ($(nix --version))"
else
  log "Instalando Nix (Determinate Systems)"
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
fi

# 2. Docker (repositório oficial) e acesso sem sudo
if command -v docker >/dev/null; then
  docker_bin="$(command -v docker)"
  log "Docker já instalado ($docker_bin)"
  if [[ "$docker_bin" == /snap/* ]] || dpkg -s docker.io >/dev/null 2>&1; then
    echo "  aviso: o Docker não veio do repositório oficial (snap ou docker.io); o script não o substitui." >&2
  fi
else
  log "Instalando Docker"
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  # shellcheck disable=SC1091
  CODENAME="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")"
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $CODENAME stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi
sudo systemctl enable --now docker

getent group docker >/dev/null || sudo groupadd docker
if ! in_docker_group; then
  log "Adicionando $USER ao grupo docker"
  sudo usermod -aG docker "$USER"
  DOCKER_RELOGIN=1
fi

# 3. (opcional) ~/.bashrc inicia o fish, instalado depois pelo home-manager
if [ "$BASHRC_FISH" -eq 1 ]; then
  BASHRC="$HOME/.bashrc"
  touch "$BASHRC"
  if grep -qF "$MARK_BEGIN" "$BASHRC"; then
    log "~/.bashrc já tem o bloco do fish"
  else
    log "Configurando ~/.bashrc para iniciar o fish"
    cp -a "$BASHRC" "$BASHRC.finix-backup"
    cat >>"$BASHRC" <<BLOCK

$MARK_BEGIN
FISH_BIN="\$HOME/.nix-profile/bin/fish"
if [[ \$- == *i* && -x "\$FISH_BIN" && -z "\${BASH_EXECUTION_STRING:-}" \\
      && "\$(ps --no-header --pid=\$PPID --format=comm)" != "fish" ]]; then
  shopt -q login_shell && LOGIN_OPTION=--login || LOGIN_OPTION=
  exec "\$FISH_BIN" \$LOGIN_OPTION
fi
$MARK_END
BLOCK
  fi
fi

log "Pronto! Abra um novo terminal e siga o README para configurar o home-manager."
[ -z "${DOCKER_RELOGIN:-}" ] || log "Faça logout/login para o grupo docker valer (ou use 'newgrp docker')."
