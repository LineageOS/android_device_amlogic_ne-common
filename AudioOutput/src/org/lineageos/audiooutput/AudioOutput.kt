/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.audiooutput

import android.content.Context
import android.media.AudioManager
import android.provider.Settings
import android.util.Log

/**
 * Passes the surround sound setting (TV Settings > Display & Sound > Surround sound) to the Amlogic
 * audio HAL.
 *
 * The framework only uses the setting to decide which encoded formats apps may output, while the
 * HAL picks its HDMI output format from `hdmi_format`, and starts with 0 (decode everything to
 * PCM): 5 passes through what the sink's EDID lists, 6 always passes through and 7 passes through
 * the formats given in `hal_param_digital_audio_subformat`, as AudioFormat encodings.
 */
object AudioOutput {
    private const val TAG = "AudioOutput"

    // Settings.Global.ENCODED_SURROUND_OUTPUT{,_ENABLED_FORMATS}, hidden from apps
    const val KEY_SURROUND_OUTPUT = "encoded_surround_output"
    const val KEY_ENABLED_FORMATS = "encoded_surround_output_enabled_formats"

    fun apply(context: Context) {
        val resolver = context.contentResolver
        val mode =
            Settings.Global.getInt(
                resolver,
                KEY_SURROUND_OUTPUT,
                AudioManager.ENCODED_SURROUND_OUTPUT_AUTO,
            )
        val parameters =
            when (mode) {
                AudioManager.ENCODED_SURROUND_OUTPUT_NEVER -> "hdmi_format=0"
                AudioManager.ENCODED_SURROUND_OUTPUT_ALWAYS -> "hdmi_format=6"
                AudioManager.ENCODED_SURROUND_OUTPUT_MANUAL -> {
                    val formats = Settings.Global.getString(resolver, KEY_ENABLED_FORMATS) ?: ""
                    "hdmi_format=7;hal_param_digital_audio_subformat=$formats"
                }
                else -> "hdmi_format=5"
            }
        Log.i(TAG, "Surround sound mode $mode: $parameters")
        context.getSystemService(AudioManager::class.java).setParameters(parameters)
    }
}
