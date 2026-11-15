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
# arm64-конфиг добавлен патчем patches/0001-arm64-makedefs.patch (платформа MacOSX, SDK macosx).
export SDKROOT="${SDKROOT:-macosx}"
export ARCH_CONFIGS="${ARCH_CONFIGS:-ARM64}"
export MACHINE_CONFIGS="${MACHINE_CONFIGS:-NONE}"   # свой конфиг для virt: см. NOTES
export KERNEL_CONFIGS="${KERNEL_CONFIGS:-RELEASE}"

cd "$XNU"
set +e
make SDKROOT="$SDKROOT" ARCH_CONFIGS="$ARCH_CONFIGS" \
     MACHINE_CONFIGS="$MACHINE_CONFIGS" KERNEL_CONFIGS="$KERNEL_CONFIGS" \
     DSTROOT="$OUT" BUILD_WERROR=0 "$@" > "$OUT/build.log" 2>&1
RC=$?
if [ $RC -ne 0 ]; then
  echo "=== первая ошибка (контекст) ==="
  grep -nE "error:|\*\*\*|fatal|No such file|not found|Undefined|cannot" "$OUT/build.log" \
    | grep -vE "ctfconvert|ctfmerge|ctf_insert|xcrun: error" | head -n 5
  N=$(grep -nE "error:|\*\*\*" "$OUT/build.log" | grep -vE "ctf|xcrun: error" | head -n 1 | cut -d: -f1)
  [ -n "$N" ] && sed -n "$((N>30?N-30:1)),$((N+5))p" "$OUT/build.log"
  echo "=== конец лога ==="
  tail -n 25 "$OUT/build.log"
fi
echo "make rc=$RC (полный лог: build/build.log)"
exit $RC
