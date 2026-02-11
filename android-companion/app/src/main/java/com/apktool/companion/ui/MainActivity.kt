package com.apktool.Companion.ui

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.core.view.isVisible
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import com.apktool.Companion.R
import com.apktool.Companion.databinding.ActivityMainBinding
import com.apktool.Companion.ui.adapters.AnalysisAdapter
import com.apktool.Companion.ui.viewmodels.MainViewModel
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch
import java.util.*

@AndroidEntryPoint
class MainActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityMainBinding
    private lateinit var viewModel: MainViewModel
    private lateinit var adapter: AnalysisAdapter
    
    private val filePickerLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == RESULT_OK) {
            result.data?.data?.let { uri ->
                handleSelectedFile(uri)
            }
        }
    }
    
    private val permissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        val allGranted = permissions.entries.all { it.value }
        if (!allGranted) {
            Toast.makeText(
                this,
                "Some permissions were denied. The app may not work properly.",
                Toast.LENGTH_LONG
            ).show()
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        viewModel = ViewModelProvider(this)[MainViewModel::class.java]
        
        setupUI()
        checkPermissions()
        loadSavedAnalyses()
        observeViewModel()
    }
    
    private fun setupUI() {
        // Setup RecyclerView
        adapter = AnalysisAdapter { analysis ->
            openAnalysisDetails(analysis.id)
        }
        
        binding.recentAnalysesRecyclerView.apply {
            layoutManager = LinearLayoutManager(this@MainActivity)
            adapter = this@MainActivity.adapter
        }
        
        // Setup FAB
        binding.fabUploadAPK.setOnClickListener {
            openFilePicker()
        }
        
        // Setup menu
        binding.topAppBar.setOnMenuItemClickListener { menuItem ->
            when (menuItem.itemId) {
                R.id.menu_settings -> {
                    openSettings()
                    true
                }
                R.id.menu_devices -> {
                    openDeviceManagement()
                    true
                }
                R.id.menu_about -> {
                    showAboutDialog()
                    true
                }
                else -> false
            }
        }
        
        // Setup refresh
        binding.swipeRefresh.setOnRefreshListener {
            loadSavedAnalyses()
        }
        
        // Setup search
        binding.searchView.setOnQueryTextListener(object :
            android.widget.SearchView.OnQueryTextListener {
            override fun onQueryTextSubmit(query: String?): Boolean {
                adapter.filter(query ?: "")
                return true
            }
            
            override fun onQueryTextChange(newText: String?): Boolean {
                adapter.filter(newText ?: "")
                return true
            }
        })
    }
    
    private fun checkPermissions() {
        val permissionsToRequest = mutableListOf<String>()
        
        // Storage permission
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.READ_MEDIA_IMAGES
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                permissionsToRequest.add(Manifest.permission.READ_MEDIA_IMAGES)
            }
        } else {
            if (ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.READ_EXTERNAL_STORAGE
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                permissionsToRequest.add(Manifest.permission.READ_EXTERNAL_STORAGE)
            }
        }
        
        // Post notifications permission (Android 13+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.POST_NOTIFICATIONS
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                permissionsToRequest.add(Manifest.permission.POST_NOTIFICATIONS)
            }
        }
        
        if (permissionsToRequest.isNotEmpty()) {
            permissionLauncher.launch(permissionsTo.toTypedArray())
        }
    }
    
    private fun openFilePicker() {
        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
            type = "application/vnd.android.package-archive"
            addCategory(Intent.CATEGORY_OPENABLE)
        }
        filePickerLauncher.launch(Intent.createChooser(intent, "Select APK File"))
    }
    
    private fun handleSelectedFile(uri: Uri) {
        val intent = Intent(this, UploadActivity::class.java).apply {
            putExtra("apk_uri", uri.toString())
        }
        startActivity(intent)
    }
    
    private fun loadSavedAnalyses() {
        binding.swipeRefresh.isRefreshing = true
        
        lifecycleScope.launch {
            viewModel.loadSavedAnalyses()
        }
    }
    
    private fun observeViewModel() {
        viewModel.analyses.observe(this) { analyses ->
            adapter.submitList(analyses)
            binding.emptyState.isVisible = analyses.isEmpty()
            binding.recentAnalysesRecyclerView.isVisible = analyses.isNotEmpty()
            binding.swipeRefresh.isRefreshing = false
        }
        
        viewModel.error.observe(this) { error ->
            binding.swipeRefresh.isRefreshing = false
            if (error != null) {
                showErroramatAlertDialog("Error", error)
            }
        }
        
        viewModel.networkStatus.observe(this) { isOnline ->
            binding.networkStatus.isVisible = !isOnline
        }
    }
    
    private fun openAnalysisDetails(analysisId: String) {
        val intent = Intent(this, AnalysisResultsActivity::class.java).apply {
            putExtra("analysis_id", analysisId)
        }
        startActivity(intent)
    }
    
    private fun openSettings() {
        val intent = Intent(this, SettingsActivity::class.java)
        startActivity(intent)
    }
    
    private fun openDeviceManagement() {
        val intent = Intent(this, DeviceManagementActivity::class.java)
        startActivity(intent)
    }
    
    private fun showAboutDialog() {
        val version = packageManager.getPackageInfo(packageName, 0).versionName
        AlertDialog.Builder(this)
            .setTitle("About APK Tool Companion")
            .setMessage("""
                Version: $version
                A comprehensive APK analysis tool for Android devices.
                
                Features:
                - Upload and analyze APKs
                - Remote control of Linux analysis tool
                - Real-time analysis progress
                - Offline report viewing
                - Security vulnerability scanning
                - ML-based malware detection
                
                For more information, visit:
                https://github.com/esooLsIeicuJehT/enhanced-apk-reverse-tool
            """.trimIndent())
            .setPositiveButton("OK", null)
            .show()
    }
    
    private fun showAlertDialog(title: String, message: String) {
        AlertDialog.Builder(this)
            .setTitle(title)
            .setMessage(message)
            .setPositiveButton("OK", null)
            .show()
    }
}