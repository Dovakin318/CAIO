if [ -z $UF ]; then
  UF=$TMPDIR/common/unityfiles
  unzip -oq "$ZIPFILE" 'common/unityfiles/util_functions.sh' -d $TMPDIR >&2
  [ -f "$UF/util_functions.sh" ] || { ui_print "! Unable to extract zip file !"; exit 1; }
  . $UF/util_functions.sh
fi

comp_check
#MINAPI=21
#MAXAPI=25
#DYNLIB=true
#SYSOVER=true
DEBUG=true
#SKIPMOUNT=true

REPLACE_EXAMPLE="
/system/app/Youtube
/system/priv-app/SystemUI
/system/priv-app/Settings
/system/framework
"

REPLACE="
"
print_modname() {
  center_and_print
  ui_print "    *******************************************"
  ui_print "    *       Shoutout to TadiT7 @ github       *"
  ui_print "    *       for NUMEROUS Stock ROM dumps      *"
  ui_print "    *******************************************"
  ui_print " "
  unity_main
}

set_permissions() {
  $MAGISK && set_perm_recursive $UNITY 0 0 0755 0644
}

unity_custom() {
  # Device vars
  DEVNAME=$(grep_prop ro.product.model)
  DEVCODE=$(grep_prop ro.build.product)
  LANJUT=false
  GCAM=false
  
  # Supported devices
  case $DEVCODE in
   jasmine*) LANJUT=true;;
      tulip) LANJUT=true; GCAM=true;;
      wayne) LANJUT=true; GCAM=true;;
     whyred) LANJUT=true; GCAM=true;;
  esac
  
  # Correct MI with Mi 😂
  case $DEVNAME in
    MI*) DEVNAME=$(echo $DEVNAME | tr [I] [i]);;
  esac
  
  # Begin checking devices
  if $MAGISK || $LANJUT; then
      ui_print " "
      ui_print "- Your $DEVNAME ($DEVCODE) is supported"
      sed -i "s/SDM660/$DEVNAME/g" $TMPDIR/module.prop
  else
      abort "  ! Your $DEVNAME ($DEVCODE) is not supported"
  fi
}
