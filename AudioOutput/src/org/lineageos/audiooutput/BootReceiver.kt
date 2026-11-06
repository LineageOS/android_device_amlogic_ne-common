/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.audiooutput

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** The audio HAL forgets its output format on reboot, so set it again. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_LOCKED_BOOT_COMPLETED) {
            AudioOutput.apply(context)
            SettingsJobService.schedule(context)
        }
    }
}
