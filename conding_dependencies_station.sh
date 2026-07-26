#!/usr/bin/env bash

set -Eeuo pipefail

readonly NVIM_CONFIG_REPO="https://github.com/lfrecalde1/nvim_setup.git"
readonly LOCAL_PREFIX="${HOME}/.local"
readonly NVIM_PREFIX="${LOCAL_PREFIX}/opt/neovim"
readonly BASHRC="${HOME}/.bashrc"

log() {
  printf '\n==> %s\n' "$*"
}

append_line_once() {
  local line="$1"
  local file="$2"

  touch "${file}"
  grep -Fqx "${line}" "${file}" || printf '%s\n' "${line}" >> "${file}"
}

backup_if_present() {
  local path="$1"
  local backup_suffix="$2"

  if [[ -e "${path}" || -L "${path}" ]]; then
    mv "${path}" "${path}.bak-${backup_suffix}"
    printf 'Backed up %s to %s\n' "${path}" "${path}.bak-${backup_suffix}"
  fi
}

export PATH="${LOCAL_PREFIX}/bin:${HOME}/.cargo/bin:${PATH}"
mkdir -p "${LOCAL_PREFIX}/bin" "${LOCAL_PREFIX}/opt"

log "Installing system packages"
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  build-essential \
  ca-certificates \
  clangd \
  cmake \
  curl \
  gettext \
  git \
  liblua5.3-dev \
  lua5.3 \
  luarocks \
  ninja-build \
  pkg-config \
  tree \
  unzip

log "Installing Node.js 20"
node_setup="$(mktemp)"
curl -fsSL https://deb.nodesource.com/setup_20.x -o "${node_setup}"
sudo -E bash "${node_setup}"
rm -f "${node_setup}"
sudo apt-get install -y --no-install-recommends nodejs

log "Installing or updating Rust"
if command -v rustup >/dev/null 2>&1; then
  rustup update
else
  rustup_init="$(mktemp)"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o "${rustup_init}"
  sh "${rustup_init}" -y --no-modify-path
  rm -f "${rustup_init}"
  # shellcheck source=/dev/null
  source "${HOME}/.cargo/env"
  rustup update
fi

log "Installing command-line tools"
npm config set prefix "${LOCAL_PREFIX}"
npm install --global @openai/codex
cargo install --locked zellij

log "Backing up the existing Neovim configuration and data"
backup_suffix="$(date -u +%Y%m%dT%H%M%SZ)"
backup_if_present "${HOME}/.config/nvim" "${backup_suffix}"
backup_if_present "${HOME}/.local/share/nvim" "${backup_suffix}"
backup_if_present "${HOME}/.local/state/nvim" "${backup_suffix}"
backup_if_present "${HOME}/.cache/nvim" "${backup_suffix}"

log "Installing the Neovim configuration"
mkdir -p "${HOME}/.config"
git clone --depth 1 "${NVIM_CONFIG_REPO}" "${HOME}/.config/nvim"
rm -rf "${HOME}/.config/nvim/.git"

log "Building stable Neovim"
build_dir="$(mktemp -d)"
trap 'rm -rf "${build_dir}"' EXIT
git clone --depth 1 --branch stable https://github.com/neovim/neovim.git \
  "${build_dir}/neovim"

make -C "${build_dir}/neovim" \
  CMAKE_BUILD_TYPE=RelWithDebInfo \
  CMAKE_INSTALL_PREFIX="${NVIM_PREFIX}"
make -C "${build_dir}/neovim" install

ln -sfn "${NVIM_PREFIX}/bin/nvim" "${LOCAL_PREFIX}/bin/nvim"

log "Updating the shell PATH"
append_line_once 'export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"' "${BASHRC}"

log "Verifying the installation"
nvim --version | head -n 3
nvim --clean --headless \
  '+lua print("Neovim runtime: " .. vim.env.VIMRUNTIME)' \
  +qa
node --version
npm --version
rustc --version
cargo --version
zellij --version
codex --version
clangd --version | head -n 1

printf '\nInstallation complete. Open a new shell or run:\n'
printf '  export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"\n'
