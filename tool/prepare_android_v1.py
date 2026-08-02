from pathlib import Path

ROOT = Path("android/app/src/main")
MANIFEST = ROOT / "AndroidManifest.xml"


def ensure_after(text: str, marker: str, addition: str) -> str:
    if addition.strip() in text:
        return text
    if marker not in text:
        raise RuntimeError(f"Required marker not found: {marker}")
    return text.replace(marker, marker + "\n" + addition, 1)


def prepare_manifest() -> None:
    text = MANIFEST.read_text(encoding="utf-8")
    root = '<manifest xmlns:android="http://schemas.android.com/apk/res/android">'
    for permission in (
        '<uses-permission android:name="android.permission.INTERNET" />',
        '<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />',
        '<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />',
    ):
        text = ensure_after(text, root, f"    {permission}")
    text = text.replace('android:label="pour_toujours"', 'android:label="Pour Toujours"')
    text = text.replace('android:icon="@mipmap/ic_launcher"', 'android:icon="@drawable/ic_pour_toujours"')

    providers = [
        ("PourToujoursWorldWidget", "Family World", "pt_widget_world_info"),
        ("PourToujoursCitiesWidget", "Four City Weather", "pt_widget_cities_info"),
        ("PourToujoursKarachiWidget", "Karachi Weather", "pt_widget_karachi_info"),
        ("PourToujoursChibaWidget", "Chiba Weather", "pt_widget_chiba_info"),
        ("PourToujoursDublinWidget", "Dublin Weather", "pt_widget_dublin_info"),
        ("PourToujoursHattiesburgWidget", "Hattiesburg Weather", "pt_widget_hattiesburg_info"),
    ]
    receivers = "\n".join(
        f'''        <receiver android:name=".{name}" android:label="{label}" android:exported="true">
            <intent-filter><action android:name="android.appwidget.action.APPWIDGET_UPDATE" /></intent-filter>
            <meta-data android:name="android.appwidget.provider" android:resource="@xml/{info}" />
        </receiver>'''
        for name, label, info in providers
    )
    native_components = f'''\n{receivers}
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" android:exported="false" />
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver" android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON" />
            </intent-filter>
        </receiver>
'''
    if ".PourToujoursWorldWidget" not in text:
        text = text.replace("</application>", native_components + "    </application>", 1)
    MANIFEST.write_text(text, encoding="utf-8")


def prepare_gradle() -> None:
    path = Path("android/app/build.gradle.kts")
    text = path.read_text(encoding="utf-8")
    if "isCoreLibraryDesugaringEnabled = true" not in text:
        text = text.replace("compileOptions {", "compileOptions {\n        isCoreLibraryDesugaringEnabled = true", 1)
    if "multiDexEnabled = true" not in text:
        text = text.replace("defaultConfig {", "defaultConfig {\n        multiDexEnabled = true", 1)
    dependency = 'coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")'
    if dependency not in text:
        text += f"\n\ndependencies {{\n    {dependency}\n}}\n"
    path.write_text(text, encoding="utf-8")


def write(path: Path, content: str) -> None:
    path.write_text(content.strip() + "\n", encoding="utf-8")


def shape(start: str, end: str, radius: int = 28) -> str:
    return f'''<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <gradient android:angle="315" android:startColor="{start}" android:endColor="{end}" />
    <corners android:radius="{radius}dp" />
    <stroke android:width="1dp" android:color="#42FFFFFF" />
</shape>'''


