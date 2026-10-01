package com.krisnayukrisna.seruma

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget layar utama: sisa uang aman hari ini, mood pasangan, dan urusan yang perlu dipikirkan.
 * Datanya dikirim dari Flutter lewat HomeWidgetService.
 */
class HomeSummaryWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.home_summary_widget).apply {
                setTextViewText(R.id.safe_to_spend, widgetData.getString("safe_to_spend", "Rp0"))
                setTextViewText(R.id.partner_mood, widgetData.getString("partner_mood", "Belum check-in"))
                setTextViewText(R.id.tasks_line, widgetData.getString("tasks_line", "Belum ada urusan"))
                setTextViewText(R.id.tasks_count, widgetData.getString("tasks_count", ""))
                setTextViewText(R.id.label_safe, widgetData.getString("label_safe", "Aman dipakai"))
                setTextViewText(R.id.label_tasks, widgetData.getString("label_tasks", "Perlu dipikirkan"))
                val launch = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_root, launch)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
