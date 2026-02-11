package com.apktool.companion.ui

import android.os.Bundle
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import androidx.preference.PreferenceFragmentCompat
import androidx.preference.PreferenceManager
import androidx.preference.SwitchPreference
import androidx.preference.EditTextPreference
import androidx.preference.Preference
import com.apktool.companion.R
import com.apktool.companion.databinding.ActivitySettingsBinding
import com.apktool.companion.ui.viewmodel.SettingsViewModel
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch

@AndroidEntryPoint
class SettingsActivity : AppCompatActivity() {

    private lateinit var binding: ActivitySettingsBinding
    private val viewModel: SettingsViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivitySettingsBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setupToolbar()
        setupObservers()
        supportFragmentManager
            .beginTransaction()
            .replace(R.id.settings_container, SettingsFragment())
            .commit()
    }

    private fun setupToolbar() {
        setSupportActionBar(binding.toolbar)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        binding.toolbar.setNavigationOnClickListener {
            onBackPressed()
        }
    }

    private fun setupObservers() {
        viewModel.isLoading.observe(this) { isLoading ->
            // Show/hide loading indicator
        }

        viewModel.error.observe(this) { error ->
            error?.let {
                // Show error message
                viewModel.clearError()
            }
        }
    }

    class SettingsFragment : PreferenceFragmentCompat() {
        override fun onCreatePreferences(savedInstanceState: Bundle?, rootKey: String?) {
            setPreferencesFromResource(R.xml.settings, rootKey)

            // Setup preference listeners
            findPreference<SwitchPreference>("notifications_enabled")?.setOnPreferenceChangeListener { _, newValue ->
                // Handle notifications toggle
                true
            }

            findPreference<EditTextPreference>("api_endpoint")?.setOnPreferenceChangeListener { _, newValue ->
                // Handle API endpoint change
                true
            }

            findPreference<SwitchPreference>("biometric_enabled")?.setOnPreferenceChangeListener { _, newValue ->
                // Handle biometric toggle
                true
            }

            findPreference<Preference>("clear_cache")?.setOnPreferenceClickListener {
                // Clear cache
                true
            }

            findPreference<Preference>("export_data")?.setOnPreferenceClickListener {
                // Export data
                true
            }

            findPreference<Preference>("about")?.setOnPreferenceClickListener {
                // Show about dialog
                true
            }
        }
    }
}