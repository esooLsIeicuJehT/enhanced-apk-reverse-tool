package com.apktool.Companion.ui

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.lifecycleScope
import androidx.viewpager2.widget.ViewPager2
import com.aptool.Companion.R
import com.apktool.Companion.data.models.AnalysisResponse
import com.apktool.Companion.databinding.ActivityAnalysisResultsBinding
import com.apktool.Companion.ui.adapters.ResultsPagerAdapter
import com.apktool.Companion.ui.viewmodels.AnalysisResultsViewModel
import dagger.hilt.android.Android
import kotlinx.coroutines.launch
import com.google.android.material.appbar.MaterialToolbar
import com.google.android.material.tabs.TabLayout
import com.google.android.material.tabs.TabLayoutMediator

@AndroidEntryPoint
class AnalysisResultsActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityAnalysisResultsBinding
    private lateinit var viewModel: AnalysisResultsViewModel
    private lateinit var resultsPagerAdapter: ResultsPagerAdapter
    
    private var analysisId: String? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityAnalysisResultsBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        // Get analysis ID from intent
        analysisId = intent.getStringExtra("analysis_id")
        if (analysisId == null) {
            Toast.makeText(this, "No analysis ID provided", Toast.LENGTH_SHORT).show()
            finish()
            return
        }
        
        viewModel = ViewModelProvider(this)[AnalysisResults@android.annotation.SuppressLint("SetTextI18n")
    }
}