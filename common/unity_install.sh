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
DEDIT "Apply Camera2 API, Google Lens, Google Photos unlimited backup,"

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
    ui_print "  $SYSCAM installed, replacing.."
    DEDIT "Replace MIUI Camera with $NAMEMC,"
    mktouch $TMPSYS/priv-app/"$SYSCAM"/.replace
    # Basically whenever ROM has MiuiCamera, it will have false values here
    sed -i "s/true/false/g" $TMPSYS/etc/default-permissions/miuicamera-permissions.xml
  else
    case $MICAM in
      Mi*) ui_print " ";
           ui_print "  [Note]: Please manually assign permissions MIUI Camera ($NAMEMC)";
           sleep 3;;
    esac
    DEDIT  "Install MIUI Camera from $NAMEMC,"
  fi
  
  ui_print " "
  ui_print "  Cleaning up old Miui Camera data.."
  for b in $(find /data -name "*MiuiCamera*" -o -name "*com.android.camera*"); do
    case $b in
      /data/media/0*) continue;; # Internal storage
      /data/adb/modules*) continue;; # Magisk modules
    esac
    if [ -d "$b" ]; then
      rm -rf $b 2>/dev/null
    else
      rm -f $b 2>/dev/null
    fi
  done
  
  # AOSP Installations
  ui_print " "
  ui_print "  Extracting AOSP/LOS files..."
  unzip -oq $CUS/AOSP.zip -d $TMPSYS 2>/dev/null
  case $DEVCODE in
   jasmine*) unzip -oq $CUS/jasmine_sprout.zip -d $TMPSYS 2>/dev/null;;
  esac
  unzip -oq $CUS/"$DEVCODE".zip -d $TMPSYS 2>/dev/null
  
  # Install selected MIUI Camera
  cp -f $CUS/"$MICAM".apk $TMPSYS/priv-app/MiuiCamera/MiuiCamera.apk >/dev/null
  # End of AOSP/LOS
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
    $VAL) continue;; #ui_print " Exist  : $NAME = [$VAL]"; 
  esac
  if [ -n "$OVAL" ]; then
    #ui_print " Changed: $NAME -- [$OVAL] => [$VAL]"
    sed -i "$ONUM s/$OVAL/$VAL/" $DFM
    sed -ri "$(($ONUM - 1)) s/<!--(.*)/<!-- $MODID changed \"$OVAL\" to \"$VAL\" -->/" $DFM
  else
    #ui_print " Added  : $NAME -- [$VAL]"
    sed -i "/<features>/ a\    <!-- $MODID -->" $DFM
    sed -i "/<features>/ a\    <bool name=\"$NAME\">$VAL</bool>" $DFM
  fi
done <"$CUS/features.txt"

# In case we need to change stuffs
ui_print " "
ui_print "  Do you finish setting up $MODID ?"
ui_print "  [Vol+] = Yes, I will reboot my $DEVNAME"
ui_print "  [Vol-] = No, I will change something"
ui_print " "
if $VKSEL; then
  DEDIT "and patch $DEVCODE.xml"
  prop_process $PROPFILE
  ui_print " ***********************************************"
  ui_print " *            [!! IF BOOTLOOP !!]              *"
  ui_print " * Reflash/Install CAIO zip from recovery/TWRP *"
  ui_print " ***********************************************"
  sleep 5
else
  sed -ri "s/versionCode=(.*)/versionCode=1/" $TMPDIR/module.prop
  sed -ri "s/description=(.*)/description=Please reflash\/Install CAIO zip again/" $TMPDIR/module.prop
  # Delete tmp files
  rm -rf $TMPSYS 2>/dev/null
  ui_print " **********************************************"
  ui_print " *         [!! DO NOT REBOOT YET !!]          *"
  ui_print " *  Reflash/Install CAIO zip again to change  *"
  ui_print " *  anything you need                         *"
  ui_print " **********************************************"
  sleep 5
fi
ui_print " "
