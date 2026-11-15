#!/bin/sh
# Запуск в QEMU (aarch64 virt). Нужен qemu-system-aarch64.
# Без platform-кода pe_virt.c ядро на virt не стартует.
set -e
cd "$(dirname "$0")/.."
KERNEL="${KERNEL:-build/mach_kernel}"
ROOTFS="${ROOTFS:-build/rootfs.img}"
exec qemu-system-aarch64 \
  -M virt -cpu cortex-a57 -m 1G \
  -kernel "$KERNEL" \
  -drive file="$ROOTFS",format=raw,if=none,id=hd0 \
  -device virtio-blk-device,drive=hd0 \
  -append "$(cat config/boot-args.txt)" \
  -serial mon:stdio -nographic
