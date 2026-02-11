package com.apktool.companion.ui

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.apktool.companion.R
import com.apktool.companion.databinding.ActivityDeviceManagementBinding
import com.apktool.companion.databinding.ItemDeviceBinding
import com.apktool.companion.data.model.DeviceInfo
import com.apktool.companion.ui.viewmodel.DeviceManagementViewModel
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch

@AndroidEntryPoint
class DeviceManagementActivity : AppCompatActivity() {

    private lateinit var binding: ActivityDeviceManagementBinding
    private val viewModel: DeviceManagementViewModel by viewModels()
    private lateinit var deviceAdapter: DeviceAdapter

    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        val allGranted = permissions.values.all { it }
        if (allGranted) {
            refreshDevices()
        } else {
            Toast.makeText(this, "Permissions denied", Toast.LENGTH_SHORT).show()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityDeviceManagementBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setupToolbar()
        setupRecyclerView()
        setupListeners()
        setupObservers()

        checkPermissions()
    }

    private fun setupToolbar() {
        setSupportActionBar(binding.toolbar)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        binding.toolbar.setNavigationOnClickListener {
            onBackPressed()
        }
    }

    private fun setupRecyclerView() {
        deviceAdapter = DeviceAdapter { device ->
            // Handle device click
            viewModel.selectDevice(device)
        }

        binding.devicesRecyclerView.apply {
            layoutManager = LinearLayoutManager(this@DeviceManagementActivity)
            adapter = deviceAdapter
        }
    }

    private fun setupListeners() {
        binding.refreshButton.setOnClickListener {
            refreshDevices()
        }

        binding.disconnectButton.setOnClickListener {
            viewModel.disconnectCurrentDevice()
        }
    }

    private fun setupObservers() {
        viewModel.devices.observe(this) { devices ->
            deviceAdapter.submitList(devices)
            updateUI(devices)
        }

        viewModel.selectedDevice.observe(this) { device ->
            updateSelectedDeviceInfo(device)
        }

        viewModel.isLoading.observe(this) { isLoading ->
            binding.progressBar.visibility = if (isLoading) View.VISIBLE else View.GONE
        }

        viewModel.error.observe(this) { error ->
            error?.let {
                Toast.makeText(this, it, Toast.LENGTH_LONG).show()
                viewModel.clearError()
            }
        }
    }

    private fun checkPermissions() {
        val permissions = arrayOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.BLUETOOTH_SCAN,
            Manifest.permission.BLUETOOTH_CONNECT
        )

        val missingPermissions = permissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }

        if (missingPermissions.isNotEmpty()) {
            requestPermissionLauncher.launch(missingPermissions.toTypedArray())
        } else {
            refreshDevices()
        }
    }

    private fun refreshDevices() {
        viewModel.refreshDevices()
    }

    private fun updateUI(devices: List<DeviceInfo>) {
        if (devices.isEmpty()) {
            binding.emptyView.visibility = View.VISIBLE
            binding.devicesRecyclerView.visibility = View.GONE
        } else {
            binding.emptyView.visibility = View.GONE
            binding.devicesRecyclerView.visibility = View.VISIBLE
        }
    }

    private fun updateSelectedDeviceInfo(device: DeviceInfo?) {
        device?.let {
            binding.selectedDeviceInfo.visibility = View.VISIBLE
            binding.deviceNameText.text = it.name
            binding.deviceAddressText.text = it.address
            binding.deviceStatusText.text = it.status
            binding.batteryLevelText.text = "${it.batteryLevel}%"
        } ?: run {
            binding.selectedDeviceInfo.visibility = View.GONE
        }
    }

    class DeviceAdapter(
        private val onDeviceClick: (DeviceInfo) -> Unit
    ) : RecyclerView.Adapter<DeviceAdapter.DeviceViewHolder>() {

        private var devices = listOf<DeviceInfo>()

        fun submitList(newDevices: List<DeviceInfo>) {
            devices = newDevices
            notifyDataSetChanged()
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): DeviceViewHolder {
            val binding = ItemDeviceBinding.inflate(
                LayoutInflater.from(parent.context),
                parent,
                false
            )
            return DeviceViewHolder(binding)
        }

        override fun onBindViewHolder(holder: DeviceViewHolder, position: Int) {
            holder.bind(devices[position])
        }

        override fun getItemCount(): Int = devices.size

        inner class DeviceViewHolder(
            private val binding: ItemDeviceBinding
        ) : RecyclerView.ViewHolder(binding.root) {

            fun bind(device: DeviceInfo) {
                binding.deviceNameText.text = device.name
                binding.deviceAddressText.text = device.address
                binding.deviceStatusText.text = device.status

                binding.root.setOnClickListener {
                    onDeviceClick(device)
                }
            }
        }
    }
}