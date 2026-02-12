# Neovim + AstroNvim Setup for ROS 2 C++ Development

This guide describes how to set up **Neovim + AstroNvim** for **ROS 2 C++ development**, including `clangd` installation for remote/Singularity-based workflows and generation of `compile_commands.json` for proper language-server support.

---

## 1. Install Neovim from Source

Building Neovim from source ensures you get a recent, stable version with full feature support.

```bash
cd /tmp
rm -rf /tmp/neovim
git clone https://github.com/neovim/neovim
cd neovim
git checkout stable

make CMAKE_BUILD_TYPE=RelWithDebInfo
sudo make install
```

Verify the installation:

```bash
nvim --version
```


## 2. Install AstroNvim (Custom Configuration)

Clone the custom AstroNvim configuration repository:

```bash

sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  lua5.3 \
  liblua5.3-dev \
  luarocks \
  tree

curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak
mv ~/.local/state/nvim ~/.local/state/nvim.bak
mv ~/.cache/nvim ~/.cache/nvim.bak
git clone --depth 1 https://github.com/lfrecalde1/nvim_setup.git ~/.config/nvim
rm -rf ~/.config/nvim/.git
```

Start Neovim to trigger plugin installation:

```bash
nvim
```

 The first launch may take a few minutes while plugins are downloaded and configured.

---

## 3. Install `clangd` Inside a Container (Remote / Singularity Development)

When working inside a container or on a system without root access, `clangd` can be installed locally in your home directory.

### 3.1 Download and Extract Runtime Dependencies

```bash
mkdir -p $HOME/clangd-root
cd $HOME/clangd-root

# Download runtime dependencies
apt-get download clangd clangd-14
apt-get download libgrpc++1 libgrpc10 libabsl20210324 libc-ares2

# Extract packages
for f in *.deb; do
  dpkg-deb -x "$f" .
done
```

### 3.2 Download and Extract clangd

```bash
apt-get download libclang-cpp14 libllvm14
dpkg-deb -x libclang-cpp14_*_arm64.deb .
dpkg-deb -x libllvm14_*_arm64.deb .
```

### 3.3 Configure Environment Variables

```bash
export LD_LIBRARY_PATH=$HOME/clangd-root/usr/lib/aarch64-linux-gnu:$HOME/clangd-root/usr/lib:$LD_LIBRARY_PATH
export PATH="$HOME/clangd-root/usr/bin:$PATH"
```

Verify the installation:

```bash
clangd --version
```

Expected output (example):

```
Ubuntu clangd version 14.0.0
Platform: aarch64-unknown-linux-gnu
```

---

## 4. Verify clangd Availability

Ensure `clangd` is correctly resolved:

```bash
which clangd
clangd --version
```

If multiple versions exist, make sure the **ARM64-compatible** binary appears first in your `PATH`.

---

## 5. Generate `compile_commands.json` for ROS 2 (Required for clangd)

For proper C++ code intelligence in ROS 2, `clangd` requires a `compile_commands.json` file.

### 5.1 Build ROS 2 Packages with Compilation Database Enabled

```bash
colcon build --cmake-args -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
```

This generates `compile_commands.json` **per package** inside:

```
build/<package_name>/compile_commands.json
```

---

## 6. Merge `compile_commands.json` Files (Recommended)

Clangd expects a single `compile_commands.json` at the **workspace root**.

Place a script named `merge_compile_commands.py` in your ROS 2 workspace root, then run:

```bash
chmod +x merge_compile_commands.py
./merge_compile_commands.py
```

This will generate:

```
<ros2_ws>/compile_commands.json
```

AstroNvim + clangd will now automatically pick up the correct compilation flags for all ROS 2 packages.

---

## Notes and Recommendations

* **Do not use Bear** for ROS 2 unless absolutely necessary; CMake’s native export is more reliable with `colcon`.
* Keep `compile_commands.json` at the workspace root.
* If working inside containers, ensure `$HOME` is bind-mounted.
* You may optionally add a `.clangd` file to the workspace root:

```yaml
CompileFlags:
  CompilationDatabase: .
```
