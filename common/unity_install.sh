# Variables
TMPSYS=$TMPDIR/system
CUS=$TMPDIR/custom
DFO=$ORIGDIR/system/etc/device_features/"$DEVCODE".xml
DFM=$TMPSYS/etc/device_features/"$DEVCODE".xml
ROM=$(grep_prop ro.build.display.id | cut -d'-' -f1)

# Description edit
DEDIT() {
  sed -ri "s/description=(.*)/description=\1 $1/" $TMPDIR/module.prop 2>/dev/null
}

ui_print " "
ui_print "- Detecting ROM -"
if [ -f /system/priv-app/MiuiSystemUI/MiuiSystemUI.apk ]; then
  ui_print " "
  ui_print "- $ROM is MIUI based -"
  ui_print "- AOSP/LOS patches will be skipped -"
  PROPFILE=$CUS/MIUI.prop
  MIUI=true
else
  ui_print " "
  ui_print "- $ROM is AOSP/LOS based -"
  PROPFILE=$CUS/AOSP.prop
  MIUI=false
fi

# Basic patches
ui_print " "
ui_print "  Extracting $MODID base files..."
unzip -oq $CUS/Base.zip -d $TMPDIR 2>/dev/null
DEDIT "Apply Camera2 API, Google Lens,"

ui_print " "
ui_print "- Disable EIS? -"
ui_print "  [Vol+] = Yes "
ui_print "  [Vol-] = No"
ui_print " "
if $VKSEL; then
  ui_print "  > EIS Disabled"
  DEDIT "Disable EIS,"
else
  ui_print "  > EIS Enabled"
  DEDIT "Enable EIS,"
  sed -i "s/eis.enable=0/eis.enable=1/g" $PROPFILE
fi

ui_print " "
ui_print "- Enable Gimmick AI (selfie, square and portrait)? -"
ui_print "  [Vol+] = Yes "
ui_print "  [Vol-] = No"
ui_print " "
if $VKSEL; then
  ui_print "  > Gimmick AI enabled"
  DEDIT "Gimmick AI,"
  sed -i '3 s/false/true/' $CUS/features.txt 2>/dev/null
  sed -i '5 s/false/true/' $CUS/features.txt 2>/dev/null
  sed -i '10 s/false/true/' $CUS/features.txt 2>/dev/null
else
  ui_print "  > Gimmick AI disabled"
fi

ui_print " "
ui_print "- PS: Google Photos may reads your $DEVNAME"
ui_print "      as Pixel 3XL, but all backed up photos "
ui_print "      are STILL COMPRESSED"
sleep 3
ui_print " "
ui_print "- Apply Pixel 3XL sysconfig? -"
ui_print "  [Vol+] = Yes "
ui_print "  [Vol-] = No"
ui_print " "
if $VKSEL; then
  ui_print "  > Google Photos unlimited backups applied"
  DEDIT "Google Photos unlimited backups,"
else
  ui_print "  > Google Photos unlimited backups removed"
  for xml in $(find $TMPSYS/etc/sysconfig -type f -name "google*.xml" -o -name "pixel*.xml" -o -name "nexus*.xml"); do
    rm -f $xml >/dev/null
  done
fi

if $MIUI; then
  sed -ri "s/name=(.*)/name=\1 for MIUI/" $TMPDIR/module.prop
  cp -rf -r $TMPSYS/vendor/etc/permissions $UNITY/system/etc/permissions >/dev/null
  # Use original device xml from MIUI
  cp -f $DFO $DFM 2>/dev/null
else
  sed -ri "s/name=(.*)/name=\1 for AOSP\/LOS/" $TMPDIR/module.prop
  # Additional AOSP/LOS features
  ui_print " "
  ui_print "- Which MIUI Camera you want to install? -"
  ui_print "  [Vol+] = Stock Mi A2"
  ui_print "  [Vol-] = AI Part 7 or AI Part 8"
  if $VKSEL; then
    MICAM="MiA2"
    NAMEMC="Stock Mi A2"
  else
    ui_print " "
    ui_print "  [Vol+] = AI Part 7"
    ui_print "  [Vol-] = AI Part 8"
    if $VKSEL; then
      MICAM="AIpart7"
      NAMEMC="AI Part 7"
    else
      MICAM="AIpart8"
      NAMEMC="AI Part 8"
    fi
  fi
  ui_print " "
  ui_print "  > MIUI Camera from $NAMEMC selected -"
  
  if $GCAM; then
    ui_print " "
    ui_print "- PS: GCam 4k60 recording will break"
    ui_print "      Miui Camera manual mode"
    sleep 3
    ui_print " "
    ui_print "- Apply 4k60-ish Google Camera video recording? -"
    ui_print "  [Vol+] = Yes"
    ui_print "  [Vol-] = No"
    ui_print " "
    if $VKSEL; then
      ui_print "  > Additional Google Camera patch applied"
      DEDIT "GCam 4k60-ish video recording,"  
      unzip -oq $CUS/GCam.zip -d $TMPSYS 2>/dev/null
    else
      ui_print "  > Additional Google Camera patch not applied"
    fi
  fi
    
  # Find system MIUI Camera
  # Some ROM may use different priv-app folder name for Miui Camera.
  SYSCAM=$(find $ORIGDIR/system/priv-app -type d -name "*MiuiCamera*" | head -n1)
  if [ -d "$SYSCAM" ]; then
    if $BOOTMODE; then
      SYSCAM=$(echo $SYSCAM | cut -d'/' -f7)
    else
      SYSCAM=$(echo $SYSCAM | cut -d'/' -f4)
    fi
    ui_print " "
    ui_print "  $SYSCAM installed, replacing..."
    DEDIT "Replace MIUI Camera with $NAMEMC,"
    mkdir -p $TMPSYS/priv-app/$SYSCAM >/dev/null
    touch $TMPSYS/priv-app/$SYSCAM/.replace >/dev/null
  else
    case $MICAM in
      Mi*) ui_print " ";
           ui_print "  [Note]: Please manually assign permissions MIUI Camera ($NAMEMC)";
           sleep 3;;
    esac
    DEDIT  "Install MIUI Camera from $NAMEMC,"
  fi
  
  # AOSP Installations
  ui_print " "
  ui_print "  Extracting AOSP/LOS and $DEVCODE files..."
  unzip -oq $CUS/AOSP.zip -d $TMPSYS 2>/dev/null
  case $DEVCODE in
    jasmine) unzip -oq $CUS/jasmine_sprout.zip -d $TMPSYS 2>/dev/null;;
  esac
  unzip -oq $CUS/"$DEVCODE".zip -d $TMPSYS 2>/dev/null
  
  # Install selected MIUI Camera
  cp -f $CUS/"$MICAM".apk $TMPSYS/priv-app/MemeCamera/MemeCamera.apk >/dev/null
  # End of AOSP/LOS
