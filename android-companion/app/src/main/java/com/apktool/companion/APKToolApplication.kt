package com.apktool.Companion

import android.app.Application
import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import androidx.work.WorkManager
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class APKToolApplication : Application() {
    
    companion object {
        private lateinit var instance: APKToolApplication
        
        fun getInstance(): APKToolApplication = instance
        
        fun getAppContext(): Context = instance.applicationContext
    }
    
    private lateinit var encryptedPrefs: SharedPreferences
    private lateinit var prefs: SharedPreferences
    
    override fun onCreate() {
        super.onCreate()
        instance = this
        
        // Initialize preferences
        initPreferences()
        
        // Initialize WorkManager
        WorkManager.initialize(this)
        
        // Initialize crash reporting
        initCrashReporting()
    }
    
    private fun initPreferences() {
        // Regular preferences
        prefs = getSharedPreferences("app_prefs", Context.MODE_PRIVATE)
        
        // Encrypted preferences for sensitive data
        val masterKey = MasterKey.Builder(applicationContext)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
            
        encryptedPrefs = EncryptedSharedPreferences.create(
            applicationContext,
            "secure_prefs",
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
    }
    
    private fun initCrashReporting() {
        // Initialize crash reporting service
        // This would integrate with Firebase Crashlytics or similar
        // For now, we'll just log to file
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            // Log crash to file
            logCrash(thread, throwable)
            
            // Call default handler
            val defaultHandler = Thread.getDefaultUncaughtExceptionHandler()
            defaultHandler?.uncaughtException(thread, throwable)
        }
    }
    
    private fun logCrash(thread: Thread, throwable: Throwable) {
        // Implement crash logging
        // Could be extended to send to server
    }
    
    fun getPreferences(): SharedPreferences = prefs
    
    fun getEncryptedPreferences(): SharedPreferences = encryptedPrefs
    
    fun clearAllData() {
        prefs.edit().clear().apply()
        encryptedPrefs.edit().clear().apply()
    }
}