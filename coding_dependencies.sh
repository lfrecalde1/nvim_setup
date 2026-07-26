
#!/usr/bin/env bash

set -Eeuo pipefail

readonly DEV_ROOT="${HOME}/.local"
readonly CLANGD_ROOT="${HOME}/clangd-root"
readonly USER_APT="${CLANGD_ROOT}/apt-user"
readonly NVM_VERSION="v0.40.3"

log() {
    printf '\n==> %s\n' "$*"
}

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        printf 'Required command not found: %s\n' "$1" >&2
        exit 1
    fi
}

add_to_bashrc() {
    local line="$1"
    touch "${HOME}/.bashrc"
    grep -Fqx "$line" "${HOME}/.bashrc" || printf '%s\n' "$line" >> "${HOME}/.bashrc"
}

backup_path() {
    local path="$1"
    local suffix="$2"

    if [[ -e "$path" || -L "$path" ]]; then
        mv "$path" "${path}.bak.${suffix}"
    fi
}

for command_name in apt-get curl dpkg dpkg-deb git make cmake; do
    require_command "$command_name"
done

if [[ "$(dpkg --print-architecture)" != "arm64" ]]; then
    printf 'This script expects an ARM64 container.\n' >&2
    exit 1
fi

mkdir -p "${DEV_ROOT}/bin"

log "Preparing user-local Ubuntu package repository"
mkdir -p \
    "${USER_APT}/lists/partial" \
    "${USER_APT}/cache/archives/partial"

cp /var/lib/dpkg/status "${USER_APT}/status"

cat > "${USER_APT}/sources.list" <<'EOF'
deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports jammy main restricted universe multiverse
deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports jammy-updates main restricted universe multiverse
deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports jammy-security main restricted universe multiverse
EOF

APT_OPTIONS=(
    -o Debug::NoLocking=1
    -o APT::Sandbox::User=root
    -o "Dir::Etc::sourcelist=${USER_APT}/sources.list"
    -o Dir::Etc::sourceparts=-
    -o "Dir::State::Lists=${USER_APT}/lists"
    -o "Dir::State::status=${USER_APT}/status"
    -o "Dir::Cache=${USER_APT}/cache"
)

apt-get "${APT_OPTIONS[@]}" update
apt-get "${APT_OPTIONS[@]}" \
    --download-only \
    --no-install-recommends \
    install clangd-14 lua5.3 liblua5.3-dev luarocks tree

log "Extracting user-local Ubuntu packages"
shopt -s nullglob
package_files=("${USER_APT}"/cache/archives/*.deb)
if ((${#package_files[@]} == 0)); then
    printf 'APT did not download any packages.\n' >&2
    exit 1
fi

for package_file in "${package_files[@]}"; do
    dpkg-deb -x "$package_file" "$CLANGD_ROOT"
done
shopt -u nullglob

mkdir -p "${CLANGD_ROOT}/bin"
ln -sfn "${CLANGD_ROOT}/usr/bin/clangd-14" "${CLANGD_ROOT}/bin/clangd"

export PATH="${CLANGD_ROOT}/bin:${CLANGD_ROOT}/usr/bin:${DEV_ROOT}/bin:${PATH}"
export LD_LIBRARY_PATH="${CLANGD_ROOT}/usr/lib/aarch64-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

add_to_bashrc 'export PATH="$HOME/clangd-root/bin:$HOME/clangd-root/usr/bin:$HOME/.local/bin:$PATH"'
add_to_bashrc 'export LD_LIBRARY_PATH="$HOME/clangd-root/usr/lib/aarch64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"'

log "Installing Rust"
rm -rf /tmp/rust
mkdir -p /tmp/rust
curl --proto '=https' --tlsv1.2 -sSf \
    https://sh.rustup.rs \
    -o /tmp/rust/rustup-init.sh
chmod +x /tmp/rust/rustup-init.sh
/tmp/rust/rustup-init.sh -y --no-modify-path

# shellcheck source=/dev/null
. "${HOME}/.cargo/env"
rustup update

log "Installing Zellij"
cargo install --locked zellij

log "Installing Node.js 20 with nvm"
curl -fsSL \
    "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" \
    -o /tmp/install-nvm.sh
bash /tmp/install-nvm.sh

export NVM_DIR="${HOME}/.nvm"
# shellcheck source=/dev/null
. "${NVM_DIR}/nvm.sh"
nvm install 20
nvm alias default 20

log "Building and installing Neovim"
rm -rf /tmp/neovim
git clone --depth 1 --branch stable https://github.com/neovim/neovim /tmp/neovim
make -C /tmp/neovim CMAKE_BUILD_TYPE=RelWithDebInfo
cmake --install /tmp/neovim/build --prefix "$DEV_ROOT"

log "Installing Neovim configuration"
backup_suffix="$(date +%Y%m%d_%H%M%S)"
backup_path "${HOME}/.config/nvim" "$backup_suffix"
backup_path "${HOME}/.local/share/nvim" "$backup_suffix"
backup_path "${HOME}/.local/state/nvim" "$backup_suffix"
backup_path "${HOME}/.cache/nvim" "$backup_suffix"

mkdir -p "${HOME}/.config"
git clone --depth 1 \
    https://github.com/lfrecalde1/nvim_setup.git \
    "${HOME}/.config/nvim"
rm -rf "${HOME}/.config/nvim/.git"

log "Installed versions"
rustc --version
cargo --version
zellij --version
node --version
npm --version
nvim --version | head -n 1
clangd --version | head -n 1
lua5.3 -v
tree --version

printf '\nInstallation finished. Run: source "%s/.bashrc"\n' "$HOME"
