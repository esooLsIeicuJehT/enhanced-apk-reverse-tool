package com.apktool.Companion.ui

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch
import java.io.File
import com.apktool.Companion.R
import com.apktool.Companion.databinding.ActivityUploadBinding
import com.apktool.Companion.data.repository.APKRepository
import com.apktool.Companion.data.models.AnalysisOptions
import com.apktool.Companion.data.util.NetworkResult
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

@AndroidEntryPoint
class UploadActivity : AppCompatActivity() {
    
    @Inject
    lateinit var repository: APKRepository
    
    private lateinit var binding: ActivityUploadBinding
    private var selectedFile: File? = null
    
    private val filePickerLauncher = registerForActivityResult(
        ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let { handleSelectedFile(it) }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityUploadBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        setupUI()
        handleIntent()
    }
    
    private fun setupUI() {
        // Setup toolbar
        setSupportActionBar(binding.toolbar)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        binding.toolbar.setNavigationOnClickListener {
            onBackPressed()
        }
        
        // Setup select file button
        binding.btnSelectFile.setOnClickListener {
            openFilePicker()
        }
        
        // Setup upload button
        binding.btnUpload.setOnClickListener {
            selectedFile?.let { startAnalysis(it) }
        }
        
        // Setup advanced options
        binding.btnAdvancedOptions.setOnClickListener {
            showAdvancedOptionsDialog()
        }
        
        // Setup device pull
        binding.btnPullFromDevice.setOnClickListener {
            openDeviceSelection()
        }
    }
    
    private fun handleIntent() {
        // Check if APK URI was passed from MainActivity
        val apkUri = intent.getStringExtra("apk_uri")
        if (!apkUri.isNullOrBlank()) {
            val uri = Uri.parse(apkUri)
            lifecycleScope.launch {
                try {
                    val file = repository.copyUriToCache(uri)
                    selectedFile = file
                    updateUIWithFile(file)
                } catch (e: Exception) {
                    showError("Failed to load file: ${e.message}")
                }
            }
        }
    }
    
    private fun openFilePicker() {
        filePickerLauncher.launch("application/vnd.android.package-archive")
    }
    
    private fun handleSelectedFile(uri: Uri) {
        lifecycleScope.launch {
            try {
                val file = repository.copyUriToCache(uri)
                selectedFile = file
                updateUIWithFile(file)
            } catch (e: Exception) {
                showError("Failed to load file: ${e.message}")
            }
        }
    }
    
    private fun updateUIWithFile(file: File) {
        // Show file info
        binding.txtFileName.text = file.name
        binding.txtFileSize.text = formatFileSize(file.length())
        binding.txtFileSelected.text = "File selected"
        
        // Enable upload button
        binding.btnUpload.isEnabled = true
    }
    
    private fun startAnalysis(file: File) {
        val options = getSelectedOptions()
        
        binding.uploadProgressIndicator.isIndeterminate = true
        binding.btnUpload.isEnabled = false
        binding.txtUploadStatus.text = "Uploading..."
        
        lifecycleScope.launch {
            repository.analyzeAPK(file.absolutePath, options).collect { result ->
                when (result) {
                    is NetworkResult.Loading -> {
                        // Loading state
                    }
                    is NetworkResult.Success -> {
                        binding.uploadProgressIndicator.isIndeterminate = false
                        binding.uploadProgressIndicator.progress = 100
                        binding.txtUploadStatus.text = "Analysis started!"
                        
                        // Navigate to analysis results
                        result.data?.id?.let { analysisId ->
                            navigateToAnalysis(analysisId)
                        }
                    }
                    is NetworkResult.Error -> {
                        binding.uploadProgressIndicator.isIndeterminate = false
                        binding.btnUpload.isEnabled = true
                        showError("Upload failed: ${result.message}")
                    }
                }
            }
        }
    }
    
    private fun getSelectedOptions(): AnalysisOptions {
        return AnalysisOptions(
            securityAnalysis = binding.chkSecurity.isChecked,
            vulnerabilityScan = binding.chkVulnerability.isChecked,
            malwareDetection = binding.chkMalware.isChecked,
            deepAnalysis = binding.chkDeepAnalysis.isChecked
        )
    }
    
    private fun showAdvancedOptionsDialog() {
        MaterialAlertDialogBuilder(this)
            .setTitle("Advanced Options")
            .setMultiChoiceItems(
                arrayOf(
                    "Permission Analysis",
                    "API Usage Analysis",
                    "Network Analysis",
                    "Certificate Analysis",
                    "Manifest Analysis",
                    "Code Analysis",
                    "Native Code Analysis",
                    "Library Analysis"
                ),
                booleanArrayOf(
                    true,
                    true,
                    true,
                    true,
                    true,
                    false,
                    false,
                    false
                )
            ) { _, which, _ ->
                // Handle selections
            }
            .setPositiveButton("OK") { _, _ ->
                Toast.makeText(this, "Options saved", Toast.LENGTH_SHORT).show()
            }
            .show()
    }
    
    private fun openDeviceSelection() {
        val intent = Intent(this, DeviceSelectionActivity::class.java)
        startActivityForResult(intent, DEVICE_SELECTION_REQUEST_CODE)
    }
    
    private fun navigateToAnalysis(analysisId: String) {
        val intent = Intent(this, AnalysisResultsActivity::class.java).apply {
            putExtra("analysis_id", analysisId)
        }
        startActivity(intent)
        finish()
    }
    
    private fun showError(message: String) {
        MaterialAlertDialogBuilder(this)
            .setTitle("Error")
            .setMessage(message)
            .setPositiveButton("OK", null)
            .show()
    }
    
    private fun formatFileSize(bytes: Long): String {
        val kb = bytes / 1024.0
        val mb = kb / 1024.0
        return when {
            mb >= 1 -> "%.2f MB".format(mb)
            kb >= 1 -> "%.2f KB".format(kb)
            else -> "$bytes bytes"
        }
    }
    
    companion object {
        private const val DEVICE_SELECTION_REQUEST_CODE = 1001
    }
}