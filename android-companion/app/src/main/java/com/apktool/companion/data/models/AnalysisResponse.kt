package com.apktool.Companion.data.models

import com.google.gson.annotations.SerializedName

data class AnalysisResponse(
    @SerializedName("id") val id: String,
    @SerializedName("status") val status: AnalysisStatus,
    @SerializedName("appName") val appName: String,
    @SerializedName("packageName") val packageName: String,
    @SerializedName("versionName") val versionName: String?,
    @SerializedName("versionCode") val versionCode: Int?,
    @SerializedName("minSdk") val minSdk: Int?,
    @SerializedName("targetSdk") val targetSdk: Int?,
    @SerializedName("permissions") val permissions: List<Permission>,
    @SerializedName("certificate") val certificate: CertificateInfo?,
    @SerializedName("security") val security: SecurityAnalysis,
    @SerializedName("features") val features: AppFeatures,
    @SerializedName("vulnerabilities") val vulnerabilities: List<Vulnerability>,
    @SerializedName("malwareScore") val malwareScore: MalwareScore?,
    @SerializedName("createdAt") val createdAt: Long,
    @SerializedName("completedAt") val completedAt: Long?,
    @SerializedName("errors") val errors: List<String>? = null
)

data class AnalysisStatus(
    @SerializedName("code") val code: String,
    @SerializedName("message") val message: String,
    @SerializedName("progress") val progress: Float
)

data class Permission(
    @SerializedName("name") val name: String,
    @SerializedName("type") val type: PermissionType,
    @SerializedName("description") val description: String?,
    @SerializedName("level") val level: PermissionLevel,
    @SerializedName("dangerous") val dangerous: Boolean = false
)

enum class PermissionType {
    NORMAL,
    DANGEROUS,
    SIGNATURE,
    RUNTIME,
    SPECIAL
}

enum class PermissionLevel {
    MINIMAL,
    LOW,
    MODERATE,
    HIGH,
    CRITICAL
}

data class CertificateInfo(
    @SerializedName("issuer") val issuer: String,
    @SerializedName("subject") val subject: String,
    @SerializedName("validFrom") val validFrom: Long,
    @SerializedName("validUntil") val validUntil: Long,
    @SerializedName("signatureAlgorithm") val signatureAlgorithm: String,
    @SerializedName("sha1") val sha1: String?,
    @SerializedName("sha256") val sha256: String?,
    @SerializedName("valid") val valid: Boolean,
    @SerializedName("expired") val expired: Boolean,
    @SerializedName("selfSigned") val selfSigned: Boolean
)

data class SecurityAnalysis(
    @SerializedName("sslPinning") val sslPinning: Boolean,
    @SerializedName("rootDetection") val rootDetection: Boolean,
    @SerializedName("debuggable") val debuggable: Boolean,
    @SerializedName("backupEnabled") val backupEnabled: Boolean,
    @SerializedName("testOnly") val testOnly: Boolean,
    @SerializedName("exportedComponents") val exportedComponents: Int,
    @SerializedName("exportedActivities") val exportedActivities: Int,
    @SerializedName("exportedServices") val exportedServices: Int,
    @SerializedName("exportedReceivers") val exportedReceivers: Int,
    @SerializedName("exportedProviders") val exportedProviders: Int,
    @SerializedName("hardcodedSecrets") val hardcodedSecrets: List<Secret>,
    @SerializedName("weakCrypto") val weakCrypto: Boolean,
    @SerializedName("insecureDataStorage") val insecureDataStorage: List<DataStorageIssue>,
    @SerializedName("insecureNetwork") val insecureNetwork: List<NetworkIssue>,
    @SerializedName("riskLevel") val riskLevel: RiskLevel,
    @SerializedName("score") val score: Float
)

enum class RiskLevel {
    NONE,
    LOW,
    MEDIUM,
    HIGH,
    CRITICAL
}

data class Secret(
    @SerializedName("type") val type: String,
    @SerializedName("location") val location: String,
    @SerializedName("value") val value: String,
    @SerializedName("severity") val severity: String
)

data class DataStorageIssue(
    @SerializedName("type") val type: String,
    @SerializedName("location") val location: String,
    @SerializedName("severity") val severity: String,
    @SerializedName("description") val description: String
)

data class NetworkIssue(
    @SerializedName("type") val type: String,
    @SerializedName("endpoint") val endpoint: String,
    @SerializedName("severity") val severity: string?,
    @SerializedName("description") val description: String
)

data class AppFeatures(
    @SerializedName("nativeLibraries") val nativeLibraries: List<String>,
    @SerializedName("usesOpenGL") val usesOpenGL: Boolean,
    @SerializedName("usesCamera") val usesCamera: Boolean,
    @SerializedName("usesMicrophone") val usesMicrophone: Boolean,
    @SerializedName("usesBluetooth") val usesBluetooth: Boolean,
    @SerializedName("usesNFC") val usesNFC: Boolean,
    @SerializedName("usesLocation") val usesLocation: Boolean,
    @SerializedName("usesNetwork") val usesNetwork: Boolean,
    @SerializedName("minGlEsVersion") val minGlEsVersion: Int?,
    @SerializedName("screenOrientation") val screenOrientation: String?
)

data class Vulnerability(
    @SerializedName("owasp") val owasp: String,
    @SerializedName("title") val title: String,
    @SerializedName("description") val description: String,
    @SerializedName("severity") val severity: VulnerabilitySeverity,
    @SerializedName("location") val location: String?,
    @SerializedName("cwe") val cwe: String?,
    @SerializedName("recommendations") val recommendations: List<String>
)

enum class VulnerabilitySeverity {
    INFO,
    LOW,
    MEDIUM,
    HIGH,
    CRITICAL
}

data class MalwareScore(
    @SerializedName("score") val score: Float,
    @SerializedName("confidence") val confidence: Float,
    @SerializedName("classification") val classification: MalwareClassification,
    @SerializedName("features") val features: Map<String, Float>,
    @SerializedName("riskFactors") val riskFactors: List<String>
)

enum class MalwareClassification {
    SAFE,
    SUSPICIOUS,
    LIKELY_MALWARE,
    MALWARE
}

data class ProgressUpdate(
    @SerializedName("id") val id: String,
    @SerializedName("status") val status: String,
    @SerializedName("progress") val progress: Float,
    @SerializedName("currentStep") val currentStep: String,
    @SerializedName("estimatedTimeRemaining") val estimatedTimeRemaining: Long?
)