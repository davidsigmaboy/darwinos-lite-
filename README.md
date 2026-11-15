# Darwinos lite6

Лёгкая ОС на ядре XNU эпохи iOS 11 (`xnu-4570.71.2`, arm64).

## Почему не iOS 6 / iOS 7
Apple не публиковала исходники XNU для iOS. В iOS 6/7-эпохе (xnu-2050, xnu-2422) в открытом
коде нет ни 32-битного ARM, ни arm64. Первый открытый тег с ARM: `xnu-4570` (есть `osfmk/arm`,
`osfmk/arm64`, `pexpert/arm`). Поэтому берём его.

## Условия проекта
- arm64
- Без сервисов Apple (нет iCloud, App Store, APNs, lockdownd, apsd и т.п.)
- Без проверки подписи кода (AMFI / cs_enforcement отключены)
- Лёгкий userland: launchd + sh + базовые утилиты

## Цели
| Цель | Статус |
|------|--------|
| QEMU `-M virt -cpu cortex-a57` (aarch64) | первый тест, нужен platform-код `platform/pe_virt.c` |
| Raspberry Pi 3/4 (aarch64) | нужен свой platform-код под BCM283x/2711 и GIC/ARM-local |
| Старые iPhone (A7-A11: 5s, 6, 6s, 7, 8, X) | загрузка через checkm8, закрытые драйверы отсутствуют |

## Структура
- `scripts/fetch-sources.sh` - клонирует xnu-4570.71.2 локально (в GitHub ничего не пушится)
- `scripts/build-xnu.sh` - сборка ядра arm64 (нужен macOS + Xcode)
- `scripts/make-rootfs.sh` - rootfs-образ
- `scripts/run-qemu.sh` - запуск в QEMU
- `config/boot-args.txt` - boot-args (подпись кода выключена)
- `patches/NOTES.md` - что патчить в ядре
- `platform/pe_virt.c` - platform-код QEMU virt (arm64)
- `rootfs/` - launchd-конфиг

## Порядок работ
1. `scripts/fetch-sources.sh`
2. Положить `platform/pe_virt.c` в `src/xnu/pexpert/arm/`, подключить (patches/NOTES.md, п. 4)
3. Применить патчи (подпись кода, п. 1)
4. На Mac: `SDKROOT=macosx scripts/build-xnu.sh`
5. `scripts/make-rootfs.sh`, затем `scripts/run-qemu.sh`

## Честные ограничения
- XNU собирается только на macOS (Xcode). Из Linux собрать нельзя.
- В открытом XNU нет драйверов дисплея, тача, GPU, Wi-Fi, а также iBoot и закрытых kext.
- Ядро не запускалось: это каркас, а не готовая ОС. Готового .iso нет.
