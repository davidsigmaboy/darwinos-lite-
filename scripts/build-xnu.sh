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
  echo "=== ERRORS ==="
  # параллельная сборка перемешивает вывод, поэтому берём только шаблон файл:строка:колонка: error
  grep -aoE "[A-Za-z0-9_/.+-]+\.(c|cpp|cc|m|s|S|h|hpp):[0-9]+:[0-9]+: (fatal )?error: .{0,160}" "$OUT/build.log" \
    | sed 's#^.*/src/xnu/##' | sort -u | head -n 40
  echo "=== FAILED TARGETS ==="
  grep -aoE "make\[[0-9]+\]: \*\*\* \[[^]]+\.(o|a|kext|c|h)\] Error [0-9]+" "$OUT/build.log" | sort -u | head -n 20
  echo "=== LINK/OTHER ==="
  grep -aE "^ld: |Undefined symbols|clang: error|No rule to make|command not found|ModuleNotFound|Traceback|SyntaxError" "$OUT/build.log" | sort -u | head -n 20
  echo "=== END ==="
fi
echo "make rc=$RC (полный лог: build/build.log)"
exit $RC
