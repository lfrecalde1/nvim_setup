#!/usr/bin/env bash

set -Eeuo pipefail

readonly NVIM_CONFIG_REPOSITORY="https://github.com/lfrecalde1/nvim_setup.git"

log() {
    printf '\n==> %s\n' "$*"
}

backup_path() {
    local path="$1"
    local suffix="$2"

    if [[ -e "$path" || -L "$path" ]]; then
        mv "$path" "${path}.bak.${suffix}"
    fi
}

log "Checking tools installed in the Singularity image"

required_commands=(
    git
    nvim
    clangd
    rustc
    cargo
    zellij
    node
    npm
    lua5.3
    luarocks
    tree
)

missing_commands=()
for command_name in "${required_commands[@]}"; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        missing_commands+=("$command_name")
    fi
done

if ((${#missing_commands[@]} > 0)); then
    printf 'The Singularity image is missing required commands:\n' >&2
    printf '  %s\n' "${missing_commands[@]}" >&2
    printf 'Rebuild the image with the updated definition file.\n' >&2
    exit 1
fi

log "Backing up the current Neovim configuration and state"

backup_suffix="$(date +%Y%m%d_%H%M%S)"
backup_path "${HOME}/.config/nvim" "$backup_suffix"
backup_path "${HOME}/.local/share/nvim" "$backup_suffix"
backup_path "${HOME}/.local/state/nvim" "$backup_suffix"
backup_path "${HOME}/.cache/nvim" "$backup_suffix"

log "Installing the Neovim configuration"

mkdir -p "${HOME}/.config"
git clone --depth 1 \
    "$NVIM_CONFIG_REPOSITORY" \
    "${HOME}/.config/nvim"
rm -rf "${HOME}/.config/nvim/.git"

log "Runtime setup finished"
printf 'Start Neovim with: nvim\n'
printf 'Inside Neovim, run: :checkhealth\n'
