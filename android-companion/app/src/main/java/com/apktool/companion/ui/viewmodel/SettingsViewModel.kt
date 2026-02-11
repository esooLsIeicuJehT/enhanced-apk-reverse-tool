package com.apktool.companion.ui.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.viewModelScope
import com.apktool.companion.data.repository.SettingsRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SettingsViewModel @Inject constructor(
    application: Application,
    private val settingsRepository: SettingsRepository
) : AndroidViewModel(application) {

    private val _isLoading = MutableLiveData<Boolean>()
    val isLoading: LiveData<Boolean> = _isLoading

    private val _error = MutableLiveData<String>()
    val error: LiveData<String> = _error

    private val _isNotificationsEnabled = MutableLiveData<Boolean>()
    val isNotificationsEnabled: LiveData<Boolean> = _isNotificationsEnabled

    private val _isBiometricEnabled = MutableLiveData<Boolean>()
    val isBiometricEnabled: LiveData<Boolean> = _isBiometricEnabled

    private val _apiEndpoint = MutableLiveData<String>()
    val apiEndpoint: LiveData<String> = _apiEndpoint

    init {
        loadSettings()
    }

    fun loadSettings() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                _isNotificationsEnabled.value = settingsRepository.isNotificationsEnabled()
                _isBiometricEnabled.value = settingsRepository.isBiometricEnabled()
                _apiEndpoint.value = settingsRepository.getApiEndpoint()
            } catch (e: Exception) {
                _error.value = e.message
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun setNotificationsEnabled(enabled: Boolean) {
        viewModelScope.launch {
            try {
                settingsRepository.setNotificationsEnabled(enabled)
                _isNotificationsEnabled.value = enabled
            } catch (e: Exception) {
                _error.value = e.message
            }
        }
    }

    fun setBiometricEnabled(enabled: Boolean) {
        viewModelScope.launch {
            try {
                settingsRepository.setBiometricEnabled(enabled)
                _isBiometricEnabled.value = enabled
            } catch (e: Exception) {
                _error.value = e.message
            }
        }
    }

    fun setApiEndpoint(endpoint: String) {
        viewModelScope.launch {
            try {
                settingsRepository.setApiEndpoint(endpoint)
                _apiEndpoint.value = endpoint
            } catch (e: Exception) {
                _error.value = e.message
            }
        }
    }

    fun clearCache() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                settingsRepository.clearCache()
            } catch (e: Exception) {
                _error.value = e.message
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun exportData() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                settingsRepository.exportData()
            } catch (e: Exception) {
                _error.value = e.message
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun clearError() {
        _error.value = null
    }
}