#!/bin/sh
# Собирает минимальный rootfs-образ (HFS+ или ext2, что доступно).
# Бинарники (launchd, sh, coreutils) должны быть собраны под armv7-apple-ios6
# и лежать в build/userland/ (usr/libexec/launchd, bin/sh, ...).
set -e
cd "$(dirname "$0")/.."
OUT=build/rootfs.img
STAGE=build/rootfs-stage
rm -rf "$STAGE"; mkdir -p "$STAGE"/{bin,sbin,usr/libexec,usr/lib,dev,private/var,tmp}
cp -R rootfs/System "$STAGE"/ 2>/dev/null || true
[ -d build/userland ] && cp -R build/userland/* "$STAGE"/
ln -sf private/var "$STAGE"/var 2>/dev/null || true

dd if=/dev/zero of="$OUT" bs=1M count=64
if command -v mkfs.hfsplus >/dev/null; then
  mkfs.hfsplus -v darwinos "$OUT"
  echo "Скопируй $STAGE в образ (hfsplus mount / hfsfuse)."
else
  echo "mkfs.hfsplus не найден (нужен hfsprogs). Образ пустой: $OUT, содержимое в $STAGE"
fi
