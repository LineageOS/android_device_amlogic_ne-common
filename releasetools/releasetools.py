#!/bin/env python3
#
# Copyright (C) 2020-2021 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#
"""Device-specific releasetools extensions for device/amlogic/ne-common.

A/B (AB_OTA_UPDATER := true) -- READ THIS FIRST
-----------------------------------------------
build/make/tools/releasetools only builds a common.DeviceSpecificParams in
non_ab_ota.py.  ota_from_target_files.py never constructs one on the A/B
path, so none of the hooks in this file are called for an A/B build, no
matter what TARGET_RELEASETOOLS_EXTENSIONS points at.

An A/B OTA is applied by update_engine from payload.bin.  Anything that has
to be written by an OTA must therefore be listed in AB_OTA_PARTITIONS in
BoardConfigCommon.mk and have a matching image under IMAGES/,
PREBUILT_IMAGES/ or RADIO/ in the target-files zip (see
ota_utils.TARGET_FILES_IMAGES_SUBDIR); update_engine picks the target slot
itself.  delta_generator zero-pads images that are not a multiple of 4096
(RoundUpPartitions in generate_delta_main.cc), so raw vendor blobs are fine.

The Amlogic reference for this SoC is
device/khadas/common/{scripts,scripts/U}/releasetools.py in the vendor
Android 14 tree.  Note that those files are non-A/B leftovers -- they write
unsuffixed by-name nodes and use the bootloader_up / recoverybak staging
partitions and set_bootloader_env("upgrade_step", ...), none of which exist
in the kvim1s A/B partition table.  core_amlogic.mk still points
TARGET_RELEASETOOLS_EXTENSIONS at them under AB_OTA_UPDATER := true, where
they are dead code for exactly the same reason this file is.

The vendor's authoritative A/B list (core_amlogic.mk:943-1013) is mirrored in
AB_OTA_PARTITIONS.  Deliberately *not* mirrored:

  dtb       BOARD_INCLUDE_DTB_IN_BOOTIMG := true, so the dtb ships inside
              boot.img and is updated with it.  The standalone Amlogic dtb
              lives on /dev/dtb, which has no A/B suffix and no by-name
              entry, so update_engine cannot write it.  The vendor omits it
              from AB_OTA_PARTITIONS too.
  logo        Not slot-suffixed in the partition table -- writing it would
              clobber the running slot mid-update.  Vendor omits it as well;
              it stays in the factory/aml_upgrade package.
  recovery    TARGET_NO_RECOVERY := true; recovery lives in vendor_boot.

Mirrored via RADIO/ rather than the normal image targets:

  bootloader  A frozen 4 MiB prebuilt, identical in every build, but it still
              has to ship: u-boot reports forUpgrade_robustOta=true, so on a
              slot switch it copies bootloader_$active_slot into the eMMC boot
              area and rolls the slot back if the BootROM then boots a
              different copy.  A blank bootloader_b makes slot B unreachable.
              See the note in device/khadas/kvim1s/BoardConfig.mk.  It is
              already in RADIO/ via the factory/bootfiles wildcard in
              build/tasks/factory.mk.

  odm_ext     Both are slot-suffixed and both are required first_stage_mount
  oem         entries in fstab, so a slot whose copy was never written panics
              first-stage init.  Neither has a standard AOSP image target here,
              so device/khadas/kvim1s/build/tasks/factory.mk produces them by
              hand and adds them to INSTALLED_RADIOIMAGE_TARGET;
              BOARD_PACK_RADIOIMAGES mirrors RADIO/ into IMAGES/, which is
              where brillo_update_payload looks first.

              odm_ext is the unsparsed factory/odm_ext_a.PARTITION - it holds
              Amlogic content this tree has no sources for, including the
              boot splash u-boot reads directly (bootLogoPart=odm_ext_a).
              oem is built from $(TARGET_OUT_OEM) with BUILD_IMAGE.  Before
              this, image_upgrade.cfg only ever wrote odm_ext_a and oem_a, so
              the *_b copies were blank.

The hooks below are kept only for the non-A/B path (a build that flips
TARGET_OTA_ALLOW_NON_AB := true and clears AB_OTA_UPDATER).  They bail out
if they are ever reached with ab_update set.
"""

import common


def FullOTA_InstallEnd(info):
  OTA_InstallEnd(info, info.input_zip)


def IncrementalOTA_InstallEnd(info):
  # The incremental path passes target_zip, not input_zip.
  OTA_InstallEnd(info, info.target_zip)


def GetSlotSuffixExpr(info):
  """Edify expression for the by-name suffix of a slotted partition."""
  if info.info_dict.get("ab_update") == "true":
    return ' + getprop("ro.boot.slot_suffix")'
  return ""


def AddImage(info, input_zip, folder, basename, dest, slotted=False):
  data = input_zip.read(folder + basename)
  common.ZipWriteStr(info.output_zip, basename, data)
  suffix = GetSlotSuffixExpr(info) if slotted else ""
  info.script.AppendExtra(
      'package_extract_file("%s", "%s"%s);' % (basename, dest, suffix))


def AddDtbImage(info, input_zip, folder, basename):
  data = input_zip.read(folder + basename)
  common.ZipWriteStr(info.output_zip, basename, data)
  info.script.AppendExtra(
      'package_extract_file("%s", "/tmp/dtb.img");' % basename)
  info.script.AppendExtra(
      'run_program("/system/bin/dd", "if=/tmp/dtb.img", "of=/dev/dtb", '
      '"bs=1k", "count=256");')


def PrintInfo(info, dest):
  info.script.Print("Patching {} image unconditionally...".format(
      dest.split('/')[-1]))


def OTA_InstallEnd(info, input_zip):
  if info.info_dict.get("ab_update") == "true":
    # Should be unreachable -- see the module docstring.  Refuse rather than
    # emit an edify script that would write the *running* slot.
    raise common.ExternalError(
        "ne-common releasetools: edify install hooks reached on an A/B "
        "build; extra images must go through AB_OTA_PARTITIONS instead.")

  names = input_zip.namelist()

  PrintInfo(info, "/dev/block/by-name/dtbo")
  AddImage(info, input_zip, "IMAGES/", "dtbo.img",
           "/dev/block/by-name/dtbo", slotted=True)

  PrintInfo(info, "/dev/block/by-name/vbmeta")
  AddImage(info, input_zip, "IMAGES/", "vbmeta.img",
           "/dev/block/by-name/vbmeta", slotted=True)

  if "IMAGES/vbmeta_system.img" in names:
    PrintInfo(info, "/dev/block/by-name/vbmeta_system")
    AddImage(info, input_zip, "IMAGES/", "vbmeta_system.img",
             "/dev/block/by-name/vbmeta_system", slotted=True)

  if "RADIO/dtb.img" in names:
    PrintInfo(info, "/dev/dtb")
    AddDtbImage(info, input_zip, "RADIO/", "dtb.img")
