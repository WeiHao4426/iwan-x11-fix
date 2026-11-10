#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -m)" != "x86_64" ]]; then
    echo "错误：此脚本目前只支持 amd64/x86_64。" >&2
    exit 1
fi

if [[ ! -x /usr/bin/iwan || ! -f /usr/share/applications/iwan.desktop ]]; then
    echo "错误：未检测到 iWAN，请先安装 iwan_2.4.3_amd64.deb。" >&2
    exit 1
fi

if ! command -v cc >/dev/null 2>&1 || \
   ! printf '#include <X11/Xlib.h>\n' | cc -x c -E - >/dev/null 2>&1; then
    echo "正在安装编译依赖 gcc 和 libx11-dev……"
    sudo apt-get update
    sudo apt-get install -y gcc libx11-dev
fi

tmp_dir="$(mktemp -d)"
cleanup() {
    rm -rf -- "$tmp_dir"
}
trap cleanup EXIT

cat >"$tmp_dir/xinitthreads_iwan.c" <<'EOF'
#include <X11/Xlib.h>

__attribute__((constructor))
static void initialize_xlib_threads(void) {
    XInitThreads();
}
EOF

cc -shared -fPIC -O2 -Wall -Wextra \
    -o "$tmp_dir/libiwan-xinitthreads.so" \
    "$tmp_dir/xinitthreads_iwan.c" -lX11

lib_dir="$HOME/.local/lib/iwan"
lib_file="$lib_dir/libiwan-xinitthreads.so"
desktop_dir="$HOME/.local/share/applications"
desktop_file="$desktop_dir/iwan.desktop"

install -d -m 0755 "$lib_dir" "$desktop_dir"
install -m 0755 "$tmp_dir/libiwan-xinitthreads.so" "$lib_file"

awk -v command="Exec=/usr/bin/env LD_PRELOAD=$lib_file /usr/bin/iwan %u" '
    BEGIN { replaced = 0 }
    /^Exec=/ && !replaced { print command; replaced = 1; next }
    { print }
    END { if (!replaced) print command }
' /usr/share/applications/iwan.desktop >"$tmp_dir/iwan.desktop"

install -m 0644 "$tmp_dir/iwan.desktop" "$desktop_file"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$desktop_dir" >/dev/null 2>&1 || true
fi

echo "修复完成。请关闭旧的 iWAN 窗口，然后从应用菜单重新打开。"