def scene_vector(top: str, bottom: str, landscape: str) -> str:
    silhouettes = {
        "karachi": '<path android:fillColor="#55344247" android:pathData="M0,78L0,100L100,100L100,73L94,73L94,55L88,55L88,75L81,75L81,61L75,61L75,77L68,77L68,68L60,68L60,78L52,78L52,59L45,59L45,77L36,77L36,65L29,65L29,79L20,79L20,70L12,70L12,79Z"/><path android:fillColor="#334FC3C8" android:pathData="M0,83L100,83L100,100L0,100Z"/>',
        "chiba": '<path android:fillColor="#55384B58" android:pathData="M0,80L0,100L100,100L100,76L92,76L92,62L84,62L84,79L75,79L75,68L66,68L66,80L56,80L56,57L49,57L49,79L39,79L39,70L31,70L31,80L20,80L20,64L13,64L13,81Z"/><path android:fillColor="#334EA6B7" android:pathData="M0,86L100,86L100,100L0,100Z"/>',
        "dublin": '<path android:fillColor="#55403145" android:pathData="M0,78L8,70L16,78L24,67L33,78L42,69L52,78L61,65L72,78L82,68L92,78L100,71L100,100L0,100Z"/>',
        "hattiesburg": '<path android:fillColor="#5530442D" android:pathData="M0,79C8,63 17,65 23,79C29,59 40,61 46,79C52,56 64,59 69,79C75,61 87,62 92,79C96,68 100,68 100,79L100,100L0,100Z"/>',
    }
    return f'''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="320dp" android:height="220dp" android:viewportWidth="100" android:viewportHeight="100">
    <path android:fillColor="{top}" android:pathData="M0,0L100,0L100,100L0,100Z" />
    <path android:fillColor="{bottom}" android:pathData="M0,45C30,30 67,58 100,35L100,100L0,100Z" />
    <path android:fillColor="#35FFFFFF" android:pathData="M-12,23C-3,13 8,14 15,23C22,17 34,18 39,27C31,31 4,31 -12,23M48,18C56,7 69,9 75,18C82,12 94,14 101,23C88,29 62,28 48,18M20,43C29,32 43,34 49,43C57,36 70,39 74,48C60,53 36,52 20,43" />
    <path android:fillColor="#FFF1B96A" android:pathData="M77,13A6,6 0,1 0,77 25A6,6 0,1 0,77 13" />
    {silhouettes[landscape]}
</vector>'''


