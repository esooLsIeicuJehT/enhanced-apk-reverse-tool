package com.apktool.Companion.services

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.apktool.Companion.R
import com.google.gson.Gson
import com.google.gson.JsonObject
import kotlinx.coroutines.*
import kotlinx.coroutines.channels.consumeEach
import org.java_websocket.client.WebSocketClient
import org.java_websocket.handshake.ServerHandshake
import java.net.URI

data class WebSocketMessage(
    val type: String,
    val data: JsonObject,
    val timestamp: Long = System.currentTimeMillis()
)

class WebSocketService : Service() {
    
    companion object {
        const val CHANNEL_ID = "ws_notification_channel"
        const val NOTIFICATION_ID = 1001
        
        private const val ACTION_CONNECT = "action_connect"
        private const val ACTION_DISCONNECT = "action_disconnect"
        const val ACTION_SEND_MESSAGE = "action_send_message"
        const val EXTRA_MESSAGE = "extra_message"
        
        // WebSocket URL (configurable)
        private const val DEFAULT_WS_URL = "ws://localhost:8080/ws"
    }
    
    private val binder = LocalBinder()
    private var webSocketClient: WebSocketClient? = null
    private var isConnected = false
    private val serviceScope = CoroutineScope(Dispatchers.IO + Job())
    
    // Connection listeners
    private val connectionListeners = mutableListOf<ConnectionListener>()
    
    // Message listeners
    private val messageListeners = mutableMapOf<String, List<MessageListener>>()
    
