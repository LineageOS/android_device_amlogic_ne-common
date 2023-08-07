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
TARGET_AMLOGIC_GPU_ARCH := bifrost

## HIDL
DEVICE_MANIFEST_FILE += $(COMMON_PATH)/manifest.xml
DEVICE_MANIFEST_FILE += $(COMMON_PATH)/manifest_boot.xml

## Kernel
BOARD_KERNEL_CMDLINE := androidboot.dynamic_partitions=true androidboot.boot_devices=soc/fe08c000.mmc use_uvm=1
TARGET_KERNEL_CONFIG := lineage_kvim1s_defconfig
TARGET_KERNEL_SOURCE := kernel/amlogic/linux-5.4

# Kernel modules
BOARD_VENDOR_KERNEL_MODULES_BLOCKLIST_FILE := $(COMMON_PATH)/modules.blocklist
BOARD_VENDOR_KERNEL_MODULES_LOAD := $(strip $(shell cat $(COMMON_PATH)/modules.load))
BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD := $(strip $(shell cat $(COMMON_PATH)/modules.load))
BOOT_KERNEL_MODULES := $(BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD)
BOARD_GENERIC_RAMDISK_KERNEL_MODULES_LOAD := $(strip $(shell cat $(COMMON_PATH)/modules.load))

## Partitions
CORE_PARTITIONS := system vendor
ADDITIONAL_PARTITIONS := odm product system_ext

ALL_PARTITIONS := $(CORE_PARTITIONS) $(ADDITIONAL_PARTITIONS)

BOARD_AMLOGIC_DYNAMIC_PARTITIONS_PARTITION_LIST := $(ALL_PARTITIONS)
BOARD_AMLOGIC_DYNAMIC_PARTITIONS_SIZE := $(shell echo $$(($(BOARD_SUPER_PARTITION_SIZE) - 4194304))) # (BOARD_SUPER_PARTITION_SIZE - "reasonable overhead of 4 MiB" 4194304)
BOARD_BUILD_SUPER_IMAGE_BY_DEFAULT := true
BOARD_SUPER_PARTITION_GROUPS := amlogic_dynamic_partitions
BUILDING_SUPER_EMPTY_IMAGE := true

ifneq ($(WITH_GMS),true)
BOARD_PRODUCTIMAGE_PARTITION_RESERVED_SIZE := 420000000
BOARD_PRODUCTIMAGE_EXTFS_INODE_COUNT := -1
BOARD_SYSTEMIMAGE_PARTITION_RESERVED_SIZE := 40000000
BOARD_SYSTEM_EXTIMAGE_PARTITION_RESERVED_SIZE := 20000000
BOARD_VENDORIMAGE_PARTITION_RESERVED_SIZE := 10000000
endif

## Properties
TARGET_PRODUCT_PROP += $(COMMON_PATH)/product.prop
TARGET_VENDOR_PROP += $(COMMON_PATH)/vendor.prop

## Recovery
TARGET_RECOVERY_FSTAB := $(COMMON_PATH)/init-files/fstab.amlogic
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
TARGET_NO_RECOVERY := true
BOARD_USES_RECOVERY_AS_BOOT := true

## Releasetools
TARGET_RELEASETOOLS_EXTENSIONS := $(COMMON_PATH)/releasetools

## Vendor SPL
VENDOR_SECURITY_PATCH := 2022-12-01

## Include the main common tree BoardConfig makefile
include device/amlogic/common/BoardConfigAmlogic.mk

## Include the common proprietary BoardConfig makefile
include vendor/amlogic/ne-common/BoardConfigVendor.mk
