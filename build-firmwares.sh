#!/bin/bash
debug=0

# Stops on first error, echo on
set -e
set -x

SRC_DIR="${SRC_DIR:=$(realpath "$(pwd)"/edgetx)}"

# TARGET_NAMES_COLORLCD=("nv14" el18 "t16" "t18" "tx16s"
# "x10" "x10-access" "x12s")

TARGET_NAMES_BW=("t8" "tlite" "tpro" "tx12" "tx12mk2"
"x7" "x7-access" "x9d" "x9dp" "x9dp2019"
"x9e" "x9e-hall" "x9lite" "x9lites" "xlite"
"xlites" "zorro" "commando8" "lr3pro" "t12")

# Voice menu only: SK HU
#LANGUAGES_ALL=(CN CZ DA DE EN ES FI FR IT JA PT SE TW PL NL)
LANGUAGES_COLORLCD=(CN CZ DA DE EN ES FI FR IT PT SE TW PL NL)

# CZ overflowed on x9d family build
# CN, TW and JP don't display properly on B&W when last checked
LANGUAGES_BW=(DA DE EN ES FI FR IT PT SE PL NL)

# workaround for GH repo owner
git config --global --add safe.directory "$(pwd)"

GIT_SHA_SHORT=$(git rev-parse --short HEAD )
target_names=$(echo "$FLAVOR" | tr '[:upper:]' '[:lower:]' | tr ';' '\n')

for target in $target_names; do
    fw_name="${target}-${GIT_SHA_SHORT}.bin"

    if [[ ${TARGET_NAMES_BW[*]} =~ ${target} ]]; then
        for lang in "${LANGUAGES_BW[@]}"; do
            if [[ ${debug} -ne 1 ]]; then
                SRCDIR=${SRC_DIR} FLAVOR=${target} EXTRA_OPTIONS=" -DTRANSLATIONS=${lang} " "${SRC_DIR}/tools/build-gh.sh"
            fi
            if [ -f "${SRC_DIR}/${fw_name}" ]; then
                mv "${SRC_DIR}/${fw_name}" "${target}-${lang}-${GIT_SHA_SHORT}.bin"
            fi
        done
    else # Color LCD
        for lang in "${LANGUAGES_COLORLCD[@]}"; do
            if [[ ${debug} -ne 1 ]]; then
                SRCDIR=${SRC_DIR} FLAVOR=${target} EXTRA_OPTIONS=" -DTRANSLATIONS=${lang} " "${SRC_DIR}/tools/build-gh.sh"
            fi
            if [ -f "${SRC_DIR}/${fw_name}" ]; then
                mv "${SRC_DIR}/${fw_name}" "${target}-${lang}-${GIT_SHA_SHORT}.bin"
            fi
        done
    fi

    # Zip all the languages for this target, remove the rest
    sha256sum "${target}"-[A-Z][A-Z]-*.bin >> "${target}".sha256 || continue
    zip -7 -q -r "${target}".zip "${target}"-[A-Z][A-Z]-*.bin "${target}".sha256 "${SRC_DIR}/fw.json" "${SRC_DIR}/LICENSE"
done
