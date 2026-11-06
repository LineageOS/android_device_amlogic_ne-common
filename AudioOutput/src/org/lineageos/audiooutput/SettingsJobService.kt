/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.audiooutput

import android.app.job.JobInfo
import android.app.job.JobParameters
import android.app.job.JobScheduler
import android.app.job.JobService
import android.content.ComponentName
import android.content.Context
import android.provider.Settings

/**
 * Runs when the surround sound setting changes, so the HAL follows it without a process kept alive.
 */
class SettingsJobService : JobService() {
    override fun onStartJob(params: JobParameters): Boolean {
        AudioOutput.apply(this)
        // Content trigger jobs only fire once
        schedule(this)
        return false
    }

    override fun onStopJob(params: JobParameters) = false

    companion object {
        private const val JOB_ID = 1

        fun schedule(context: Context) {
            val job =
                JobInfo.Builder(JOB_ID, ComponentName(context, SettingsJobService::class.java))
                    .apply {
                        listOf(AudioOutput.KEY_SURROUND_OUTPUT, AudioOutput.KEY_ENABLED_FORMATS)
                            .forEach {
                                addTriggerContentUri(
                                    JobInfo.TriggerContentUri(Settings.Global.getUriFor(it), 0)
                                )
                            }
                    }
                    .setTriggerContentUpdateDelay(0)
                    .setTriggerContentMaxDelay(1000)
                    .build()
            context.getSystemService(JobScheduler::class.java).schedule(job)
        }
    }
}
