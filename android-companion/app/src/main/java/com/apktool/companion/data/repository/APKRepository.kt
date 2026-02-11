package com.apktool.Companion.data.repository

import android.content.Context
import android.net.Uri
import com.apktool.Companion.data.api.APKAnalysisAPI
import com.apktool.Companion.data.models.*
import com.apktool.Companion.data.util.NetworkResult
import com.apktool.Companion.data.util.safeApiCall
import com.google.gson.Gson
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.asRequestBody
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.File
import java.io.FileOutputStream
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class APKRepository @Inject constructor(
    private val api: APKAnalysisAPI,
    private val context: Context
) {
    
    suspend fun analyzeAPK(
        filePath: String,
        options: AnalysisOptions = AnalysisOptions()
    ): Flow<NetworkResult<AnalysisResponse>> = flow {
        emit(NetworkResult.Loading())
        
        val result = safeApiCall {
            val file = File(filePath)
            
            // Create request body
            val requestBody = file.asRequestBody("application/vnd.android.package-archive".toMediaType())
            val filePart = MultipartBody.Part.createFormData("file", file.name, requestBody)
            
            // Convert options to JSON
            val optionsJson = Gson().toJson(options)
            val optionsBody = optionsJson.toRequestBody("application/json".toMediaType())
            
            api.uploadAPK(filePart, optionsBody)
        }
        
        emit(result)
    }.flowOn(Dispatchers.IO)
    
    suspend fun getAnalysis(analysisId: String): Flow<NetworkResult<AnalysisResponse>> = flow {
        emit(NetworkResult.Loading())
        
        val result = safeApiCall {
            api.getAnalysis(analysisId)
        }
        
        emit(result)
    }.flowOn(Dispatchers.IO)
    
    suspend fun getAnalysisProgress(
        analysisId: String
    ): Flow<NetworkResult<ProgressUpdate>> = flow {
        emit(NetworkResult.Loading())
        
        val result = safeApiCall {
            api.getAnalysisProgress(analysisId)
        }
        
        emit(result)
    }.flowOn(Dispatchers.IO)
    
    suspend fun getDevices(): Flow<NetworkResult<List<DeviceInfo>>> = flow {
        emit(NetworkResult.Loading())
        
        val result = safeApiCall {
            api.getDevices()
        }
        
        emit(result)
    }.flowOn(Dispatchers.IO)
    
    suspend fun pullAPKFromDevice(
        packageName: String,
        deviceId: String? = null,
        options: AnalysisOptions = AnalysisOptions()
    ): Flow<NetworkResult<AnalysisResponse>> = flow {
        emit(NetworkResult.Loading())
        
        val result = safeApiCall {
            val request = mapOf(
                "package" to packageName,
                "deviceId" to deviceId,
                "options" to options
            )
            
            api.pullAPKFromDevice(packageName, request)
        }
        
        emit(result)
    }.flowOn(Dispatchers.IO)
    
    suspend fun cancelAnalysis(analysisId: String): Flow<NetworkResult<Map<String, Any>>> = flow {
        emit(NetworkResult.Loading())
        
        val result = safeApiCall {
            api.cancelAnalysis(analysisId)
        }
        
        emit(result)
    }.flowOn(Dispatchers.IO)
    
    suspend fun saveAnalysisResult(
        result: AnalysisResponse
    ): Flow<NetworkResult<File>> = flow {
        emit(NetworkResult.Loading())
        
        try {
            // Save analysis result to local storage
            val resultFile = saveAnalysisToFile(result)
            emit(NetworkResult.Success(resultFile))
        } catch (e: Exception) {
            emit(NetworkResult.Error(e.message ?: "Failed to save analysis"))
        }
    }.flowOn(Dispatchers.IO)
    
    suspend fun getSavedAnalyses(): Flow<NetworkResult<List<AnalysisResponse>>> = flow {
        emit(NetworkResult.Loading())
        
        try {
            val analyses = loadSavedAnalyses()
            emit(NetworkResult.Success(analyses))
        } catch (e: Exception) {
            emit(NetworkResult.Error(e.message ?: "Failed to load analyses"))
        }
    }.flowOn(Dispatchers.IO)
    
    suspend fun deleteSavedAnalysis(analysisId: String): Flow<NetworkResult<Boolean>> = flow {
        emit(NetworkResult.Loading())
        
        try {
            val deleted = deleteAnalysisFile(analysisId)
            emit(NetworkResult.Success(deleted))
        } catch (e: Exception) {
            emit(NetworkResult.Error(e.message ?: "Failed to delete analysis"))
        }
    }.flowOn(Dispatchers.IO)
    
    private suspend fun saveAnalysisToFile(result: AnalysisResponse): File = withContext(Dispatchers.IO) {
        val analysesDir = File(context.filesDir, "analyses")
        if (!analysesDir.exists()) {
            analysesDir.mkdirs()
        }
        
        val resultFile = File(analysesDir, "${result.id}.json")
        val json = Gson().toJson(result)
        
        FileOutputStream(resultFile).use { output ->
            output.write(json.toByteArray())
        }
        
        resultFile
    }
    
    private suspend fun loadSavedAnalyses(): List<AnalysisResponse> = withContext(Dispatchers.IO) {
        val analysesDir = File(context.filesDir, "analyses")
        if (!analysesDir.exists()) {
            return@withContext emptyList()
        }
        
        val analyses = analysesDir.listFiles()?.mapNotNull { file ->
            try {
                val json = file.readText()
                Gson().fromJson(json, AnalysisResponse::class.java)
            } catch (e: Exception) {
                null
            }
        } ?: emptyList()
        
        analyses.sortedByDescending { it.createdAt }
    }
    
    private suspend fun deleteAnalysisFile(analysisId: String): Boolean = withContext(Dispatchers.IO) {
        val analysesDir = File(context.filesDir, "analyses")
        val file = File(analysesDir, "$analysisId.json")
        
        if (file.exists()) {
            file.delete()
        } else {
            false
        }
    }
    
    suspend fun copyUriToCache(uri: Uri): File = withContext(Dispatchers.IO) {
        val cacheDir = context.cacheDir
        val tempFile = File(cacheDir, "temp_${System.currentTimeMillis()}.apk")
        
        context.contentResolver.openInputStream(uri)?.use { input ->
            FileOutputStream(tempFile).use { output ->
                input.copyTo(output)
            }
        } ?: throw Exception("Unable to open file")
        
        tempFile
    }
    
    suspend fun cleanupCache() {
        withContext(Dispatchers.IO) {
            val cacheDir = context.cacheDir
            cacheDir.listFiles()?.forEach { file ->
                if (file.isDirectory) {
                    file.deleteRecursively()
                } else {
                    file.delete()
                }
            }
        }
    }
}