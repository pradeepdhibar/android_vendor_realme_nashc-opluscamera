#!/usr/bin/env bash

ROOT="${1:-$(pwd)}"

die() {
    echo "ERROR: $*" >&2
    exit 1
}

[ -f "$ROOT/build/envsetup.sh" ] || \
    die "Run from Android source root or pass source root as argument"

PORT="$ROOT/vendor/realme/nashc-opluscamera"
DEVICE="$ROOT/device/realme/nashc"
HARDWARE_OPLUS="$ROOT/hardware/oplus"
KERNEL="$ROOT/kernel/realme/nashc"
BASE_VENDOR="$ROOT/vendor/realme/nashc"

[ -d "$PORT" ] || die "Standalone repo missing: $PORT"
[ -d "$DEVICE" ] || die "Device tree missing: $DEVICE"
[ -d "$HARDWARE_OPLUS" ] || die "hardware/oplus missing"
[ -d "$KERNEL" ] || die "Kernel tree missing"
[ -d "$BASE_VENDOR" ] || die "Base vendor tree missing"

echo "========================================"
echo " Nashc OplusCamera standalone setup"
echo "========================================"

copy_payload() {
    SRCROOT="$1"
    DSTROOT="$2"
    LABEL="$3"

    [ -d "$SRCROOT" ] || {
        echo "SKIP: $LABEL payload not present"
        return
    }

    echo
    echo "===== $LABEL ====="

    find "$SRCROOT" -type f -print0 |
    while IFS= read -r -d '' SRC; do
        REL="${SRC#$SRCROOT/}"
        DST="$DSTROOT/$REL"

        mkdir -p "$(dirname "$DST")" || exit 1

        if [ -f "$DST" ] && cmp -s "$SRC" "$DST"; then
            echo "OK      $REL"
        else
            cp -a "$SRC" "$DST" || exit 1
            echo "COPIED  $REL"
        fi
    done
}

apply_git_patch() {
    TREE="$1"
    PATCH="$2"
    LABEL="$3"

    [ -f "$PATCH" ] || die "$LABEL patch missing: $PATCH"

    echo
    echo "===== $LABEL ====="

    if git -C "$TREE" apply --reverse --check "$PATCH" >/dev/null 2>&1; then
        echo "OK: patch already applied"
        return 0
    fi

    if git -C "$TREE" apply --check "$PATCH" >/dev/null 2>&1; then
        git -C "$TREE" apply "$PATCH" || die "Failed applying $LABEL patch"
        echo "APPLIED"
        return 0
    fi

    echo "Patch cannot be cleanly applied and is not detected as already applied."
    echo "Tree:  $TREE"
    echo "Patch: $PATCH"
    return 1
}

ensure_line() {
    FILE="$1"
    LINE="$2"

    grep -Fqx "$LINE" "$FILE" 2>/dev/null && return 0

    printf '\n%s\n' "$LINE" >> "$FILE" || \
        die "Could not modify $FILE"
}

echo
echo "===== VERIFY CRITICAL BLOBS ====="

check_hash() {
    EXPECTED="$1"
    FILE="$2"

    [ -f "$FILE" ] || die "Missing: $FILE"

    GOT="$(sha256sum "$FILE" | awk '{print $1}')"

    if [ "$GOT" != "$EXPECTED" ]; then
        die "Hash mismatch: $FILE
expected=$EXPECTED
actual=$GOT"
    fi

    echo "OK  $GOT  ${FILE#$ROOT/}"
}

check_hash \
96c62bd11dbee449456da089134dcb599c97e3144f7829154eb1dca06dfa9221 \
"$PORT/proprietary/odm/lib64/libAlgoInterface.so"

check_hash \
c1803e723c4241e4c4938b50da139271e53ade63ec0524291637da15f3263f13 \
"$PORT/proprietary/odm/lib64/libAlgoProcess.so"

check_hash \
7cb1f2f717250793a9f873ab3050b98cb08b9c8cf72b6f0d4847b1997f100c79 \
"$PORT/proprietary/odm/lib64/libarcsoft_dualcam_bokeh_frt_api.so"

check_hash \
c27b282c56824be444851e18de6e0b2fe2b48456bfc76186bac7f1914e40f896 \
"$PORT/proprietary/odm/lib64/libmpbase.so"

check_hash \
d297aa5ad92033cd7f3cba7cab2c46645e3824fbab2413081a756d5cbc54983e \
"$PORT/overrides/vendor/lib64/libmtkcam_pipelinemodel_session.so"

#
# hardware/oplus working camera framework additions
#
copy_payload \
"$PORT/patches/hardware-oplus/files" \
"$HARDWARE_OPLUS" \
"hardware/oplus camera files"

apply_git_patch \
"$HARDWARE_OPLUS" \
"$PORT/patches/hardware-oplus/0001-oplus-fwk-camera-compat.patch" \
"hardware/oplus OplusBuild compatibility" || exit 1

#
# Kernel OWE source files
#
copy_payload \
"$PORT/patches/kernel/files" \
"$KERNEL" \
"kernel OWE files"

echo
echo "===== kernel OWE integration ====="

