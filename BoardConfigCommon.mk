#
# Copyright (C) 2021-2023 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

TARGET_KERNEL_VERSION := 5.15

COMMON_PATH := device/amlogic/ne-common

# A/B
AB_OTA_PARTITIONS += \
    boot \
    dtbo \
    odm \
    product \
    system \
    system_dlkm \
    system_ext \
    vbmeta \
    vbmeta_system \
    vendor \
    vendor_dlkm


## BUILD_BROKEN_*
# Needed for systemcontrol blobs copy-files to recovery via TARGET_RECOVERY_DEVICE_DIRS
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

## HIDL
DEVICE_MANIFEST_FILE += $(COMMON_PATH)/manifest.xml

## Kernel
BOARD_KERNEL_CMDLINE := bootconfig
BOARD_BOOTCONFIG += androidboot.dynamic_partitions=true
BOARD_BOOTCONFIG += androidboot.dtbo_idx=0
BOARD_BOOTCONFIG += androidboot.boot_devices=soc/fe08c000.mmc
BOARD_BOOTCONFIG += use_uvm=1

BOARD_USES_GENERIC_KERNEL_IMAGE := true
BOARD_PREBUILT_DTBOIMAGE := $(KERNEL_PATH)/dtbo.img
BOARD_PREBUILT_DTBIMAGE_DIR := $(KERNEL_PATH)

TARGET_NO_KERNEL_OVERRIDE := true
PRODUCT_COPY_FILES += \
    $(KERNEL_PATH)/gki/Image.lz4:kernel

BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD := $(strip $(shell cat $(KERNEL_PATH)/vendor_boot.modules.load))
BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD := $(strip $(shell cat $(KERNEL_PATH)/vendor_recovery.modules.load))
BOARD_VENDOR_RAMDISK_KERNEL_MODULES := $(wildcard $(KERNEL_PATH)/ramdisk/lib/modules/*.ko)

# 1. Enable system_dlkm
BOARD_USES_SYSTEM_DLKMIMAGE := true
TARGET_COPY_OUT_SYSTEM_DLKM := system_dlkm
BOARD_SYSTEM_KERNEL_MODULES := $(strip $(shell find $(SYSTEM_DLKM_SRC) -type f -name "*.ko"))
BOARD_SYSTEM_KERNEL_MODULES :=  $(strip $(shell find $(KERNEL_PATH)/gki/lib/modules/ -type f -name "*.ko"))
BOARD_SYSTEM_KERNEL_MODULES_LOAD := $(strip $(shell cat $(KERNEL_PATH)/gki/system_dlkm.modules.load))

BOARD_USES_VENDOR_DLKMIMAGE := true
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm
BOARD_VENDOR_KERNEL_MODULES := $(wildcard $(KERNEL_PATH)/lib/modules/*.ko)
BOARD_VENDOR_KERNEL_MODULES_LOAD := $(strip $(shell cat $(KERNEL_PATH)/vendor_dlkm.modules.load))


## Partitions
SSI_PARTITIONS := product system system_ext system_dlkm 
TREBLE_PARTITIONS := odm vendor vendor_dlkm
ALL_PARTITIONS := $(SSI_PARTITIONS) $(TREBLE_PARTITIONS)

BOARD_AMLOGIC_DYNAMIC_PARTITIONS_PARTITION_LIST := $(ALL_PARTITIONS)
BOARD_AMLOGIC_DYNAMIC_PARTITIONS_SIZE := $(shell echo $$(($(BOARD_SUPER_PARTITION_SIZE) - 4194304))) # (BOARD_SUPER_PARTITION_SIZE - "reasonable overhead of 4 MiB" 4194304)
BOARD_BUILD_SUPER_IMAGE_BY_DEFAULT := true
BOARD_SUPER_PARTITION_GROUPS := amlogic_dynamic_partitions
BUILDING_SUPER_EMPTY_IMAGE := true

## Properties
TARGET_SYSTEM_PROP += $(COMMON_PATH)/system.prop
TARGET_VENDOR_PROP += $(COMMON_PATH)/vendor.prop

## Recovery
TARGET_RECOVERY_DEVICE_DIRS += vendor/amlogic/ne-common/proprietary
TARGET_RECOVERY_FSTAB := $(COMMON_PATH)/init-files/fstab.amlogic
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
TARGET_NO_RECOVERY := true
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT:=true

## Releasetools
TARGET_RELEASETOOLS_EXTENSIONS := $(COMMON_PATH)/releasetools

## Updater
AB_OTA_UPDATER := true

## Vendor SPL
VENDOR_SECURITY_PATCH := 2024-07-01

## Include the main common tree BoardConfig makefile
include device/amlogic/common/BoardConfigAmlogic.mk

## Include the common proprietary BoardConfig makefile
include vendor/amlogic/ne-common/BoardConfigVendor.mk
