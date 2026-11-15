#!/bin/sh
# Клонирует XNU эпохи iOS 11 ЛОКАЛЬНО. Никаких push в GitHub.
# Тулчейн-проекты берутся из macOS 10.13 (xnu-4570 собирается вместе с ними):
# dtrace, AvailabilityVersions, Libsystem, libdispatch, bootstrap_cmds, launchd.
set -e
cd "$(dirname "$0")/.."
mkdir -p src && cd src
ORG=https://github.com/apple-oss-distributions
XNU_TAG="${XNU_TAG:-xnu-4570.71.2}"

fetch() { # repo tag
  [ -d "$1" ] && return 0
  mkdir "$1" && (cd "$1" && git init -q && git remote add origin "$ORG/$1.git" \
    && git fetch -q --depth 1 origin tag "$2" && git checkout -q FETCH_HEAD) \
    || { echo "не удалось: $1 $2 (проверь тег: git ls-remote --tags $ORG/$1.git)"; }
}

fetch xnu "$XNU_TAG"
# Теги ниже уточни через ls-remote под выбранный релиз:
for r in dtrace AvailabilityVersions; do
  [ -d "$r" ] || git clone --depth 1 "$ORG/$r.git" "$r" || echo "skip $r"
done
echo "XNU: $XNU_TAG в src/xnu"
