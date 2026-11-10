#!/usr/bin/env bash
set -eu
cd "$(dirname "$0")/../.."
root=mobile/branding
src=mobile/assets/brand/app-icon-master.png
# Isolate the bright mark from the generated dark background; the dark bowl cutout stays transparent.
convert "$src" -colorspace Gray -level 12%,25% -blur 0x0.3 /tmp/brand-mask.png
convert "$src" /tmp/brand-mask.png -alpha off -compose CopyOpacity -composite mobile/assets/brand/app-icon-foreground.png
fg=mobile/assets/brand/app-icon-foreground.png
for entry in mdpi:48 hdpi:72 xhdpi:96 xxhdpi:144 xxxhdpi:192; do
 d=${entry%:*}; n=${entry#*:}; mkdir -p "$root/android/mipmap-$d"
 convert "$fg" -background '#1A100B' -alpha remove -alpha off -resize "${n}x${n}" "$root/android/mipmap-$d/ic_launcher.png"
done
mkdir -p "$root/android/drawable-nodpi" "$root/android/mipmap-anydpi-v26" "$root/android/values" "$root/android/drawable" "$root/android/drawable-v21"
convert "$fg" -resize 432x432 "$root/android/drawable-nodpi/brand_foreground.png"
for entry in mdpi:288 hdpi:432 xhdpi:576 xxhdpi:864 xxxhdpi:1152; do
 d=${entry%:*}; n=${entry#*:}; mkdir -p "$root/android/drawable-$d"
 convert "$fg" -resize "${n}x${n}" "$root/android/drawable-$d/brand_splash.png"
done
cat > "$root/android/mipmap-anydpi-v26/ic_launcher.xml" <<'XML'
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/brand_background" />
    <foreground android:drawable="@drawable/brand_foreground" />
    <monochrome android:drawable="@drawable/brand_foreground" />
</adaptive-icon>
XML
cat > "$root/android/values/brand_colors.xml" <<'XML'
<resources><color name="brand_background">#1A100B</color></resources>
XML
for d in drawable drawable-v21; do
cat > "$root/android/$d/launch_background.xml" <<'XML'
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/brand_background" />
    <item><bitmap android:gravity="center" android:src="@drawable/brand_splash" /></item>
</layer-list>
XML
done
for d in values values-night values-v31 values-night-v31; do
mkdir -p "$root/android/$d"
cat > "$root/android/$d/styles.xml" <<'XML'
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:windowLightStatusBar">false</item>
        <item name="android:statusBarColor">@color/brand_background</item>
        <item name="android:navigationBarColor">@color/brand_background</item>
XML
case "$d" in *v31)
cat >> "$root/android/$d/styles.xml" <<'XML'
        <item name="android:windowSplashScreenBackground">@color/brand_background</item>
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/brand_splash</item>
        <item name="android:windowSplashScreenIconBackgroundColor">@color/brand_background</item>
XML
;; esac
cat >> "$root/android/$d/styles.xml" <<'XML'
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@color/brand_background</item>
    </style>
</resources>
XML
done
python - <<'PY'
import json,subprocess,pathlib
root=pathlib.Path('mobile/branding/ios/Assets.xcassets')
icons=root/'AppIcon.appiconset';icons.mkdir(parents=True,exist_ok=True)
images=[]
for idiom,sizes in [('iphone',[(20,[2,3]),(29,[1,2,3]),(40,[2,3]),(60,[2,3])]),('ipad',[(20,[1,2]),(29,[1,2]),(40,[1,2]),(76,[1,2]),(83.5,[2])]),('ios-marketing',[(1024,[1])])]:
 for size,scales in sizes:
  for scale in scales:
   filename=f'icon-{size}-{scale}.png'; pixels=round(size*scale)
   subprocess.run(['convert','mobile/assets/brand/app-icon-foreground.png','-background','#1A100B','-alpha','remove','-alpha','off','-resize',f'{pixels}x{pixels}',str(icons/filename)],check=True)
   images.append(dict(idiom=idiom,size=f'{size}x{size}',scale=f'{scale}x',filename=filename))
(icons/'Contents.json').write_text(json.dumps(dict(images=images,info=dict(version=1,author='BongoFoodie')),indent=2)+'\n')
launch=root/'LaunchImage.imageset';launch.mkdir(exist_ok=True)
images=[]
for scale in [1,2,3]:
 filename=f'launch-{scale}.png';n=288*scale
 subprocess.run(['convert','mobile/assets/brand/app-icon-foreground.png','-resize',f'{n}x{n}',str(launch/filename)],check=True)
 images.append(dict(idiom='universal',scale=f'{scale}x',filename=filename))
(launch/'Contents.json').write_text(json.dumps(dict(images=images,info=dict(version=1,author='BongoFoodie')),indent=2)+'\n')
PY
for n in 192 512; do
 convert "$fg" -background '#1A100B' -alpha remove -alpha off -resize "${n}x${n}" "mobile/web/icons/Icon-$n.png"
done
convert "$fg" -background '#1A100B' -alpha remove -alpha off -resize 180x180 mobile/web/icons/apple-touch-icon.png
convert "$fg" -background '#1A100B' -alpha remove -alpha off -resize 32x32 mobile/web/favicon.png
