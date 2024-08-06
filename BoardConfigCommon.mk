#
# Copyright (C) 2021-2023 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Target kernel, must be set before inheriting common tree
TARGET_KERNEL_VERSION := 5.4

COMMON_PATH := device/amlogic/ne-common

# A/B
AB_OTA_UPDATER := true

AB_OTA_PARTITIONS += \
    boot \
    dtbo \
    odm \
    product \
    system \
    system_ext \
    vbmeta \
    vbmeta_system \
    vendor

## BUILD_BROKEN_*
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

# GPU
MALI_DRV_VERSION := r32p1
TARGET_AMLOGIC_GPU_ARCH ?= bifrost

## HIDL
DEVICE_MANIFEST_FILE += $(COMMON_PATH)/manifest.xml

## Kernel
BOARD_KERNEL_CMDLINE := androidboot.dynamic_partitions=true androidboot.boot_devices=soc/fe08c000.mmc use_uvm=1
TARGET_KERNEL_SOURCE := kernel/amlogic/linux-5.4

ifeq ($(WITH_CONSOLE),true)
BOARD_KERNEL_CMDLINE += console=ttyS0,921600 no_console_suspend ignore_loglevel
endif

## Kernel modules
TARGET_KERNEL_EXT_MODULE_ROOT := kernel/amlogic/kernel-modules
TARGET_KERNEL_EXT_MODULES += \
    mali-driver/bifrost \
    media-5.4

ifneq ($(TARGET_HAS_TEE),false)
TARGET_KERNEL_EXT_MODULES += \
    optee
endif

TARGET_MODULE_ALIASES += \
    mali_kbase.ko:mali.ko

BOARD_VENDOR_KERNEL_MODULES_BLOCKLIST_FILE := $(COMMON_PATH)/modules.blocklist
BOARD_VENDOR_KERNEL_MODULES_LOAD := $(strip $(shell cat $(COMMON_PATH)/modules.load))
BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD := $(strip $(shell cat $(COMMON_PATH)/modules.load))
BOOT_KERNEL_MODULES := $(BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD)
BOARD_GENERIC_RAMDISK_KERNEL_MODULES_LOAD := $(strip $(shell cat $(COMMON_PATH)/modules.load))

## Partitions
SSI_PARTITIONS := product system system_ext
TREBLE_PARTITIONS := odm vendor vendor_dlkm
ALL_PARTITIONS := $(SSI_PARTITIONS) $(TREBLE_PARTITIONS)

# TODO: VBMETA_OEM
BOARD_CUSTOMIMAGES_PARTITION_LIST := oem
BOARD_AVB_OEM_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_OEM_ALGORITHM := SHA256_RSA4096
BOARD_AVB_OEM_ADD_HASHTREE_FOOTER_ARGS :=
BOARD_AVB_OEM_ROLLBACK_INDEX_LOCATION := 1
BOARD_AVB_OEM_PARTITION_SIZE := 33554432
BOARD_AVB_OEM_IMAGE_LIST := \
    device/amlogic/ne-common/factory/oem_a.PARTITION

BOARD_AMLOGIC_DYNAMIC_PARTITIONS_PARTITION_LIST := $(ALL_PARTITIONS)
BOARD_AMLOGIC_DYNAMIC_PARTITIONS_SIZE := $(shell echo $$(($(BOARD_SUPER_PARTITION_SIZE) - 4194304))) # (BOARD_SUPER_PARTITION_SIZE - "reasonable overhead of 4 MiB" 4194304)
BOARD_BUILD_SUPER_IMAGE_BY_DEFAULT := true
BOARD_SUPER_PARTITION_GROUPS := amlogic_dynamic_partitions
BUILDING_SUPER_EMPTY_IMAGE := true

## Properties
TARGET_PRODUCT_PROP += $(COMMON_PATH)/product.prop
TARGET_SYSTEM_PROP += $(COMMON_PATH)/system.prop
TARGET_VENDOR_PROP += $(COMMON_PATH)/vendor.prop

## Recovery
TARGET_RECOVERY_FSTAB := $(COMMON_PATH)/init-files/fstab.amlogic
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
TARGET_NO_RECOVERY := true
BOARD_USES_RECOVERY_AS_BOOT := true

## Vendor SPL
VENDOR_SECURITY_PATCH := 2023-03-01

## Include the main common tree BoardConfig makefile
include device/amlogic/common/BoardConfigAmlogic.mk

## Include the common proprietary BoardConfig makefile
include vendor/amlogic/ne-common/BoardConfigVendor.mk
