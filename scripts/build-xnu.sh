#!/bin/sh
# Сборка XNU (arm64) на macOS с Xcode. Из Linux не работает.
set -e
cd "$(dirname "$0")/.."
ROOT=$(pwd); XNU="$ROOT/src/xnu"; OUT="$ROOT/build"
[ "$(uname)" = Darwin ] || { echo "Нужен macOS (Xcode)."; exit 1; }
[ -d "$XNU" ] || { echo "Сначала: scripts/fetch-sources.sh"; exit 1; }
mkdir -p "$OUT"

for p in "$ROOT"/patches/*.patch; do
  [ -f "$p" ] || continue
  (cd "$XNU" && patch -p1 -N < "$p") || echo "patch $p: уже применён или конфликт"
done

# Для QEMU положи platform/pe_virt.c в src/xnu/pexpert/arm/ (см. patches/NOTES.md п.4).
export SDKROOT="${SDKROOT:-macosx}"
export ARCH_CONFIGS="${ARCH_CONFIGS:-ARM64}"
export MACHINE_CONFIGS="${MACHINE_CONFIGS:-T8002}"   # свой конфиг для virt: см. NOTES
export KERNEL_CONFIGS="${KERNEL_CONFIGS:-RELEASE}"

cd "$XNU"
make SDKROOT="$SDKROOT" ARCH_CONFIGS="$ARCH_CONFIGS" \
     MACHINE_CONFIGS="$MACHINE_CONFIGS" KERNEL_CONFIGS="$KERNEL_CONFIGS" \
     DSTROOT="$OUT" "$@"
echo "Готово: $OUT"
