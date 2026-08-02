from pathlib import Path

ROOT = Path("android/app/src/main")
DRAWABLE = ROOT / "res/drawable"
LAYOUT = ROOT / "res/layout"
XML = ROOT / "res/xml"
KOTLIN = ROOT / "kotlin/com/pourtoujours/pour_toujours"


def write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content.strip() + "\n", encoding="utf-8")


def rounded_gradient(start: str, end: str, radius: int = 28, stroke: str = "#38FFFFFF") -> str:
    return f'''<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <gradient android:angle="315" android:startColor="{start}" android:endColor="{end}" />
    <corners android:radius="{radius}dp" />
    <stroke android:width="1dp" android:color="{stroke}" />
</shape>'''


def scene(city: str, night: bool) -> str:
    palettes = {
        "karachi": (("#17213E", "#77435D"), ("#09152D", "#262147")),
        "chiba": (("#4E7E9E", "#E3A17B"), ("#17243E", "#394C70")),
        "dublin": (("#53697D", "#B05B75"), ("#141D35", "#3B3157")),
        "hattiesburg": (("#557A68", "#C29955"), ("#132A31", "#324A46")),
    }
    silhouettes = {
        "karachi": '''<path android:fillColor="#74333B42" android:pathData="M0,79L0,100L100,100L100,72L94,72L94,55L88,55L88,76L81,76L81,61L75,61L75,78L67,78L67,68L59,68L59,79L52,79L52,58L44,58L44,78L36,78L36,64L28,64L28,80L20,80L20,69L12,69L12,80Z"/><path android:fillColor="#3C52C3C8" android:pathData="M0,84L100,84L100,100L0,100Z"/>''',
        "chiba": '''<path android:fillColor="#6A344957" android:pathData="M0,81L0,100L100,100L100,76L92,76L92,61L84,61L84,80L75,80L75,67L66,67L66,81L57,81L57,56L49,56L49,80L40,80L40,69L31,69L31,81L20,81L20,63L13,63L13,82Z"/><path android:fillColor="#3B66B7C7" android:pathData="M0,86L100,86L100,100L0,100Z"/>''',
        "dublin": '''<path android:fillColor="#70403145" android:pathData="M0,79L8,70L16,79L24,67L33,79L42,69L52,79L61,65L72,79L82,68L92,79L100,71L100,100L0,100Z"/><path android:fillColor="#2AFFFFFF" android:pathData="M13,79L13,67M24,79L24,67M42,79L42,68M61,79L61,64M82,79L82,68"/>''',
        "hattiesburg": '''<path android:fillColor="#7030442D" android:pathData="M0,80C8,62 17,64 23,80C29,58 40,60 46,80C52,55 64,58 69,80C75,60 87,61 92,80C96,67 100,67 100,80L100,100L0,100Z"/><path android:fillColor="#424A352A" android:pathData="M8,100L13,72L17,100M37,100L42,68L47,100M73,100L78,70L83,100"/>''',
    }
    top, bottom = palettes[city][1 if night else 0]
    celestial = (
        '<path android:fillColor="#E8FFF3C4" android:pathData="M79,14A6,6 0,1 0,79 26A6,6 0,1 0,79 14M82,14A6,6 0,0 1,82 26A5,5 0,0 0,82 14" />'
        if night
        else '<path android:fillColor="#FFFFDEA0" android:pathData="M79,13A7,7 0,1 0,79 27A7,7 0,1 0,79 13" />'
    )
    stars = '<path android:fillColor="#99FFFFFF" android:pathData="M9,14A1,1 0,1 0,9 16A1,1 0,1 0,9 14M24,9A0.7,0.7 0,1 0,24 10.4A0.7,0.7 0,1 0,24 9M53,17A0.8,0.8 0,1 0,53 18.6A0.8,0.8 0,1 0,53 17M91,31A0.7,0.7 0,1 0,91 32.4A0.7,0.7 0,1 0,91 31" />' if night else ''
    return f'''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="320dp" android:height="230dp" android:viewportWidth="100" android:viewportHeight="100">
    <path android:fillColor="{top}" android:pathData="M0,0L100,0L100,100L0,100Z" />
    <path android:fillColor="{bottom}" android:pathData="M0,42C25,29 61,52 100,31L100,100L0,100Z" />
    {stars}
    {celestial}
    <path android:fillColor="#35FFFFFF" android:pathData="M-13,25C-4,14 8,15 15,24C22,17 34,19 40,28C30,33 4,33 -13,25M46,20C55,8 69,10 76,20C83,13 95,15 103,25C89,31 61,30 46,20M17,44C27,32 42,34 49,44C57,36 70,39 76,49C61,54 34,54 17,44" />
    {silhouettes[city]}
</vector>'''


