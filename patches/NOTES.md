# Патчи ядра для Darwinos lite6 (xnu-4570.71.2, arm64)

Правки делаются в `src/xnu`; оформляй как `patches/NNNN-name.patch` (`git diff > ...`),
build-xnu.sh применит их автоматически. Пути ниже указаны по структуре xnu-4570, проверяй grep'ом.

## 1. Отключить подпись кода
- `bsd/kern/kern_cs.c`: `cs_enforcement()` возвращает 0; `cs_enforcement_enable` = 0.
- `bsd/kern/ubc_subr.c`: `ubc_cs_blob_add` принимает любые блобы без проверки доверия.
- `bsd/kern/mach_loader.c`: не отказывать при отсутствии подписи (`load_code_signature`).
- `osfmk/vm/vm_fault.c`, `vm_map.c`: убрать kill при `cs_invalid_page` (`CS_KILL`, `CS_HARD`).
- `bsd/kern/kern_exec.c`: не выставлять `CS_ENFORCEMENT`, `CS_REQUIRE_LV`.
- MAC-политики (AMFI, Sandbox) не подключать: `security/` оставить без внешних kext'ов.
- Проверить также `bsd/kern/kern_proc.c` и `osfmk/arm64/` на отсылки к `PE_i_can_has_debugger`/
  trust cache: убрать, если требуют подписанные образы.

## 2. Убрать сервисы Apple
Ядро их не содержит; это userland. В rootfs не класть:
`lockdownd, apsd, itunesstored, mediaserverd, SpringBoard, backboardd, CommCenter,
fairplayd, accountsd, securityd, keychainsyncingd`.
Оставить: `launchd`, `sh`, базовые утилиты.

## 3. Загрузка без образов Apple
- Не требовать IMG4/IM4P-подпись rootfs: raw-диск (`rd=disk0s1`).
- `pexpert/arm/pe_init.c`: не ждать iBoot-специфичных ключей device tree при загрузке в QEMU.

## 4. Platform-expert для QEMU virt (arm64)
Открытые платформы в pexpert: S7002, T8002 (Apple). Нужно добавить свою:
- `pexpert/arm/pe_virt.c` (см. `platform/pe_virt.c`): UART PL011, GICv2, generic timer.
- Зарегистрировать платформу в `pexpert/arm/pe_identify_machine.c` и `pexpert/pexpert/arm/board_config.h`.
- Добавить файл в `pexpert/conf/files.arm64`, добавить MACHINE_CONFIG в `config/MASTER.arm64`.
- Адаптировать `osfmk/arm64/` под cortex-a57 (кэши/CPU-id в `cpu.c`, `machine_routines.c`).
- Device tree формата Apple (`/chosen`, `/arm-io`, `memory-map`) передавать загрузчиком (U-Boot + shim) в `boot_args`.
- IOKit-драйверы: UART, virtio-blk (или SD/eMMC), GIC.

## 5. Реальные iPhone (A7-A11)
- Загрузка через checkm8, кастомный iBoot/kernelcache.
- Закрытых kext'ов (дисплей, тач, GPU, Wi-Fi, питание) в исходниках нет: нужны свои драйверы.
