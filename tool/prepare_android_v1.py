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
    text = text.replace(
        'android:icon="@mipmap/ic_launcher"',
        'android:icon="@drawable/ic_pour_toujours"',
    )

    native_components = """
        <receiver android:name=".PourToujoursSmallWidget" android:exported="true">
            <intent-filter><action android:name="android.appwidget.action.APPWIDGET_UPDATE" /></intent-filter>
            <meta-data android:name="android.appwidget.provider" android:resource="@xml/pt_widget_small_info" />
        </receiver>
        <receiver android:name=".PourToujoursMediumWidget" android:exported="true">
            <intent-filter><action android:name="android.appwidget.action.APPWIDGET_UPDATE" /></intent-filter>
            <meta-data android:name="android.appwidget.provider" android:resource="@xml/pt_widget_medium_info" />
        </receiver>
        <receiver android:name=".PourToujoursLargeWidget" android:exported="true">
            <intent-filter><action android:name="android.appwidget.action.APPWIDGET_UPDATE" /></intent-filter>
            <meta-data android:name="android.appwidget.provider" android:resource="@xml/pt_widget_large_info" />
        </receiver>
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" android:exported="false" />
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver" android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON" />
            </intent-filter>
        </receiver>
"""
    if ".PourToujoursSmallWidget" not in text:
        text = text.replace("</application>", native_components + "    </application>", 1)
    MANIFEST.write_text(text, encoding="utf-8")


def prepare_gradle() -> None:
    path = Path("android/app/build.gradle.kts")
    text = path.read_text(encoding="utf-8")
    if "isCoreLibraryDesugaringEnabled = true" not in text:
        text = text.replace(
            "compileOptions {",
            "compileOptions {\n        isCoreLibraryDesugaringEnabled = true",
            1,
        )
    if "multiDexEnabled = true" not in text:
        text = text.replace("defaultConfig {", "defaultConfig {\n        multiDexEnabled = true", 1)
    dependency = 'coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")'
    if dependency not in text:
        text += f"\n\ndependencies {{\n    {dependency}\n}}\n"
    path.write_text(text, encoding="utf-8")


def prepare_resources() -> None:
    drawable = ROOT / "res/drawable"
    layout = ROOT / "res/layout"
    xml = ROOT / "res/xml"
    kotlin = ROOT / "kotlin/com/pourtoujours/pour_toujours"
    for directory in (drawable, layout, xml, kotlin):
        directory.mkdir(parents=True, exist_ok=True)

    (drawable / "ic_pour_toujours.xml").write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#092E32" android:pathData="M54,8A46,46 0,1 0,54 100A46,46 0,1 0,54 8" />
    <path android:fillColor="#6DC0B5" android:pathData="M54,20A34,34 0,1 0,54 88A34,34 0,1 0,54 20" />
    <path android:fillColor="#0B3A43" android:pathData="M33,31L44,25L53,31L49,40L39,43L33,31M57,53L68,42L83,47L82,59L72,66L65,78L55,74L50,63L57,53M32,62L42,65L47,77L38,82L29,73L32,62" />
    <path android:fillColor="#00000000" android:strokeColor="#FFF7E6" android:strokeWidth="5" android:strokeLineCap="round" android:pathData="M12,60C31,78 76,79 96,48" />
    <path android:fillColor="#F2C15B" android:pathData="M82,18L85,25L92,28L85,31L82,38L79,31L72,28L79,25Z" />
</vector>
""",
        encoding="utf-8",
    )
    (drawable / "pt_widget_background.xml").write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <gradient android:angle="315" android:startColor="#071F23" android:centerColor="#0A3437" android:endColor="#123E45" />
    <corners android:radius="28dp" />
    <stroke android:width="1dp" android:color="#407D786A" />
</shape>
""",
        encoding="utf-8",
    )
    (drawable / "pt_widget_surface.xml").write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <solid android:color="#1FF7F1E5" />
    <corners android:radius="18dp" />
    <stroke android:width="1dp" android:color="#2875B8AE" />