OWE_DEFCONFIG="$KERNEL/arch/arm64/configs/nashc_defconfig"
OWE_KCONFIG="$KERNEL/drivers/misc/mediatek/cameraisp/Kconfig"
OWE_MAKEFILE="$KERNEL/drivers/misc/mediatek/cameraisp/Makefile"
OWE_PATCH="$PORT/patches/kernel/0001-nashc-camera-owe-integration.patch"

if \
    grep -Fqx 'CONFIG_MTK_CAMERA_ISP_OWE_SUPPORT=y' "$OWE_DEFCONFIG" && \
    grep -Fqx 'source "drivers/misc/mediatek/cameraisp/owe/Kconfig"' "$OWE_KCONFIG" && \
    grep -Eq '^[[:space:]]*obj-y[[:space:]]*\+=[[:space:]]*owe/[[:space:]]*$' "$OWE_MAKEFILE"
then
    echo "OK: OWE integration already present"
else
    echo "OWE integration incomplete; trying clean patch..."

    if git -C "$KERNEL" apply --check "$OWE_PATCH" >/dev/null 2>&1; then
        git -C "$KERNEL" apply "$OWE_PATCH" || \
            die "Failed applying kernel OWE patch"

        echo "APPLIED: kernel OWE integration"
    else
        die "OWE integration is incomplete and patch cannot be cleanly applied"
    fi
fi

#
# Patched/tested tuningflow blob.
#
echo
echo "===== ISP TUNINGFLOW ====="

SRC_TUNING="$PORT/overrides/vendor/lib64/libmtkcam_pipelinemodel_session.so"
DST_TUNING="$BASE_VENDOR/proprietary/vendor/lib64/libmtkcam_pipelinemodel_session.so"

mkdir -p "$(dirname "$DST_TUNING")" || die "Cannot create tuningflow directory"

if [ -f "$DST_TUNING" ] && cmp -s "$SRC_TUNING" "$DST_TUNING"; then
    echo "OK: tuningflow already matches"
else
    cp -a "$SRC_TUNING" "$DST_TUNING" || die "Could not install tuningflow"
    echo "COPIED: patched tuningflow"
fi

#
# Product integration.
#
echo
echo "===== DEVICE PRODUCT INTEGRATION ====="

DEVICE_MK_LINE='$(call inherit-product, vendor/realme/nashc-opluscamera/nashc-opluscamera.mk)'
BOARD_LINE='include vendor/realme/nashc-opluscamera/BoardConfigOplusCamera.mk'

if ! grep -Fqx "$DEVICE_MK_LINE" "$DEVICE/device.mk"; then
    {
        echo
        echo '# OplusCamera standalone port'
        echo "$DEVICE_MK_LINE"
    } >> "$DEVICE/device.mk" || die "Failed editing device.mk"

    echo "ADDED device.mk integration"
else
    echo "OK: device.mk integration"
fi

if ! grep -Fqx "$BOARD_LINE" "$DEVICE/BoardConfig.mk"; then
    {
        echo
        echo '# OplusCamera standalone port'
        echo "$BOARD_LINE"
    } >> "$DEVICE/BoardConfig.mk" || die "Failed editing BoardConfig.mk"

    echo "ADDED BoardConfig.mk integration"
else
    echo "OK: BoardConfig.mk integration"
fi

#
# SELinux property type.
#
echo
echo "===== VENDOR OPLUS PROPERTY TYPE ====="

PROPERTY_TE="$DEVICE/sepolicy/vendor/property.te"

python3 - "$PROPERTY_TE" <<'PY'
from pathlib import Path
import re
import sys

p = Path(sys.argv[1])
s = p.read_text()

wanted = "vendor_restricted_prop(vendor_oplus_prop)"

pattern = re.compile(
    r'^[ \t]*vendor_(?:internal|restricted|public)_prop'
    r'\(vendor_oplus_prop\)[ \t]*$',
    re.M
)

if pattern.search(s):
    s = pattern.sub(wanted, s)
else:
    if s and not s.endswith("\n"):
        s += "\n"
    s += wanted + "\n"

p.write_text(s)
PY

grep -n 'vendor_oplus_prop' "$PROPERTY_TE" || \
    die "vendor_oplus_prop setup failed"

echo
echo "===== FINAL QUICK CHECK ====="

grep -n 'MTK_CAMERA_ISP_OWE_SUPPORT=y' \
"$KERNEL/arch/arm64/configs/nashc_defconfig" || \
die "OWE config missing"

grep -n 'obj-y += owe/' \
"$KERNEL/drivers/misc/mediatek/cameraisp/Makefile" || \
die "OWE Makefile integration missing"

grep -n 'cameraisp/owe/Kconfig' \
"$KERNEL/drivers/misc/mediatek/cameraisp/Kconfig" || \
die "OWE Kconfig integration missing"

TUNING_HASH="$(sha256sum "$DST_TUNING" | awk '{print $1}')"

[ "$TUNING_HASH" = \
"d297aa5ad92033cd7f3cba7cab2c46645e3824fbab2413081a756d5cbc54983e" ] || \
die "Installed tuningflow hash mismatch"

echo
echo "========================================"
echo " OplusCamera setup completed successfully"
echo "========================================"
