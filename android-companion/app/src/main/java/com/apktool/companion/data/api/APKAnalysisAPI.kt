package com.apktool.Companion.data.api

import com.apktool.Companion.data.models.AnalysisRequest
import com.apktool.Companion.data.models.AnalysisResponse
import com.apktool.Companion.data.models.DeviceInfo
import com.apktool.Companion.data.models.ProgressUpdate
import okhttp3.MultipartBody
import okhttp3.RequestBody
import retrofit2.Response
import retrofit2.http.*

interface APKAnalysisAPI {
    
    @POST("api/analyze")
    suspend fun analyzeAPK(
        @Body request: AnalysisRequest
    ): Response<AnalysisResponse>
    
    @Multipart
    @POST("api/upload")
    suspend fun uploadAPK(
        @Part file: MultipartBody.Part,
        @Part("options") options: RequestBody?
    ): Response<Map<String, Any>>
    
    @GET("api/analysis/{id}")
    suspend fun getAnalysis(
        @Path("id") analysisId: String
    ): Response<AnalysisResponse>
    
    @GET("api/analysis/{id}/progress")
    suspend fun getAnalysisProgress(
        @Path("id") analysisId: String
    ): Response<ProgressUpdate>
    
    @GET("api/devices")
    suspend fun getDevices(): Response<List<DeviceInfo>>
    
    @GET("api/devices/{id}")
    suspend fun getDeviceDetails(
        @Path("id") deviceId: String
    ): Response<DeviceInfo>
    
    @POST("api/devices/pull/{package}")
    suspend fun pullAPKFromDevice(
        @Path("package") packageName: String,
        @Body options: Map<String, Any> = emptyMap()
    ): Response<Map<String, Any>>
    
    @DELETE("api/analysis/{id}")
    suspend fun cancelAnalysis(
        @Path("id") analysisId: String
    ): Response<Map<String, Any>>
    
    @GET("api/health")
    suspend fun healthCheck(): Response<Map<String, Any>>
    
    @POST("api/auth/login")
    suspend fun login(
        @Body credentials: Map<String, String>
    ): Response<Map<String, String>>
    
    @POST("api/auth/logout")
    suspend fun logout(): Response<Map<String, String>>
}