def widget_info(layout_name: str, width: int, height: int) -> str:
    return f'''<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:initialLayout="@layout/{layout_name}"
    android:previewLayout="@layout/{layout_name}"
    android:minWidth="{width}dp"
    android:minHeight="{height}dp"
    android:minResizeWidth="120dp"
    android:minResizeHeight="100dp"
    android:resizeMode="horizontal|vertical"
    android:updatePeriodMillis="1800000"
    android:widgetCategory="home_screen" />'''


def prepare_drawables() -> None:
    write(DRAWABLE / "pt_widget_world_v2_bg.xml", rounded_gradient("#061D29", "#125457", 30))
    write(DRAWABLE / "pt_widget_cities_v2_bg.xml", rounded_gradient("#261328", "#713C54", 30))
    write(DRAWABLE / "pt_widget_glass.xml", rounded_gradient("#3AFFFFFF", "#16FFFFFF", 20, "#2FFFFFFF"))
    write(DRAWABLE / "pt_widget_alert.xml", rounded_gradient("#66564922", "#3D2D6B51", 18, "#46F3C86B"))
    write(DRAWABLE / "pt_world_map.xml", '''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="360dp" android:height="220dp" android:viewportWidth="180" android:viewportHeight="100">
    <path android:fillColor="#12FFFFFF" android:pathData="M0,0L180,0L180,100L0,100Z" />
    <path android:fillColor="#327DD4C8" android:pathData="M9,31L18,20L32,17L42,23L48,34L39,40L29,38L23,48L14,43ZM50,51L60,47L68,56L65,70L58,83L52,72L55,61ZM79,27L89,19L104,20L111,27L125,24L141,31L151,42L143,52L128,49L119,56L108,50L99,57L89,49L83,39ZM116,59L127,57L135,67L131,81L121,84L114,72ZM148,68L158,64L170,70L166,81L154,83L146,76Z" />
    <path android:fillColor="#00000000" android:strokeColor="#447FE0D2" android:strokeWidth="0.8" android:pathData="M137,43C116,36 72,34 36,43M137,43C128,58 113,69 94,76M36,43C56,57 73,67 94,76" />
    <path android:fillColor="#8AFFFFFF" android:pathData="M137,42A2,2 0,1 0,137 46A2,2 0,1 0,137 42M151,39A2,2 0,1 0,151 43A2,2 0,1 0,151 39M94,74A2,2 0,1 0,94 78A2,2 0,1 0,94 74M36,41A2,2 0,1 0,36 45A2,2 0,1 0,36 41" />
</vector>''')
    for city in ("karachi", "chiba", "dublin", "hattiesburg"):
        write(DRAWABLE / f"pt_scene_{city}_day.xml", scene(city, False))
        write(DRAWABLE / f"pt_scene_{city}_night.xml", scene(city, True))


def marker(view_id: str, gravity: str, left: int, top: int, width: int = 104) -> str:
    return f'''<TextView android:id="@+id/{view_id}" android:layout_width="{width}dp" android:layout_height="wrap_content" android:layout_gravity="{gravity}" android:layout_marginLeft="{left}dp" android:layout_marginTop="{top}dp" android:padding="8dp" android:gravity="center" android:background="@drawable/pt_widget_glass" android:textColor="#FFF9EC" android:textSize="11sp" android:textStyle="bold" android:maxLines="2" android:ellipsize="end" />'''


def city_cell(view_id: str) -> str:
    return f'''<TextView android:id="@+id/{view_id}" android:layout_width="0dp" android:layout_height="match_parent" android:layout_weight="1" android:layout_margin="4dp" android:padding="11dp" android:gravity="left|center_vertical" android:background="@drawable/pt_widget_glass" android:textColor="#FFF9EC" android:textSize="12sp" android:maxLines="3" android:ellipsize="end" />'''


