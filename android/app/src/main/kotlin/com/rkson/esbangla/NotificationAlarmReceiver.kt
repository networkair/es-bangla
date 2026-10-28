package com.rkson.esbangla

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.os.SystemClock
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread

class NotificationAlarmReceiver : BroadcastReceiver() {

    companion object {
        const val CHANNEL_ID = "es_bangla_announcements"
        const val PREFS_NAME = "FlutterSharedPreferences"
        const val CHECK_INTERVAL_MS = 60_000L // 1 minute background periodic sync

        fun scheduleAlarm(context: Context) {
            try {
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
                val intent = Intent(context, NotificationAlarmReceiver::class.java).apply {
                    action = "com.rkson.esbangla.CHECK_NOTIFICATIONS"
                }
                val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val pendingIntent = PendingIntent.getBroadcast(context, 1001, intent, flags)
                val triggerAt = SystemClock.elapsedRealtime() + CHECK_INTERVAL_MS

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, pendingIntent)
                } else {
                    alarmManager.set(AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, pendingIntent)
                }
            } catch (_: Exception) {}
        }
    }

    override fun onReceive(context: Context, intent: Intent?) {
        // Reschedule next background tick
        scheduleAlarm(context)

        // Perform lightweight RTDB notification query on background thread
        thread {
            try {
                checkAndShowNotifications(context)
            } catch (_: Exception) {}
        }
    }

    private fun checkAndShowNotifications(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val userSemester = prefs.getLong("flutter.user_semester", 3L).toInt()
        val semKey1 = "c12_sem$userSemester"
        val semKey2 = "sem$userSemester"
        val semKey3 = userSemester.toString()

        // Read seen notification IDs
        val seenRaw = prefs.getString("flutter.seen_notif_ids_set", null)
        val seenSet = mutableSetOf<String>()
        if (seenRaw != null) {
            try {
                val arr = JSONArray(seenRaw)
                for (i in 0 until arr.length()) {
                    seenSet.add(arr.getString(i))
                }
            } catch (_: Exception) {}
        }

        // Fetch RTDB notifications
        val url = URL("https://es-bangla-225f2-default-rtdb.firebaseio.com/notifications.json")
        val conn = url.openConnection() as HttpURLConnection
        conn.connectTimeout = 6000
        conn.readTimeout = 6000
        conn.requestMethod = "GET"

        if (conn.responseCode == 200) {
            val reader = BufferedReader(InputStreamReader(conn.inputStream))
            val sb = StringBuilder()
            var line: String?
            while (reader.readLine().also { line = it } != null) {
                sb.append(line)
            }
            reader.close()

            val text = sb.toString().trim()
            if (text.startsWith("{")) {
                val json = JSONObject(text)
                val keys = json.keys()
                var newNotifFound = false

                // Existing local notifications
                val localNotifRaw = prefs.getString("flutter.user_local_notifications", null)
                val localNotifArr = try {
                    if (localNotifRaw != null) JSONArray(localNotifRaw) else JSONArray()
                } catch (_: Exception) {
                    JSONArray()
                }

                while (keys.hasNext()) {
                    val key = keys.next()
                    val item = json.optJSONObject(key) ?: continue

                    val isActive = item.optBoolean("isActive", true)
                    if (!isActive) continue

                    val audience = item.optString("audience", "all").trim().lowercase()
                    val isTarget = audience == "all" ||
                            audience == semKey1 ||
                            audience == semKey2 ||
                            audience == semKey3 ||
                            audience == "0"
                    if (!isTarget) continue

                    if (!seenSet.contains(key)) {
                        seenSet.add(key)
                        newNotifFound = true

                        val title = item.optString("title", "নতুন বিজ্ঞপ্তি 📢").trim()
                        val body = (if (item.has("body")) item.optString("body") else item.optString("message", "")).trim()
                        val imageUrl = (if (item.has("imageUrl")) item.optString("imageUrl") else item.optString("image", "")).trim()
                        val actionUrl = (if (item.has("actionUrl")) item.optString("actionUrl") else item.optString("link", "")).trim()
                        val createdAt = item.optLong("createdAt", System.currentTimeMillis())

                        // 1. Show Heads-up Android status bar notification
                        showNotification(context, key.hashCode(), title, body, imageUrl, actionUrl)

                        // 2. Save directly into device local storage
                        val notifObj = JSONObject().apply {
                            put("id", key)
                            put("title", title)
                            put("body", body)
                            put("imageUrl", imageUrl)
                            put("actionUrl", actionUrl)
                            put("timestamp", createdAt)
                            put("isRead", false)
                        }

                        // Prepend to local notifications
                        val newArr = JSONArray()
                        newArr.put(notifObj)
                        for (i in 0 until localNotifArr.length()) {
                            val existing = localNotifArr.getJSONObject(i)
                            if (existing.optString("id") != key) {
                                newArr.put(existing)
                            }
                        }
                        prefs.edit().putString("flutter.user_local_notifications", newArr.toString()).apply()
                    }
                }

                if (newNotifFound) {
                    val seenArr = JSONArray(seenSet)
                    prefs.edit().putString("flutter.seen_notif_ids_set", seenArr.toString()).apply()
                }
            }
        }
        conn.disconnect()
    }

    private fun showNotification(
        context: Context,
        notifId: Int,
        title: String,
        body: String,
        imageUrl: String,
        actionUrl: String
    ) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Create Channel if Android 8+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "বিজ্ঞপ্তি ও গুরুত্বপূর্ণ আপডেট (Announcements)",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "নোটিশ, রুটিন এবং স্টাডি সংক্রান্ত সমস্ত আপডেট"
                enableLights(true)
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(channel)
        }

        // Open MainActivity when notification is tapped
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            if (actionUrl.isNotEmpty()) {
                putExtra("actionUrl", actionUrl)
            }
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getActivity(context, notifId, launchIntent, flags)

        var bigBitmap: Bitmap? = null
        if (imageUrl.isNotEmpty() && (imageUrl.startsWith("http://") || imageUrl.startsWith("https://"))) {
            try {
                val imgUrl = URL(imageUrl)
                val imgConn = imgUrl.openConnection() as HttpURLConnection
                imgConn.connectTimeout = 4000
                imgConn.readTimeout = 4000
                if (imgConn.responseCode == 200) {
                    bigBitmap = BitmapFactory.decodeStream(imgConn.inputStream)
                }
                imgConn.disconnect()
            } catch (_: Exception) {}
        }

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setDefaults(NotificationCompat.DEFAULT_ALL)

        if (bigBitmap != null) {
            builder.setLargeIcon(bigBitmap)
            builder.setStyle(
                NotificationCompat.BigPictureStyle()
                    .bigPicture(bigBitmap)
                    .setBigContentTitle(title)
                    .setSummaryText(body)
            )
        } else {
            builder.setStyle(NotificationCompat.BigTextStyle().bigText(body))
        }

        notificationManager.notify((notifId and 0x7FFFFFFF), builder.build())
    }
}