</shape>
""",
        encoding="utf-8",
    )
    (drawable / "pt_widget_alert.xml").write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <solid android:color="#22F2C15B" />
    <corners android:radius="14dp" />
</shape>
""",
        encoding="utf-8",
    )

    (layout / "pt_widget_small.xml").write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:id="@+id/small_root" android:layout_width="match_parent" android:layout_height="match_parent" android:orientation="vertical" android:padding="15dp" android:background="@drawable/pt_widget_background">
    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content" android:gravity="center_vertical" android:orientation="horizontal">
        <ImageView android:layout_width="24dp" android:layout_height="24dp" android:src="@drawable/ic_pour_toujours" android:contentDescription="Pour Toujours" />
        <TextView android:layout_width="0dp" android:layout_height="wrap_content" android:layout_weight="1" android:layout_marginStart="8dp" android:text="POUR TOUJOURS" android:textColor="#AEE2D9" android:textSize="10sp" android:textStyle="bold" android:letterSpacing="0.10" />
    </LinearLayout>
    <TextView android:id="@+id/small_title" android:layout_width="match_parent" android:layout_height="wrap_content" android:layout_marginTop="9dp" android:maxLines="2" android:ellipsize="end" android:textColor="#FFF8EA" android:textSize="18sp" android:textStyle="bold" />
    <TextView android:id="@+id/small_body" android:layout_width="match_parent" android:layout_height="wrap_content" android:layout_marginTop="4dp" android:maxLines="2" android:ellipsize="end" android:textColor="#C9E2DD" android:textSize="12sp" />
    <TextView android:id="@+id/small_updated" android:layout_width="match_parent" android:layout_height="wrap_content" android:layout_marginTop="6dp" android:textColor="#83B7B0" android:textSize="9sp" />
</LinearLayout>
""",
        encoding="utf-8",
    )

    (layout / "pt_widget_medium.xml").write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:id="@+id/medium_root" android:layout_width="match_parent" android:layout_height="match_parent" android:orientation="vertical" android:padding="16dp" android:background="@drawable/pt_widget_background">
    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content" android:gravity="center_vertical" android:orientation="horizontal">
        <ImageView android:layout_width="28dp" android:layout_height="28dp" android:src="@drawable/ic_pour_toujours" android:contentDescription="Pour Toujours" />
        <TextView android:id="@+id/medium_title" android:layout_width="0dp" android:layout_height="wrap_content" android:layout_weight="1" android:layout_marginStart="10dp" android:maxLines="2" android:ellipsize="end" android:textColor="#FFF8EA" android:textSize="17sp" android:textStyle="bold" />
    </LinearLayout>
    <TextView android:id="@+id/medium_cities" android:layout_width="match_parent" android:layout_height="wrap_content" android:layout_marginTop="10dp" android:padding="11dp" android:background="@drawable/pt_widget_surface" android:maxLines="3" android:ellipsize="end" android:textColor="#E5F3EF" android:textSize="12sp" android:lineSpacingExtra="2dp" />
    <TextView android:id="@+id/medium_alert" android:layout_width="match_parent" android:layout_height="wrap_content" android:layout_marginTop="8dp" android:padding="8dp" android:background="@drawable/pt_widget_alert" android:maxLines="1" android:ellipsize="end" android:textColor="#FFE8AA" android:textSize="11sp" android:textStyle="bold" />
    <TextView android:id="@+id/medium_updated" android:layout_width="match_parent" android:layout_height="wrap_content" android:layout_marginTop="6dp" android:textColor="#83B7B0" android:textSize="9sp" />
</LinearLayout>
""",
        encoding="utf-8",
    )

    (layout / "pt_widget_large.xml").write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:id="@+id/large_root" android:layout_width="match_parent" android:layout_height="match_parent" android:orientation="vertical" android:padding="18dp" android:background="@drawable/pt_widget_background">
    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content" android:gravity="center_vertical" android:orientation="horizontal">
        <ImageView android:layout_width="30dp" android:layout_height="30dp" android:src="@drawable/ic_pour_toujours" android:contentDescription="Pour Toujours" />
        <LinearLayout android:layout_width="0dp" android:layout_height="wrap_content" android:layout_weight="1" android:layout_marginStart="11dp" android:orientation="vertical">
            <TextView android:text="FAMILY WORLD" android:layout_width="match_parent" android:layout_height="wrap_content" android:textColor="#AEE2D9" android:textSize="9sp" android:textStyle="bold" android:letterSpacing="0.12" />
            <TextView android:id="@+id/large_title" android:layout_width="match_parent" android:layout_height="wrap_content" android:maxLines="2" android:ellipsize="end" android:textColor="#FFF8EA" android:textSize="19sp" android:textStyle="bold" />
        </LinearLayout>
    </LinearLayout>
    <TextView android:id="@+id/large_timeline" android:layout_width="match_parent" android:layout_height="wrap_content" android:layout_marginTop="12dp" android:padding="12dp" android:background="@drawable/pt_widget_surface" android:maxLines="3" android:ellipsize="end" android:textColor="#E8F5F1" android:textSize="13sp" android:textStyle="bold" />
    <TextView android:id="@+id/large_event" android:layout_width="match_parent" android:layout_height="wrap_content" android:layout_marginTop="9dp" android:padding="11dp" android:background="@drawable/pt_widget_surface" android:maxLines="2" android:ellipsize="end" android:textColor="#D4E8E3" android:textSize="12sp" />
    <TextView android:id="@+id/large_alert" android:layout_width="match_parent" android:layout_height="wrap_content" android:layout_marginTop="9dp" android:padding="9dp" android:background="@drawable/pt_widget_alert" android:maxLines="2" android:ellipsize="end" android:textColor="#FFE8AA" android:textSize="11sp" android:textStyle="bold" />
    <TextView android:id="@+id/large_updated" android:layout_width="match_parent" android:layout_height="wrap_content" android:layout_marginTop="7dp" android:textColor="#83B7B0" android:textSize="9sp" />
