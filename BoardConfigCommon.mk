#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

COMMON_PATH := device/amlogic/ne-common

# A/B
AB_OTA_UPDATER := true

AB_OTA_PARTITIONS += \
    boot \
    dtbo \
    odm \
    odm_dlkm \
    product \
    system \
    system_dlkm \
    system_ext \
    vbmeta \
    vbmeta_system \
    vendor \
    vendor_boot \
    vendor_dlkm

## Architecture
TARGET_CPU_VARIANT_RUNTIME := cortex-a55

## BUILD_BROKEN_*
# Needed for systemcontrol blobs copy-files to recovery via TARGET_RECOVERY_DEVICE_DIRS
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

## HIDL
DEVICE_MANIFEST_FILE += $(COMMON_PATH)/manifest.xml

## Kernel
BOARD_KERNEL_CMDLINE := bootconfig
BOARD_BOOTCONFIG += androidboot.dynamic_partitions=true
BOARD_BOOTCONFIG += androidboot.dtbo_idx=0
BOARD_BOOTCONFIG += use_uvm=1
ifeq ($(TARGET_BOOTDEVICE),usb)
  BOARD_BOOTCONFIG += androidboot.boot_devices=soc/fde00000.dwc3
else ifeq ($(TARGET_BOOTDEVICE),sdcard)
  BOARD_BOOTCONFIG += androidboot.boot_devices=soc/fe08a000.sd
else
  BOARD_BOOTCONFIG += androidboot.boot_devices=soc/fe08c000.mmc
endif

BOARD_USES_ODM_DLKMIMAGE := true
BOARD_USES_SYSTEM_DLKMIMAGE := true
BOARD_USES_VENDOR_DLKMIMAGE := true

BOARD_USES_GENERIC_KERNEL_IMAGE := true

TARGET_KERNEL_VERSION ?= 5.15

## Partitions
SSI_PARTITIONS := product system system_ext
TREBLE_PARTITIONS := odm odm_dlkm system_dlkm vendor vendor_dlkm
ALL_PARTITIONS := $(SSI_PARTITIONS) $(TREBLE_PARTITIONS)

BOARD_AMLOGIC_DYNAMIC_PARTITIONS_PARTITION_LIST := $(ALL_PARTITIONS)
BOARD_AMLOGIC_DYNAMIC_PARTITIONS_SIZE := $(shell echo $$(($(BOARD_SUPER_PARTITION_SIZE) - 4194304))) # (BOARD_SUPER_PARTITION_SIZE - "reasonable overhead of 4 MiB" 4194304)
BOARD_BUILD_SUPER_IMAGE_BY_DEFAULT := true
BOARD_SUPER_PARTITION_GROUPS := amlogic_dynamic_partitions

## Properties
TARGET_SYSTEM_EXT_PROP += $(COMMON_PATH)/system_ext.prop
TARGET_VENDOR_PROP += $(COMMON_PATH)/vendor.prop

## Recovery
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT :=true
TARGET_NO_RECOVERY := true
TARGET_RECOVERY_DEVICE_DIRS += vendor/amlogic/ne-common/proprietary
ifneq ($(strip $(TARGET_BOOTDEVICE)),)
  TARGET_RECOVERY_FSTAB := $(COMMON_PATH)/init-files/fstab.$(TARGET_BOOTDEVICE).amlogic
else
  TARGET_RECOVERY_FSTAB := $(COMMON_PATH)/init-files/fstab.amlogic
endif

## Vendor SPL
VENDOR_SECURITY_PATCH := 2026-03-01

## Include the main common tree BoardConfig makefile
include device/amlogic/common/BoardConfigAmlogic.mk

## Include the common proprietary BoardConfig makefile
include vendor/amlogic/ne-common/BoardConfigVendor.mk