def prepare_layouts() -> None:
    write(LAYOUT / "pt_widget_world.xml", f'''<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android" android:id="@+id/world_root" android:layout_width="match_parent" android:layout_height="match_parent" android:padding="14dp" android:background="@drawable/pt_widget_world_v2_bg">
    <ImageView android:layout_width="match_parent" android:layout_height="match_parent" android:layout_marginTop="34dp" android:layout_marginBottom="31dp" android:src="@drawable/pt_world_map" android:scaleType="fitXY" />
    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content" android:gravity="center_vertical">
        <ImageView android:layout_width="27dp" android:layout_height="27dp" android:src="@drawable/ic_pour_toujours" />
        <LinearLayout android:layout_width="0dp" android:layout_height="wrap_content" android:layout_weight="1" android:layout_marginStart="8dp" android:orientation="vertical">
            <TextView android:layout_width="match_parent" android:layout_height="wrap_content" android:text="Family world" android:textColor="#FFF9EC" android:textSize="18sp" android:textStyle="bold" />
            <TextView android:layout_width="match_parent" android:layout_height="wrap_content" android:text="Four places · one shared day" android:textColor="#A9DCD4" android:textSize="10sp" />
        </LinearLayout>
    </LinearLayout>
    {marker("world_hattiesburg", "top|left", 0, 73, 105)}
    {marker("world_dublin", "top|center_horizontal", -10, 54, 92)}
    {marker("world_karachi", "top|right", 30, 74, 96)}
    {marker("world_chiba", "top|right", 0, 47, 92)}
    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content" android:layout_gravity="bottom" android:orientation="vertical">
        <TextView android:id="@+id/world_footer" android:layout_width="match_parent" android:layout_height="wrap_content" android:gravity="center" android:textColor="#D7F3EC" android:textSize="11sp" android:maxLines="1" android:ellipsize="end" />
        <TextView android:id="@+id/world_updated" android:layout_width="match_parent" android:layout_height="wrap_content" android:gravity="center" android:textColor="#7FC2B9" android:textSize="9sp" />
    </LinearLayout>
</FrameLayout>''')

    write(LAYOUT / "pt_widget_cities.xml", f'''<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:id="@+id/cities_root" android:layout_width="match_parent" android:layout_height="match_parent" android:orientation="vertical" android:padding="12dp" android:background="@drawable/pt_widget_cities_v2_bg">
    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content" android:gravity="center_vertical">
        <ImageView android:layout_width="25dp" android:layout_height="25dp" android:src="@drawable/ic_pour_toujours" />
        <TextView android:layout_width="0dp" android:layout_height="wrap_content" android:layout_weight="1" android:layout_marginStart="8dp" android:text="Four cities · right now" android:textColor="#FFF9EC" android:textSize="17sp" android:textStyle="bold" />
    </LinearLayout>
    <LinearLayout android:layout_width="match_parent" android:layout_height="0dp" android:layout_weight="1" android:orientation="vertical" android:layout_marginTop="5dp">
        <LinearLayout android:layout_width="match_parent" android:layout_height="0dp" android:layout_weight="1" android:orientation="horizontal">{city_cell("cities_karachi")}{city_cell("cities_chiba")}</LinearLayout>
        <LinearLayout android:layout_width="match_parent" android:layout_height="0dp" android:layout_weight="1" android:orientation="horizontal">{city_cell("cities_dublin")}{city_cell("cities_hattiesburg")}</LinearLayout>
    </LinearLayout>
    <TextView android:id="@+id/cities_updated" android:layout_width="match_parent" android:layout_height="wrap_content" android:gravity="center" android:textColor="#D8B7C7" android:textSize="9sp" />
</LinearLayout>''')

    write(LAYOUT / "pt_widget_city.xml", '''<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android" android:id="@+id/city_root" android:layout_width="match_parent" android:layout_height="match_parent">
    <ImageView android:id="@+id/city_scene" android:layout_width="match_parent" android:layout_height="match_parent" android:scaleType="fitXY" />
    <LinearLayout android:layout_width="match_parent" android:layout_height="match_parent" android:orientation="vertical" android:padding="15dp">
        <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content" android:gravity="top">
            <LinearLayout android:layout_width="0dp" android:layout_height="wrap_content" android:layout_weight="1" android:orientation="vertical">
                <TextView android:id="@+id/city_name" android:layout_width="match_parent" android:layout_height="wrap_content" android:textColor="#FFFFFF" android:textSize="23sp" android:textStyle="bold" android:maxLines="1" android:ellipsize="end" />
                <TextView android:id="@+id/city_date_time" android:layout_width="match_parent" android:layout_height="wrap_content" android:textColor="#E8FFFFFF" android:textSize="11sp" android:maxLines="1" android:ellipsize="end" />
            </LinearLayout>
            <TextView android:id="@+id/city_weather_icon" android:layout_width="42dp" android:layout_height="42dp" android:gravity="center" android:textColor="#FFF5D48A" android:textSize="27sp" />
        </LinearLayout>
        <Space android:layout_width="1dp" android:layout_height="0dp" android:layout_weight="1" />
        <TextView android:id="@+id/city_temp" android:layout_width="match_parent" android:layout_height="wrap_content" android:textColor="#FFFFFF" android:textSize="40sp" android:textStyle="bold" />
        <TextView android:id="@+id/city_condition" android:layout_width="match_parent" android:layout_height="wrap_content" android:textColor="#FFFFFF" android:textSize="16sp" android:textStyle="bold" android:maxLines="1" android:ellipsize="end" />
        <TextView android:id="@+id/city_status" android:layout_width="match_parent" android:layout_height="wrap_content" android:layout_marginTop="3dp" android:textColor="#E2FFFFFF" android:textSize="11sp" android:maxLines="1" android:ellipsize="end" />
        <TextView android:id="@+id/city_alert" android:layout_width="match_parent" android:layout_height="wrap_content" android:layout_marginTop="8dp" android:padding="8dp" android:background="@drawable/pt_widget_alert" android:textColor="#FFF3CF" android:textSize="10sp" android:textStyle="bold" android:maxLines="2" android:ellipsize="end" />
        <TextView android:id="@+id/city_updated" android:layout_width="match_parent" android:layout_height="wrap_content" android:layout_marginTop="5dp" android:textColor="#B9FFFFFF" android:textSize="9sp" />
    </LinearLayout>
</FrameLayout>''')


