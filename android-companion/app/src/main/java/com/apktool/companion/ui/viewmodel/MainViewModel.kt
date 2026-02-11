package com.apktool.companion.ui.viewmodel

ese

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.viewModelScope
import com.apktool.companion.data.model.DeviceInfo
import com.apktool.companion.data.repository.AnalysisRepository
import com.apktool.companion.data.repository.DeviceRepository
import kotlinx.coroutines.launch
import javax.inject.Inject

class MainViewModel @Inject constructor(
    application: Application,
    private val analysisRepository: AnalysisRepository,
    private val deviceRepository: DeviceRepository
) : AndroidViewModel(application) {

   private val _recentAnalyses = MutableLiveData<List<com.apktool.companion.data.model.AnalysisResult>>()
    val recentAnalyses: LiveData<List<com.apktool.companion.data.model.AnalysisResult>> = _recentAnalyses

    private val _deviceInfo = MutableLiveData<DeviceInfo>()
    val deviceInfo: LiveData<DeviceInfo> = _deviceInfo

    private val _isLoading = MutableLiveData<Boolean>()
    val isLoading: LiveData<Boolean> = _isLoading

    private val _error = MutableLiveData<String>()
    val error: LiveData<String> = _error

    init {
        loadRecentAnalyses()
        loadDeviceInfo()
    }

    fun loadRecentAnalyses() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                val analyses = analysisRepository.getRecentAnalyses(limit = 10)
                _recentAnalyses.value = analyses
            } catch (e: Exception) {
                _error.value = e.message
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun loadDeviceInfo() {
        viewModelScope.launch {
            try {
                val info = deviceRepository.getDeviceInfo()
                _deviceInfo.value = info
            } catch (e: Exception) {
                _error.value = e.message
            }
        }
    }

    fun refreshData() {
        loadRecentAnalyses()
        loadDeviceInfo()
    }

    fun checkForUpdates() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                // Check for updates implementation
            } catch (e: Exception) {
                _error.value = e.message
            } finally {
                _isLoading.value = false
            }
    }

    fun clearError() {
        _error.value = null
    }
}