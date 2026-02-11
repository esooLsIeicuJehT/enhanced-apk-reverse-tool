package com.apktool.companion.ui.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.viewModelScope
import com.apktool.companion.data.model.AnalysisResult
import com.apktool.companion.data.repository.AnalysisRepository
import kotlinx.coroutines.launch
import javax.inject.Inject

class AnalysisResultsViewModel @Inject constructor(
    application: Application,
    private val analysisRepository: AnalysisRepository
) : AndroidViewModel(application) {

    private val _analysisResult = MutableLiveData<AnalysisResult>()
    val analysisResult: LiveData<AnalysisResult> = _analysisResult

    private val _isLoading = MutableLiveData<Boolean>()
    val isLoading: LiveData<Boolean> = _isLoading

    private val _error = MutableLiveData<String>()
    val error: LiveData<String> = _error

    private val _currentTab = MutableLiveData<Int>()
    val currentTab: LiveData<Int> = _currentTab

    fun loadAnalysisResult(analysisId: String) {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                val result = analysisRepository.getAnalysisResult(analysisId)
                _analysisResult.value = result
            } catch (e: Exception) {
                _error.value = e.message
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun selectTab(tabIndex: Int) {
        _currentTab.value = tabIndex
    }

    fun exportReport(analysisId: String, format: String) {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                analysisRepository.exportReport(analysisId, format)
            } catch (e: Exception) {
                _error.value = e.message
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun deleteAnalysis(analysisId: String) {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                analysisRepository.deleteAnalysis(analysisId)
            } catch (e: Exception) {
                _error.value = e.message
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun shareResults(analysisId: String) {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                val result = analysisRepository.getAnalysisResult(analysisId)
                // Share implementation
            } catch (e: Exception) {
                _error.value = e.message
            } finally {
                _isLoading.value = false
            }
        }
    }
}