def prepare_resources() -> None:
    drawable = ROOT / "res/drawable"
    layout = ROOT / "res/layout"
    xml = ROOT / "res/xml"
    kotlin = ROOT / "kotlin/com/pourtoujours/pour_toujours"
    for directory in (drawable, layout, xml, kotlin):
        directory.mkdir(parents=True, exist_ok=True)

    write(drawable / "ic_pour_toujours.xml", '''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#092E32" android:pathData="M54,8A46,46 0,1 0,54 100A46,46 0,1 0,54 8" />
    <path android:fillColor="#6DC0B5" android:pathData="M54,20A34,34 0,1 0,54 88A34,34 0,1 0,54 20" />
    <path android:fillColor="#0B3A43" android:pathData="M33,31L44,25L53,31L49,40L39,43L33,31M57,53L68,42L83,47L82,59L72,66L65,78L55,74L50,63L57,53M32,62L42,65L47,77L38,82L29,73L32,62" />
    <path android:fillColor="#00000000" android:strokeColor="#FFF7E6" android:strokeWidth="5" android:strokeLineCap="round" android:pathData="M12,60C31,78 76,79 96,48" />
    <path android:fillColor="#F2C15B" android:pathData="M82,18L85,25L92,28L85,31L82,38L79,31L72,28L79,25Z" />
</vector>''')
    write(drawable / "pt_world_bg.xml", shape("#071E29", "#164B4D"))
    write(drawable / "pt_cities_bg.xml", shape("#24152D", "#6A314B"))
    write(drawable / "pt_surface.xml", shape("#36FFFFFF", "#18FFFFFF", 18))
    write(drawable / "pt_scene_karachi.xml", scene_vector("#16304D", "#8C5D76", "karachi"))
    write(drawable / "pt_scene_chiba.xml", scene_vector("#315875", "#D89572", "chiba"))
    write(drawable / "pt_scene_dublin.xml", scene_vector("#263456", "#A44968", "dublin"))
    write(drawable / "pt_scene_hattiesburg.xml", scene_vector("#416F62", "#B38A4F", "hattiesburg"))

    write(layout / "pt_widget_world.xml", '''<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android" android:id="@+id/world_root" android:layout_width="match_parent" android:layout_height="match_parent" android:padding="16dp" android:background="@drawable/pt_world_bg">
    <TextView android:layout_width="match_parent" android:layout_height="match_parent" android:gravity="center" android:text="◜  ◝      ◜\n   ╲  FAMILY WORLD  ╱\n◟       ◞      ◟" android:textColor="#2E9ED0C8" android:textSize="30sp" />
    <LinearLayout android:layout_width="match_parent" android:layout_height="match_parent" android:orientation="vertical">
        <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content" android:gravity="center_vertical">
            <ImageView android:layout_width="28dp" android:layout_height="28dp" android:src="@drawable/ic_pour_toujours" />
            <TextView android:layout_width="0dp" android:layout_height="wrap_content" android:layout_weight="1" android:layout_marginStart="8dp" android:text="Family world" android:textColor="#FFF8EA" android:textSize="19sp" android:textStyle="bold" />
        </LinearLayout>
        <Space android:layout_width="1dp" android:layout_height="10dp" />
        <GridLayout android:layout_width="match_parent" android:layout_height="0dp" android:layout_weight="1" android:columnCount="2" android:rowCount="2">
            <TextView android:id="@+id/world_karachi" style="@style/PtWidgetMarker" />
            <TextView android:id="@+id/world_chiba" style="@style/PtWidgetMarker" />
            <TextView android:id="@+id/world_dublin" style="@style/PtWidgetMarker" />
            <TextView android:id="@+id/world_hattiesburg" style="@style/PtWidgetMarker" />
        </GridLayout>
        <TextView android:id="@+id/world_footer" android:layout_width="match_parent" android:layout_height="wrap_content" android:gravity="center" android:textColor="#BCE9E1" android:textSize="11sp" android:maxLines="1" />
        <TextView android:id="@+id/world_updated" android:layout_width="match_parent" android:layout_height="wrap_content" android:gravity="center" android:textColor="#78BDB4" android:textSize="9sp" />
    </LinearLayout>
</FrameLayout>''')

    write(layout / "pt_widget_cities.xml", '''<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:id="@+id/cities_root" android:layout_width="match_parent" android:layout_height="match_parent" android:orientation="vertical" android:padding="14dp" android:background="@drawable/pt_cities_bg">
    <TextView android:layout_width="match_parent" android:layout_height="wrap_content" android:text="Four cities · right now" android:textColor="#FFF8EA" android:textSize="18sp" android:textStyle="bold" />
    <GridLayout android:layout_width="match_parent" android:layout_height="0dp" android:layout_weight="1" android:layout_marginTop="8dp" android:columnCount="2" android:rowCount="2">
        <TextView android:id="@+id/cities_karachi" style="@style/PtWidgetCityCell" />
        <TextView android:id="@+id/cities_chiba" style="@style/PtWidgetCityCell" />
        <TextView android:id="@+id/cities_dublin" style="@style/PtWidgetCityCell" />
        <TextView android:id="@+id/cities_hattiesburg" style="@style/PtWidgetCityCell" />
    </GridLayout>
    <TextView android:id="@+id/cities_updated" android:layout_width="match_parent" android:layout_height="wrap_content" android:textColor="#D4AFC0" android:textSize="9sp" />
</LinearLayout>''')

    write(layout / "pt_widget_city.xml", '''<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android" android:id="@+id/city_root" android:layout_width="match_parent" android:layout_height="match_parent">
    <ImageView android:id="@+id/city_scene" android:layout_width="match_parent" android:layout_height="match_parent" android:scaleType="fitXY" />
    <LinearLayout android:layout_width="match_parent" android:layout_height="match_parent" android:orientation="vertical" android:padding="16dp">
        <TextView android:id="@+id/city_name" android:layout_width="match_parent" android:layout_height="wrap_content" android:textColor="#FFFFFF" android:textSize="23sp" android:textStyle="bold" />
        <TextView android:id="@+id/city_date_time" android:layout_width="match_parent" android:layout_height="wrap_content" android:textColor="#E8FFFFFF" android:textSize="12sp" />
        <Space android:layout_width="1dp" android:layout_height="0dp" android:layout_weight="1" />
        <TextView android:id="@+id/city_temp" android:layout_width="match_parent" android:layout_height="wrap_content" android:textColor="#FFFFFF" android:textSize="38sp" android:textStyle="bold" />
        <TextView android:id="@+id/city_condition" android:layout_width="match_parent" android:layout_height="wrap_content" android:textColor="#FFFFFF" android:textSize="15sp" android:textStyle="bold" android:maxLines="1" />
        <TextView android:id="@+id/city_status" android:layout_width="match_parent" android:layout_height="wrap_content" android:layout_marginTop="3dp" android:textColor="#D8FFFFFF" android:textSize="11sp" android:maxLines="1" />
        <TextView android:id="@+id/city_alert" android:layout_width="match_parent" android:layout_height="wrap_content" android:layout_marginTop="4dp" android:textColor="#FFFFD58A" android:textSize="10sp" android:textStyle="bold" android:maxLines="1" />
        <TextView android:id="@+id/city_updated" android:layout_width="match_parent" android:layout_height="wrap_content" android:layout_marginTop="3dp" android:textColor="#B8FFFFFF" android:textSize="8sp" />
    </LinearLayout>
</FrameLayout>''')

    values = ROOT / "res/values"
    values.mkdir(parents=True, exist_ok=True)
    write(values / "pt_widget_styles.xml", '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="PtWidgetMarker">
        <item name="android:layout_width">0dp</item><item name="android:layout_height">0dp</item>
        <item name="android:layout_columnWeight">1</item><item name="android:layout_rowWeight">1</item>
        <item name="android:layout_margin">4dp</item><item name="android:padding">8dp</item>
        <item name="android:background">@drawable/pt_surface</item><item name="android:gravity">center</item>
        <item name="android:textColor">#FFF8EA</item><item name="android:textSize">12sp</item><item name="android:textStyle">bold</item>
    </style>
    <style name="PtWidgetCityCell" parent="PtWidgetMarker">
        <item name="android:gravity">left|center_vertical</item><item name="android:textSize">12sp</item>
    </style>
</resources>''')

    def info(layout_name: str, width: int, height: int) -> str:
        return f'''<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android" android:initialLayout="@layout/{layout_name}" android:previewLayout="@layout/{layout_name}" android:minWidth="{width}dp" android:minHeight="{height}dp" android:resizeMode="horizontal|vertical" android:updatePeriodMillis="1800000" android:widgetCategory="home_screen" />'''

    write(xml / "pt_widget_world_info.xml", info("pt_widget_world", 250, 220))
    write(xml / "pt_widget_cities_info.xml", info("pt_widget_cities", 250, 150))
    for city in ("karachi", "chiba", "dublin", "hattiesburg"):
        write(xml / f"pt_widget_{city}_info.xml", info("pt_widget_city", 180, 180))

    write(kotlin / "PourToujoursWidgets.kt", '''package com.pourtoujours.pour_toujours

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

private fun read(data: SharedPreferences, key: String, fallback: String): String =
    runCatching { data.getString(key, null) }.getOrNull()?.trim()?.takeIf { it.isNotEmpty() }?.take(180) ?: fallback

private fun updated(data: SharedPreferences): String =
    if (read(data, "pt_stale", "0") == "1") "Last saved update · offline" else "Last refreshed in app"

private fun open(context: Context, route: String): PendingIntent {
    val intent = Intent(context, MainActivity::class.java).apply {
        action = Intent.ACTION_VIEW
        data = Uri.parse("pourtoujours://$route")
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
    }
    return PendingIntent.getActivity(context, route.hashCode(), intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
}

class PourToujoursWorldWidget : HomeWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray, data: SharedPreferences) = ids.forEach { id ->
        runCatching {
            val v = RemoteViews(context.packageName, R.layout.pt_widget_world)
            listOf("karachi" to R.id.world_karachi, "chiba" to R.id.world_chiba, "dublin" to R.id.world_dublin, "hattiesburg" to R.id.world_hattiesburg).forEach { (city, view) ->
                v.setTextViewText(view, "${read(data, "pt_${city}_name", city.replaceFirstChar { it.uppercase() })}\n${read(data, "pt_${city}_time", "—")} · ${read(data, "pt_${city}_temp", "—")}")
            }
            v.setTextViewText(R.id.world_footer, "${read(data, "pt_daylight_cities", "0")} cities in daylight · ${read(data, "pt_active_alerts", "0")} alerts")
            v.setTextViewText(R.id.world_updated, updated(data))
            v.setOnClickPendingIntent(R.id.world_root, open(context, "today"))
            manager.updateAppWidget(id, v)
        }.onFailure { Log.w("PourToujoursWidget", "World widget update skipped", it) }
    }
}

class PourToujoursCitiesWidget : HomeWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray, data: SharedPreferences) = ids.forEach { id ->
        runCatching {
            val v = RemoteViews(context.packageName, R.layout.pt_widget_cities)
            listOf("karachi" to R.id.cities_karachi, "chiba" to R.id.cities_chiba, "dublin" to R.id.cities_dublin, "hattiesburg" to R.id.cities_hattiesburg).forEach { (city, view) ->
                v.setTextViewText(view, "${read(data, "pt_${city}_name", city)}  ${read(data, "pt_${city}_temp", "—")}\n${read(data, "pt_${city}_time", "—")} · ${read(data, "pt_${city}_condition", "Refresh in app")}")
            }
            v.setTextViewText(R.id.cities_updated, updated(data))
            v.setOnClickPendingIntent(R.id.cities_root, open(context, "today"))
            manager.updateAppWidget(id, v)
        }.onFailure { Log.w("PourToujoursWidget", "Cities widget update skipped", it) }
    }
}

abstract class CityWidget(private val city: String, private val scene: Int) : HomeWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray, data: SharedPreferences) = ids.forEach { id ->
        runCatching {
            val v = RemoteViews(context.packageName, R.layout.pt_widget_city)
            v.setImageViewResource(R.id.city_scene, scene)
            v.setTextViewText(R.id.city_name, read(data, "pt_${city}_name", city.replaceFirstChar { it.uppercase() }))
            v.setTextViewText(R.id.city_date_time, "${read(data, "pt_${city}_date", "—")} · ${read(data, "pt_${city}_time", "—")}")
            v.setTextViewText(R.id.city_temp, read(data, "pt_${city}_temp", "—"))
            v.setTextViewText(R.id.city_condition, read(data, "pt_${city}_condition", "Open app to refresh"))
            v.setTextViewText(R.id.city_status, read(data, "pt_${city}_status", "Family context unavailable"))
            v.setTextViewText(R.id.city_alert, read(data, "pt_${city}_alert", "No important alert"))
            v.setTextViewText(R.id.city_updated, updated(data))
            v.setOnClickPendingIntent(R.id.city_root, open(context, "city/$city"))
            manager.updateAppWidget(id, v)
        }.onFailure { Log.w("PourToujoursWidget", "$city widget update skipped", it) }
    }
}

class PourToujoursKarachiWidget : CityWidget("karachi", R.drawable.pt_scene_karachi)
class PourToujoursChibaWidget : CityWidget("chiba", R.drawable.pt_scene_chiba)
class PourToujoursDublinWidget : CityWidget("dublin", R.drawable.pt_scene_dublin)
class PourToujoursHattiesburgWidget : CityWidget("hattiesburg", R.drawable.pt_scene_hattiesburg)
''')


if __name__ == "__main__":
    prepare_manifest()
    prepare_gradle()
    prepare_resources()
    print("Prepared six premium Pour Toujours Android widgets.")
