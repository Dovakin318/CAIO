# Variables
CUS=$TMPDIR/custom
DFO=$ORIGDIR/system/etc/device_features/"$DEVCODE".xml
DFM=$TMPDIR/$MODID/system/etc/device_features/"$DEVCODE".xml
ROM=$(grep_prop ro.build.display.id | cut -d'-' -f1)
SYSCAM=$(find $ORIGDIR/system/priv-app -type d -name "*MiuiCamera*" | head -n1)
PERMS=$TMPDIR/$MODID/system/etc/default-permissions/miuicamera-permissions.xml

# Description edit
DEDIT() {
  sed -ri "s/description=(.*)/description=\1 $1/" $TMPDIR/module.prop 2>/dev/null
}

# Install stuffs with ease
PUSHME() {
  OUT=$(find $TMPDIR/$1 -type f -name "*.*")
  for FILE in $OUT; do
     DEST=$CUS/$MODID/system/$2/$(basename $FILE)
     #[ ! -d $(dirname $DEST) ] && mkdir -p $(dirname $DEST)
     cp_ch -rf $FILE $DEST 2>/dev/null
  done
}

# Basic patches
BASIC() {
  ui_print " "
  ui_print "  Extracting $MODID base files..."
  unzip -oq $CUS/Base.zip -d $TMPDIR 2>/dev/null
  unzip -oq $CUS/device_features.zip -d $CUS 2>/dev/null
  if [ "$PROPFILE" == $CUS/aosplos.prop ]; then
    DEDIT "Applied: Google Camera stuffs, smoother video encoder, Pixel 2018 sysconfig, "
  else
    DEDIT "Applied: Google Camera stuffs, Pixel 2018 sysconfig, "
  fi
  
  ui_print " "
  ui_print "- Disable EIS? -"
  ui_print "  Vol+ (Yes)  /  Vol- (No)"
  ui_print " "
  if $VKSEL; then
    ui_print "  > EIS Disabled"
    EIS=true
  else
    ui_print "  > EIS Enabled"
    EIS=false
  fi
  
  ui_print " "
  ui_print "- Disable Gimmick AI (selfie, square and portrait)? -"
  ui_print "  Vol+ (Yes)  /  Vol- (No)"
  ui_print " "
  if $VKSEL; then
    ui_print "  > Gimmick AI disabled"
  else
    ui_print "  > Gimmick AI enabled"
    DEDIT "Gimmick AI,"
    sed -i '3 s/false/true/' $CUS/features.txt 2>/dev/null
    sed -i '5 s/false/true/' $CUS/features.txt 2>/dev/null
    sed -i '10 s/false/true/' $CUS/features.txt 2>/dev/null
  fi
}

ui_print " "
ui_print "- Detecting ROM -"
if [ -f /system/priv-app/MiuiSystemUI/MiuiSystemUI.apk ]; then
  ui_print " "
  ui_print "- $ROM is MIUI based -"
  ui_print "- AOSP/LOS patches will be skipped -"
  MIUI=true
else
  ui_print " "
  ui_print "- $ROM is AOSP/LOS based -"
  MIUI=false
fi

if $MIUI; then
  # Weird MemeUi Camera2API file placement
  sed -i "s/Mi 6X/$DEVNAME/g" $TMPDIR/custom/miui.prop
  sed -ri "s/name=(.*)/name=\1 for MIUI/" $TMPDIR/module.prop
  BASIC
  DEDIT "Seamless GCam 4K60 recording,"
  cp -f $DFO $DFM 2>/dev/null
  cp_ch -r $TMPDIR/$MODID$VEN/etc/permissions $UNITY$SYS/etc/permissions
  PROPFILE=$CUS/miui.prop
