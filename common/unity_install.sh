# Variables
CUS=$TMPDIR/custom
CAIOSYS=$TMPDIR/$MODID/system
DFO=$ORIGDIR/system/etc/device_features/"$DEVCODE".xml
DFM=$TMPDIR/$MODID/system/etc/device_features/"$DEVCODE".xml
ROM=$(grep_prop ro.build.display.id | cut -d'-' -f1)
SYSCAM=$(find $ORIGDIR/system/priv-app -type d -name "*MiuiCamera*" | head -n1)
PERMS=$CAIOSYS/etc/default-permissions/miuicamera-permissions.xml

# Description edit
DEDIT() {
  sed -ri "s/description=(.*)/description=\1 $1/" $TMPDIR/module.prop 2>/dev/null
}

# Basic patches
BASIC() {
  ui_print " "
  ui_print "  Extracting $MODID base files..."
  unzip -oq $CUS/Base.zip -d $TMPDIR 2>/dev/null
  DEDIT "Applied Google Camera compatibilty, Lens, Photos unlimited backup,"
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
  sed -ri "s/name=(.*)/name=\1 for MIUI/" $TMPDIR/module.prop
  PROPFILE=$CUS/MIUI.prop
  # Copy device xml from magisk mirror
  cp -f $DFO $DFM 2>/dev/null 
  BASIC
else
  sed -ri "s/name=(.*)/name=\1 for AOSP\/LOS/" $TMPDIR/module.prop
  PROPFILE=$CUS/AOSP.prop
  BASIC
  
  # Additional AOSP/LOS features
  ui_print " "
  ui_print "- Which MIUI Camera you want to install? -"
  ui_print "  Vol+ (Up)   = MIUI Camera v2 from AI Part7"
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
  
  if $GCAM; then
    ui_print " "
    ui_print "- Apply 4k60-ish Google Camera video recording? -"
    ui_print "  Vol+ (Skip)  /  Vol- (Apply) "
    ui_print " "
    if $VKSEL; then
      ui_print "  > Skipped Additional Google Camera patches"
      GCAM=false
    else
      ui_print "  > Applied Additional Google Camera patches"
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
    mktouch $CAIOSYS/priv-app/"$SYSCAM"/.replace
  else
    case $MICAM in
      Mi*) ui_print " ";
           ui_print "  [Note]: MANUALLY assign ($MICAM) MIUI Camera permission";
           sleep 3;;
    esac
    DEDIT "Install MIUI Camera from $MICAM,"
  fi
  
  # AOSP Installations
  unzip -oq $CUS/AOSP.zip -d $TMPDIR 2>/dev/null
  case $DEVCODE in
     jasmine*) unzip -oq $CUS/jasmine_sprout.zip -d $TMPDIR/$MODID 2>/dev/null;;
  esac
  unzip -oq $CUS/"$DEVCODE".zip -d $TMPDIR/$MODID 2>/dev/null
  
  # Additional Google Camera patches
  if $GCAM; then
    DEDIT "4k60-ish video recording,"
    unzip -oq $CUS/GCam.zip -d $TMPDIR/$MODID 2>/dev/null
  fi

  # Install MIUI Camera
  # Lib64 has been moved to priv-app due to system stability 
  cp -f $CUS/$MICAM.apk $CAIOSYS/priv-app/MiuiCamera/MiuiCamera.apk 2>/dev/null
fi
  
# MIUI features patching
[ ! -f $DFM ] && abort "  ! $DEVCODE.xml not found !"

ui_print " "
ui_print "- Patching $DEVNAME MIUI features -"
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
    sed -i "/<features>/ a\    <!-- $MODID added $NAME -->" $DFM
    sed -i "/<features>/ a\    <bool name=\"$NAME\">$VAL</bool>" $DFM
  fi
done <"$CUS/features.txt"

if $EIS; then
    DEDIT "Disable EIS,"
else
    DEDIT "Enable EIS,"
    sed -i "s/eis.enable=0/eis.enable=1/g" $PROPFILE
fi

# Version downgrade in case we need to change features
ui_print " "
ui_print "   Do you need to change $MODID options?"
ui_print "   Vol+ (No)  /  Vol- (Yes)"
ui_print " "
if $VKSEL; then
  # Finale
  if [ -d $CAIOSYS ] || [ -f $DFM ]; then
    ui_print " "
    ui_print "- Processing $MODID files "
    DEDIT "and patch $DEVCODE.xml"
    $MIUI && cp_ch -r $CAIOSYS/vendor/etc/permissions $UNITY/system/etc/permissions
    cp_ch -r "$CAIOSYS" "$UNITY$SYS"
    prop_process "$PROPFILE"
  else
    rm -v $UNITY 2>/dev/null
    abort "! Failed to extract files"
  fi
  ui_print " "
  ui_print "   **********************************************"
  ui_print "   *           [!!] IF BOOTLOOP [!!]            *"
  ui_print "   **********************************************"
  ui_print "   *         Please reflash this module         *"
  ui_print "   *            FROM RECOVERY/TWRP              *"
  ui_print "   **********************************************"
  sleep 5
else
  ui_print " "
  ui_print "   **********************************************"
  ui_print "   *  Now you can reflash this zip again and    *"
  ui_print "   *  change anything you need                  *"
  ui_print "   **********************************************"
  sed -ri "s/versionCode=(.*)/versionCode=100/" $TMPDIR/module.prop 2>/dev/null
  sed -ri "s/description=(.*)/description=You may reflash this zip module again/" $TMPDIR/module.prop 2>/dev/null
  #unity_uninstall
  #rm -v $UNITY 2>dev/null
fi
ui_print " "