def prepare_metadata() -> None:
    write(XML / "pt_widget_world_info.xml", widget_info("pt_widget_world", 280, 220))
    write(XML / "pt_widget_cities_info.xml", widget_info("pt_widget_cities", 250, 170))
    for city in ("karachi", "chiba", "dublin", "hattiesburg"):
        write(XML / f"pt_widget_{city}_info.xml", widget_info("pt_widget_city", 180, 180))


def prepare_kotlin() -> None:
    write(KOTLIN / "PourToujoursWidgets.kt", r'''package com.pourtoujours.pour_toujours

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

private fun read(data: SharedPreferences, key: String, fallback: String): String =
    runCatching { data.getString(key, null) }.getOrNull()?.trim()?.takeIf { it.isNotEmpty() }?.take(180) ?: fallback

private fun updated(data: SharedPreferences): String =
    if (read(data, "pt_stale", "0") == "1") "Latest saved update · offline" else "Last refreshed in app"

private fun openApp(context: Context): PendingIntent {
    val intent = Intent(context, MainActivity::class.java).apply {
        action = Intent.ACTION_MAIN
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
    }
    return PendingIntent.getActivity(context, 900, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
}

private fun openCity(context: Context, city: String): PendingIntent {
    val intent = Intent(context, MainActivity::class.java).apply {
        action = Intent.ACTION_VIEW
        data = Uri.parse("pourtoujours:///city/$city")
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
    }
    return PendingIntent.getActivity(context, city.hashCode(), intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
}

private fun glyph(code: Int, day: Boolean): String = when {
    code >= 95 -> "⚡"
    code in 71..77 -> "❄"
    code in 51..67 || code in 80..82 -> "☂"
    code == 45 || code == 48 -> "≋"
    code >= 2 -> "☁"
    day -> "☀"
    else -> "☾"
}

private fun code(data: SharedPreferences, city: String): Int = read(data, "pt_${city}_weather_code", "0").toIntOrNull() ?: 0
private fun isDay(data: SharedPreferences, city: String): Boolean = read(data, "pt_${city}_is_day", "0") == "1"

class PourToujoursWorldWidget : HomeWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray, data: SharedPreferences) = ids.forEach { id ->
        runCatching {
            val views = RemoteViews(context.packageName, R.layout.pt_widget_world)
            listOf(
                "karachi" to R.id.world_karachi,
                "chiba" to R.id.world_chiba,
                "dublin" to R.id.world_dublin,
                "hattiesburg" to R.id.world_hattiesburg,
            ).forEach { (city, view) ->
                val name = read(data, "pt_${city}_name", city.replaceFirstChar { it.uppercase() })
                val time = read(data, "pt_${city}_time", "—")
                views.setTextViewText(view, "$name\n${glyph(code(data, city), isDay(data, city))} $time")
                views.setOnClickPendingIntent(view, openCity(context, city))
            }
            val next = read(data, "pt_next_event", "No saved family moment")
            views.setTextViewText(R.id.world_footer, "${read(data, "pt_daylight_cities", "0")} daylight · ${read(data, "pt_active_alerts", "0")} alerts · $next")
            views.setTextViewText(R.id.world_updated, updated(data))
            views.setOnClickPendingIntent(R.id.world_root, openApp(context))
            manager.updateAppWidget(id, views)
        }.onFailure { Log.w("PourToujoursWidget", "World widget update skipped", it) }
    }
}

class PourToujoursCitiesWidget : HomeWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray, data: SharedPreferences) = ids.forEach { id ->
        runCatching {
            val views = RemoteViews(context.packageName, R.layout.pt_widget_cities)
            listOf(
                "karachi" to R.id.cities_karachi,
                "chiba" to R.id.cities_chiba,
                "dublin" to R.id.cities_dublin,
                "hattiesburg" to R.id.cities_hattiesburg,
            ).forEach { (city, view) ->
                val name = read(data, "pt_${city}_name", city.replaceFirstChar { it.uppercase() })
                val temp = read(data, "pt_${city}_temp", "—")
                val time = read(data, "pt_${city}_time", "—")
                val date = read(data, "pt_${city}_date", "—")
                val condition = read(data, "pt_${city}_condition", "Open app to refresh")
                views.setTextViewText(view, "${glyph(code(data, city), isDay(data, city))} $name  $temp\n$time · $date\n$condition")
                views.setOnClickPendingIntent(view, openCity(context, city))
            }
            views.setTextViewText(R.id.cities_updated, updated(data))
            views.setOnClickPendingIntent(R.id.cities_root, openApp(context))
            manager.updateAppWidget(id, views)
        }.onFailure { Log.w("PourToujoursWidget", "Cities widget update skipped", it) }
    }
}

abstract class CityWidget(
    private val city: String,
    private val dayScene: Int,
    private val nightScene: Int,
) : HomeWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray, data: SharedPreferences) = ids.forEach { id ->
        runCatching {
            val views = RemoteViews(context.packageName, R.layout.pt_widget_city)
            val day = isDay(data, city)
            views.setImageViewResource(R.id.city_scene, if (day) dayScene else nightScene)
            views.setTextViewText(R.id.city_name, read(data, "pt_${city}_name", city.replaceFirstChar { it.uppercase() }))
            views.setTextViewText(R.id.city_date_time, "${read(data, "pt_${city}_date", "—")} · ${read(data, "pt_${city}_time", "—")}")
            views.setTextViewText(R.id.city_weather_icon, glyph(code(data, city), day))
            views.setTextViewText(R.id.city_temp, read(data, "pt_${city}_temp", "—"))
            views.setTextViewText(R.id.city_condition, read(data, "pt_${city}_condition", "Open app to refresh"))
            views.setTextViewText(R.id.city_status, read(data, "pt_${city}_status", "Family context unavailable"))
            val alert = read(data, "pt_${city}_alert", "No important alert")
            views.setTextViewText(R.id.city_alert, alert)
            views.setViewVisibility(R.id.city_alert, if (alert.startsWith("No important", ignoreCase = true)) View.GONE else View.VISIBLE)
            views.setTextViewText(R.id.city_updated, updated(data))
            views.setOnClickPendingIntent(R.id.city_root, openCity(context, city))
            manager.updateAppWidget(id, views)
        }.onFailure { Log.w("PourToujoursWidget", "$city widget update skipped", it) }
    }
}

class PourToujoursKarachiWidget : CityWidget("karachi", R.drawable.pt_scene_karachi_day, R.drawable.pt_scene_karachi_night)
class PourToujoursChibaWidget : CityWidget("chiba", R.drawable.pt_scene_chiba_day, R.drawable.pt_scene_chiba_night)
class PourToujoursDublinWidget : CityWidget("dublin", R.drawable.pt_scene_dublin_day, R.drawable.pt_scene_dublin_night)
class PourToujoursHattiesburgWidget : CityWidget("hattiesburg", R.drawable.pt_scene_hattiesburg_day, R.drawable.pt_scene_hattiesburg_night)
''')


def main() -> None:
    for directory in (DRAWABLE, LAYOUT, XML, KOTLIN):
        directory.mkdir(parents=True, exist_ok=True)
    prepare_drawables()
    prepare_layouts()
    prepare_metadata()
    prepare_kotlin()
    print("Prepared premium family-world, four-city, and city-specific widget pack.")


if __name__ == "__main__":
    main()
