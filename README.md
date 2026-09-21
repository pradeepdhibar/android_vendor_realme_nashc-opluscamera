# OplusCamera for Realme 8 (RMX3085 / nashc)

Build-time OplusCamera integration for Realme 8 / nashc.

This repository contains:

- OplusCamera APK
- Oplus camera unit SDK
- APS JNI libraries
- ODM APS / ArcSoft / portrait libraries
- Oplus camera configs, LUTs and PFB resources
- Oplus framework jar
- camera SELinux additions
- MT6785 OWE kernel driver
- tested pipelinemodel-session runtime patch

No camera KernelSU module or meta-overlayfs is required after the port
is integrated into the ROM source.

## Source location

Clone to:

    vendor/realme/nashc-opluscamera

## Initial source setup

From the Android source root:

    bash vendor/realme/nashc-opluscamera/setup.sh

## device.mk

Add:

    $(call inherit-product, vendor/realme/nashc-opluscamera/nashc-opluscamera.mk)

## BoardConfig.mk

Add:

    include vendor/realme/nashc-opluscamera/BoardConfigOplusCamera.mk

Then build the ROM normally.

## Tested camera state

Working:

- Rear Photo
- Rear Photo AI
- 64MP
- Front Photo
- 0.6x
- Rear Portrait
- Front Portrait preview
- Rear Night

Known issue:

- Front Night post-processing / RAW2YUV ISP tuning handoff remains broken.

## Device

Realme 8 4G
RMX3085
codename: nashc
platform: MT6785