else
  sed -i "s/Mi 6X/$DEVNAME/g" $TMPDIR/custom/aosplos.prop
  sed -ri "s/name=(.*)/name=\1 for AOSP\/LOS/" $TMPDIR/module.prop
  PROPFILE=$CUS/aosplos.prop
  BASIC
  
  # Additional AOSP/LOS features
  ui_print " "
  ui_print "- Which MIUI Camera you want to install? -"
  ui_print "  Vol+ (Up)   =  MIUI Camera v2 from Part7"
  ui_print "  Vol- (Down) = Stock Mi A2 or Mi A1 MIUI Camera"
  if $VKSEL; then
    MICAM="Part7"
  else
    ui_print " "
    ui_print "  Vol+ (Mi A2)  /  Vol- (Mi A1)"
    if $VKSEL; then
      MICAM="MiA2"
    else
      MICAM="MiA1"
    fi
  fi
  ui_print " "
  ui_print "  > MIUI Camera from $MICAM selected -"
  
  ui_print " "
  ui_print "- Where to apply libraries ? -"
  ui_print "  Vol+ (Up)   = Priv-App only (Recommended)"
  ui_print "  Vol- (Down) = System-wide (Only if you have problem)"
  ui_print " "
  if $VKSEL; then
    ui_print "  > Selected priv-app only"
    LIBS=false
  else
    ui_print "  > Selected system-wide"
    LIBS=true
  fi
  
  if $GCAM; then
    ui_print " "
    ui_print "- Additional Google Camera patch available for your $DEVNAME -"
    ui_print "  Vol+ (Skip)  /  Vol- (Apply) "
    ui_print " "
    if $VKSEL; then
      ui_print "  > Skipped Ancient Family patches"
      GCAM=false
    else
      ui_print "  > Applied Ancient Family patches"
      GCAM=true
    fi
  else
    # in case aja
    GCAM=false
  fi
  # End of AOSP/LOS selection
  
  # Find system MIUI Camera
  # Some ROM uses different priv-app folder, this unf is the answer.
  if [ -d "$SYSCAM" ]; then
    case $BOOTMODE in
      true) SYSCAM=$(echo $SYSCAM | cut -d'/' -f7);;
      false) SYSCAM=$(echo $SYSCAM | cut -d'/' -f4);;
    esac
    ui_print " "
    ui_print "- $SYSCAM installed, replacing -"
    DEDIT "Replace MIUI Camera with $MICAM,"
    sed -i "s/true/false/g" $PERMS 2>/dev/null
    mktouch $UNITY$SYS/priv-app/"$SYSCAM"/.replace
  else
    DEDIT "Install MIUI Camera from $MICAM,"
    case $MICAM in
      Mi*) ui_print " ";
           ui_print "  [Note]: MANUALLY assign ($MICAM) MIUI Camera permission";
           sleep 3;;
    esac
  fi
  
  # AOSP Installations
  unzip -oq $CUS/AOSP.zip -d $TMPDIR 2>/dev/null
  unzip -oq $CUS/lib64.zip -d $TMPDIR 2>/dev/null
  
  # Ancient fam patches
  if $GCAM; then
    DEDIT "Ancient Family camera patches,"
    sed -ri "s/author=(.*)/author=\1, Ancient Family/" $TMPDIR/module.prop
    unzip -oq $CUS/Ancient.zip -d $TMPDIR/$MODID 2>/dev/null
  fi
  
  # Device specific patches
  if [ -f $CUS/"$DEVCODE".zip ]; then
    unzip -oq $CUS/"$DEVCODE".zip -d $TMPDIR/$MODID 2>/dev/null
  else
    case $DEVCODE in
     jasmine) unzip -oq $CUS/jasmine_sprout.zip -d $TMPDIR/$MODID 2>/dev/null;;
    esac
  fi

  # MIUI Camera and its libs installation
  # BERSIHIN
  cp_ch $CUS/"$MICAM".apk $UNITY$SYS/priv-app/MiuiCamera/MiuiCamera.apk
  if $LIBS; then
    PUSHME "lib64" "lib64"
    PUSHME "lib64" "priv-app/MiuiCamera/lib/arm64"
  else
    PUSHME "lib64" "priv-app/MiuiCamera/lib/arm64"
  fi
fi
  
# MIUI features patching
[ ! -f $DFM ] && abort "  ! $DEVCODE.xml not found !"
ui_print " "
ui_print "- Patching $DEVNAME MIUI features -"
while read -r NAME VAL; do 
# UnFaedah vars
OVAL=$(cat $DFM | grep -nw "$NAME" | cut -d'>' -f2 | cut -d'<' -f1 | head -n1)
ONUM=$(cat $DFM | grep -nw "$NAME" | cut -d':' -f1 | head -n1)
  case $OVAL in
    $VAL) continue;;
          #ui_print " Exist  : $NAME = [$VAL]";
  esac
  if [ -n "$OVAL" ]; then
    #ui_print " Changed: $NAME -- [$OVAL] => [$VAL]"
    sed -i "$ONUM s/$OVAL/$VAL/" $DFM
    sed -ri "$(($ONUM - 1)) s/<!--(.*)/<!-- $MODID changed \"$OVAL\" to \"$VAL\" -->/" $DFM
  else
    #ui_print " Added  : $NAME -- [$VAL]"
    sed -i "/<features>/ a\    <bool name=\"$NAME\">$VAL</bool>" $DFM
    sed -i "/<features>/ a\    <!-- $MODID added $NAME -->" $DFM
  fi
done <"$CUS/features.txt"

if $EIS; then
    DEDIT "Disable EIS,"
else
    DEDIT "Enable EIS,"
    sed -i "s/eis.enable=0/eis.enable=1/g" $CUS/aosplos.prop
    sed -i "s/eis.enable=0/eis.enable=1/g" $CUS/miui.prop
fi

# Version downgrade in case we need to change features
ui_print " "
ui_print "   Do you need to change $MODID options?"
ui_print "   Vol+ (No)  /  Vol- (Yes)"
ui_print " "
if $VKSEL; then
  ui_print "   **********************************************"
  ui_print "   *           [!!] IF BOOTLOOP [!!]            *"
  ui_print "   **********************************************"
  ui_print "   *         Please reflash this module         *"
  ui_print "   *            FROM RECOVERY/TWRP              *"
  ui_print "   **********************************************"
  sleep 5
else
  ui_print "   *  Now you can reflash this zip again and    *"
  ui_print "   *  change anything you need                  *"
  sed -ri "s/versionCode=(.*)/versionCode=100/" $TMPDIR/module.prop 2>/dev/null
fi

# Finale
if [ -d $TMPDIR/$MODID$SYS ] || [ -f $DFM ]; then
  ui_print " "
  ui_print "- Processing $MODID files "
  DEDIT "and patch $DEVCODE MIUI features."
  cp_ch -r $TMPDIR/$MODID$SYS $UNITY$SYS
  prop_process "$PROPFILE"
else
  unity_uninstall
  abort "! Failed to extract files"
fi
ui_print " "
