# nvim_setup
Install neovim from source
```bash
# neovim
    cd /tmp
    rm -rf /tmp/neovim
    git clone https://github.com/neovim/neovim
    cd neovim
    git checkout stable
    make CMAKE_BUILD_TYPE=RelWithDebInfo
    make install

```
Install Astrovim with my setup

```bash
git clone --depth 1 git@github.com:lfrecalde1/nvim_setup.git ~/.config/nvim
rm -rf ~/.config/nvim/.git
nvim
```


Install clangd inside container for remote developing
```bash
mkdir -p $HOME/clangd-root
cd $HOME/clangd-root

# download the runtime deps you need
apt-get download libgrpc++1 libgrpc10 libabsl20210324 libc-ares2

# extract them into this same folder
for f in *.deb; do dpkg-deb -x "$f" .; done

apt-get download clangd clangd-14
dpkg-deb -x clangd_*_arm64.deb .
dpkg-deb -x clangd-14_*_arm64.deb .

export LD_LIBRARY_PATH=$HOME/clangd-root/usr/lib/aarch64-linux-gnu:$HOME/clangd-root/usr/lib:$LD_LIBRARY_PATH
export PATH="$HOME/clangd-root/usr/bin:$PATH"
$HOME/clangd-root/usr/bin/clangd --version
```

Verify you have clangd by running the following command
```bash
clangd --version
```
