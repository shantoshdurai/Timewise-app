package com.example.flutter_firebase_test

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class RobotWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.robot_widget_layout).apply {
                val filePath = widgetData.getString("robot_widget", null)
                if (filePath != null) {
                    val bitmap = BitmapFactory.decodeFile(filePath)
                    if (bitmap != null) {
                        setImageViewBitmap(R.id.robot_widget_image, bitmap)
                    }
                }

                // Add Refresh Button Click Handling
                val pendingIntent = es.antonborri.home_widget.HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    android.net.Uri.parse("timewise://update")
                )
                setOnClickPendingIntent(R.id.btn_refresh_robot, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
