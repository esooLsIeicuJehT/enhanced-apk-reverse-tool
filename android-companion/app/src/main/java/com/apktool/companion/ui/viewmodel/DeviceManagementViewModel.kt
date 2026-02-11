package com.apktool.companion.ui.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.viewModelScope
import com.apktool.companion.data.model.DeviceInfo
import com.apktool.companion.data.repository.DeviceRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class DeviceManagementViewModel @Inject constructor(
    application: Application,
    private val deviceRepository: DeviceRepository
) : AndroidViewModel(application) {

    private val _devices = MutableLiveData<List<DeviceInfo>>()
    val devices: LiveData<List<DeviceInfo>> = _devices

    private val _selectedDevice = MutableLiveData<DeviceInfo?>()
    val selectedDevice: LiveData<DeviceInfo?> = _selectedDevice

    private val _isLoading = MutableLiveData<Boolean>()
    val isLoading: LiveData<Boolean> = _isLoading

    private val _error = MutableLiveData<String>()
    val error: LiveData<String> = _error

    init {
        loadDevices()
    }

    fun loadDevices() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                val devicesList = deviceRepository.getConnectedDevices()
                _devices.value = devicesList
            } catch (e: Exception) {
                _error.value = e.message
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun refreshDevices() {
        loadDevices()
    }

    fun selectDevice(device: DeviceInfo) {
        _selectedDevice.value = device
    }

    fun disconnectDevice(deviceId: String) {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                deviceRepository.disconnectDevice(deviceId)
                loadDevices()
                if (_selectedDevice.value?.id == deviceId) {
                    _selectedDevice.value = null
                }
            } catch (e: Exception) {
                _error.value = e.message
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun disconnectCurrentDevice() {
        _selectedDevice.value?.let { device ->
            disconnectDevice(device.id)
        }
    }

    fun clearError() {
        _error.value = null
    }
}