</LinearLayout>
""",
        encoding="utf-8",
    )

    def info(layout_name: str, width: int, height: int) -> str:
        return f"""<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android" android:initialLayout="@layout/{layout_name}" android:previewLayout="@layout/{layout_name}" android:minWidth="{width}dp" android:minHeight="{height}dp" android:resizeMode="horizontal|vertical" android:updatePeriodMillis="1800000" android:widgetCategory="home_screen" />
"""

    (xml / "pt_widget_small_info.xml").write_text(info("pt_widget_small", 110, 80), encoding="utf-8")
    (xml / "pt_widget_medium_info.xml").write_text(info("pt_widget_medium", 250, 120), encoding="utf-8")
    (xml / "pt_widget_large_info.xml").write_text(info("pt_widget_large", 250, 240), encoding="utf-8")

    (kotlin / "PourToujoursWidgets.kt").write_text(
        """package com.pourtoujours.pour_toujours

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

abstract class PourToujoursWidgetProvider(
    private val layoutId: Int,
    private val rootId: Int,
    private val bindings: List<Pair<Int, String>>,
    private val updatedId: Int,
) : HomeWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray, data: SharedPreferences) {
        ids.forEach { id ->
            runCatching {
                val views = RemoteViews(context.packageName, layoutId)
                bindings.forEach { (view, key) -> views.setTextViewText(view, safeRead(data, key)) }
                val stale = runCatching { data.getString("pt_stale", "0") }.getOrNull() == "1"
                views.setTextViewText(updatedId, if (stale) "LAST KNOWN · OFFLINE" else "UPDATED WHEN APP WAS LAST OPEN")
                views.setOnClickPendingIntent(rootId, HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java))
                manager.updateAppWidget(id, views)
            }.onFailure { error ->
                Log.w("PourToujoursWidget", "Widget update skipped safely", error)
            }
        }
    }

    private fun safeRead(data: SharedPreferences, key: String): String {
        val value = runCatching { data.getString(key, null) }.getOrNull()?.trim().orEmpty()
        return if (value.isBlank()) fallback(key) else value.take(220)
    }

    private fun fallback(key: String): String = when (key) {
        "pt_primary" -> "Your family world"
        "pt_secondary" -> "Open Pour Toujours for the latest shared context"
        "pt_cities" -> "Karachi  •  Chiba  •  Dublin  •  Hattiesburg"
        "pt_timeline" -> "Open the app to refresh shared family time"
        "pt_next_event" -> "No upcoming saved event"
        "pt_alert" -> "No important alert cached"
        else -> ""
    }
}

class PourToujoursSmallWidget : PourToujoursWidgetProvider(
    R.layout.pt_widget_small,
    R.id.small_root,
    listOf(R.id.small_title to "pt_primary", R.id.small_body to "pt_secondary"),
    R.id.small_updated,
)

class PourToujoursMediumWidget : PourToujoursWidgetProvider(
    R.layout.pt_widget_medium,
    R.id.medium_root,
    listOf(R.id.medium_title to "pt_primary", R.id.medium_cities to "pt_cities", R.id.medium_alert to "pt_alert"),
    R.id.medium_updated,
)

class PourToujoursLargeWidget : PourToujoursWidgetProvider(
    R.layout.pt_widget_large,
    R.id.large_root,
    listOf(R.id.large_title to "pt_primary", R.id.large_timeline to "pt_timeline", R.id.large_event to "pt_next_event", R.id.large_alert to "pt_alert"),
    R.id.large_updated,
)
""",
        encoding="utf-8",
    )


if __name__ == "__main__":
    prepare_manifest()
    prepare_gradle()
    prepare_resources()
    print("Prepared polished, crash-safe Pour Toujours Android widgets.")