    private var reconnectAttempts = 0
    private var reconnectDelay = 1000L
    private val MAX_RECONNECT_ATTEMPTS = 5
    private val MAX_RECONNECT_DELAY = 30000L
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }
    
    override fun onBind(intent: Intent?): IBinder {
        return binder
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.action?.let { action ->
            when (action) {
                ACTION_CONNECT -> {
                    val url = intent.getStringExtra("url") ?: DEFAULT_WS_URL
                    connect(url)
                }
                ACTION_DISCONNECT -> {
                    disconnect()
                }
                ACTION_SEND_MESSAGE -> {
                    val message = intent.getStringExtra(EXTRA_MESSAGE)
                    message?.let { sendMessage(it) }
                }
            }
        }
        return START_NOT_STICKY
    }
    
    override fun onDestroy() {
        super.onDestroy()
        disconnect()
        serviceScope.cancel()
    }
    
    /**
     * Connect to WebSocket server
     */
    fun connect(url: String = DEFAULT_WS()): Boolean {
        if (isConnected) {
            return true
        }
        
        try {
            val uri = URI(url)
            webSocketClient = object : WebSocketClient(uri) {
                override fun onOpen(handshake: ServerHandshake?) {
                    isConnected = true
                    reconnectAttempts = 0
                    notifyConnectionChanged(true)
                    
                    // Send authentication message
                    sendAuthMessage()
                    
                    // Start heartbeat
                    startHeartbeat()
                }
                
                override fun onMessage(message: String?) {
                    message?.let {
                        handleIncomingMessage(it)
                    }
                }
                
                override fun onClose(code: Int, reason: String?, remote: Boolean) {
                    isConnected = false
                    notifyConnectionChanged(false)
                    
                    // Attempt to reconnect
                    if (reconnectAttempts < MAX_RECONNECT_ATTEMPTS) {
                        reconnect()
                    } else {
                        showReconnectFailedNotification()
                    }
                }
                
                override fun onError(ex: Exception?) {
                    isConnected = false
                    notifyConnectionChanged(false)
                    showError("WebSocket error: ${ex?.message}")
                }
            }
            
            webSocketClient?.connect()
            
            // Show notification
            startForegroundService()
            
            return true
            
        } catch (e: Exception) {
            showError("Failed to connect: ${e.message}")
            return false
        }
    }
    
    /**
     * Disconnect from WebSocket server
     */
    fun disconnect() {
        webSocketClient?.close()
        webSocket = null
        isConnected = false
        reconnectAttempts = 0
        notifyConnectionChanged(false)
        stopForeground(STOP_FOREGROUND_REMOVE)
    }
    
    /**
     * Send message to server
     */
    fun sendMessage(type: String, data: JsonObject = JsonObject()): Boolean {
        val message = WebSocketMessage(type = type, data = data)
        return sendMessage(Gson().toJson(message))
    }
    
    /**
     * Send JSON message to server
     */
    fun sendMessage(message: String): Boolean {
        return try {
            webSocket?.send(message)
            true
        } catch (e: Exception) {
            showError("Failed to send message: ${e.message}")
            false
        }
    }
    
    /**
     * Add connection listener
     */
    fun addConnectionListener(listener: ConnectionListener) {
        connectionListeners.add(listener)
    }
    
    /**
     * Remove connection listener
     */
    fun removeConnectionListener(listener: Connection) {
        connectionListeners.remove(listener)
    }
    
    /**
     * Add message listener
     */
    fun addMessageListener(type: String, listener: MessageListener) {
        messageListeners.getOrPut(type) { mutableListOf() }.add(listener)
    }
    
    /**
     * Remove message listener
     */
    fun removeMessageListener(type: String, listener: MessageListener) {
        messageListeners[type]?.remove(listener)
    }
    
    private fun handleIncomingMessage(message::String) {
        try {
            val gson = Gson()
            val wsMessage = gson.fromJson(message, WebSocketMessage::class.java)
            
            // Handle heartbeat
            if (wsMessage.type == "heartbeat") {
                // Ignore heartbeat messages
               定型
            }
            
            // Notify listeners
            messageListeners[wsMessage.type]?.forEach { listener ->
                listener.onMessage(wsMessage.data)
            }
            
        } catch (e: Exception) {
            showError("Failed to parse message: ${e.message}")
        }
    }
    
    private fun sendAuthMessage() {
        // Send authentication message
        val authData = JsonObject().apply {
            addProperty("token", "auth_token_here")
        }
        sendMessage("auth", authData)
    }
    
    private fun startHeartbeat() {
        serviceScope.launch {
            while (isConnected && webSocket?.isOpen == true) {
                try {
                    // Send heartbeat every 30 seconds
                    sendMessage("heartbeat", JsonObject())
                    delay(30000)
                } catch (e: Exception) {
                    // If heartbeat fails, disconnect
                    if (!isConnected) {
                        break
                    }
                }
            }
        }
    }
    
    private fun reconnect() {
        serviceScope.launch {
            try {
                delay(reconnectDelay)
                
                if (reconnectAttempts < MAX_RECONNECT_ATTEMPTS) {
                    reconnectAttempts++
                    reconnectDelay *= 2
                    reconnectDelay = minOf(reconnectDelay, MAX_RECONNECT_DELAY)
                    
                    showReconnectingNotification()
                    
                    webSocket?.reconnect()
                }
            } catch (e: Exception) {
                showError("Reconnect failed: ${e.message}")
            }
        }
    }
    
    private fun notifyConnectionChanged(connected: Boolean) {
        connectionListenersactor {
            it.onConnectionChanged(connected)
        }
    }
    
    private fun showError(message: String) {
        connectionListeners.forEach {
            it.onError(message)
        }
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "WebSocket Notifications",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notifications for WebSocket status"
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun startForegroundService() {
        val notification = createNotification(
            "Connected",
            "WebSocket service active"
        )
        
        startForeground(NOTIFICATION_ID, notification)
    }
    
    private fun createNotification(title: String, content: String): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(R.drawable.ic_notification)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
    }
    
    private fun showReconnectingNotification() {
        val notification = createNotification(
            "Reconnecting...",
            "Attempting to reconnect to server"
        )
        
        NotificationManagerCompat.from(this)
            .notify(NOTIFICATION_ID, notification)
    }
    
    private fun showReconnectFailed() {
        val notification = createNotification(
            "Connection Lost",
            "Failed to reconnect to server"
        )
        
        NotificationManagerCompat.from(this)
            .notify(NOTIFICATION_ID, notification)
    }
    
    /**
     * Binder for clients
     */
    inner class LocalBinder : Binder() {
        fun getService(): WebSocketService = this@WebSocketService
    }
}

/**
 * Connection listener interface
 */
interface ConnectionListener {
    fun onConnectionChanged(connected: Boolean)
    fun onError(error: String)
}

/**
 * Message listener interface
 */
interface MessageListener {
    fun onMessage(data: JsonObject)
}