package com.example.worktime_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetBackgroundIntent // <--- 加了这一行！

class WorktimeWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        mgr: AppWidgetManager,
        ids: IntArray
    ) {
        ids.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.worktime_widget)
            val prefs = HomeWidgetPlugin.getData(context)

            views.setTextViewText(R.id.widget_date,
                prefs.getString("widget_date", "--"))
            views.setTextViewText(R.id.widget_status,
                prefs.getString("widget_status", "未打卡"))
            views.setTextViewText(R.id.widget_in,
                "上班 ${prefs.getString("widget_in", "--")}")
            views.setTextViewText(R.id.widget_out,
                "下班 ${prefs.getString("widget_out", "--")}")
            views.setTextViewText(R.id.widget_break,
                "休息 ${prefs.getString("widget_break", "--")}")

            views.setOnClickPendingIntent(
                R.id.widget_btn_in,
                bgIntent(context, "worktime://clock_in"))
            views.setOnClickPendingIntent(
                R.id.widget_btn_out,
                bgIntent(context, "worktime://clock_out"))

            mgr.updateAppWidget(id, views)
        }
    }

    private fun bgIntent(context: Context, uri: String): PendingIntent {
        return HomeWidgetBackgroundIntent.getBroadcast(
            context, Uri.parse(uri)
        )
    }
}