fi

# Whyred Camera blobs mixups
if [ $DEVCODE == "whyred" ]; then
  ui_print " "
  ui_print "- Apply Camera blobs mix-ups from AI Part 8.2.4? -"
  ui_print "  [Vol+] = Yes"
  ui_print "  [Vol-] = No"
  ui_print " "
  if [ -f $TMPSYS/vendor/etc/camera/camera_config.xml ]; then
    for wr in $(find $TMMPSYS/vendor -type f -name "*chromatix*" -o -name "libmmcamera_whyred*"); do
      rm -f $wr
    done
    rm -f $TMPSYS/vendor/lib/libmmcamera_sunny_ov13855_eeprom.so
    rm -f $TMPSYS/vendor/etc/camera/camera_config.xml
  fi
  if $VKSEL; then
    ui_print "  > AI Part 8.2.4 blobs applied"
    if $MIUI; then
      unzip -oq $CUS/whyred.zip -x "etc/device_features/whyred.xml" -d $TMPSYS 2>/dev/null
    else    
      unzip -oq $CUS/whyred.zip -d $TMPSYS 2>/dev/null
    fi
  else   
    ui_print "  > AI Part 8.2.4 blobs not applied"
  fi
  sed -i "s/is_mode=5/is_mode=4/g" $PROPFILE
  sed -i "s/is_type=5/is_type=4/g" $PROPFILE
  sed -i "s/stats.test=0/stats.test=5/g" $PROPFILE
fi

# xml file check
[ ! -f $DFM ] && abort "  ! $DEVCODE.xml not found !"

ui_print " "
ui_print "  Patching $DEVCODE.xml ..."
while read -r NAME VAL; do 
# UnFaedah vars
local OVAL=$(cat $DFM | grep -nw "$NAME" | cut -d'>' -f2 | cut -d'<' -f1 | head -n1)
local ONUM=$(cat $DFM | grep -nw "$NAME" | cut -d':' -f1 | head -n1)
  case $OVAL in
    $VAL) continue;;
  esac
  if [ -n "$OVAL" ]; then
    sed -i "$ONUM s/$OVAL/$VAL/" $DFM
  else
    sed -i "/<features>/ a\    <bool name=\"$NAME\">$VAL</bool>" $DFM
  fi
done <"$CUS/features.txt"
sed -i "/<!--/d" $DFM
sed -i "/<features>/ a\    <!-- Modified by $MODID -->" $DFM
# In case we need to change stuffs
ui_print " "
ui_print "  Do you finish setting up $MODID ?"
ui_print "  [Vol+] = Yes, I will reboot my $DEVNAME"
ui_print "  [Vol-] = No, I will change something"
ui_print " "
if $VKSEL; then
  DEDIT "and patch $DEVCODE.xml"
  prop_process $PROPFILE
  ui_print "  *********************************************"
  ui_print "  *            [!! IF BOOTLOOP !!]            *"
  ui_print "  *         Reflash/Install CAIO zip          *"
  ui_print "  *              from recovery/               *"
  ui_print "  *********************************************"
  sleep 5
else
  ui_print "  *********************************************"
  ui_print "  *        [!! DO NOT REBOOT YET !!]          *"
  ui_print "  *    Reflash/Install CAIO zip to change     *"
  ui_print "  *           anything you need               *"
  ui_print "  *********************************************"
  sleep 5
  sed -ri "s/versionCode=(.*)/versionCode=1/" $TMPDIR/module.prop
  sed -ri "s/description=(.*)/description=Please reflash\/Install CAIO zip again/" $TMPDIR/module.prop
  # Delete installer files
  rm -rf $TMPSYS 2>/dev/null
fi
ui_print " "
