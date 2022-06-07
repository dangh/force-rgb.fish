function force-rgb --description "Force RGB mode for monitor that defaults to YPbPr"
  for plist in /Library/Preferences/com.apple.windowserver.displays.plist ~/Library/Preferences/ByHost/com.apple.windowserver.displays.*.plist
    set_color yellow; echo Fixing $plist; set_color normal;
    set --local tmp1 (mktemp)
    set --local tmp2 (mktemp)
    cp $plist $tmp1
    plutil -convert json $tmp1
    jq --argjson LinkDescription '{"Range":1,"BitDepth":8,"EOTF":0,"PixelEncoding":0}' '(. | select(.DisplaySets != null) | .DisplaySets.Configs[] | .[] | .LinkDescription) |= $LinkDescription' $tmp1 > $tmp2 2>/dev/null
    jq --argjson LinkDescription '{"Range":1,"BitDepth":8,"EOTF":0,"PixelEncoding":0}' '(. | select(.DisplayAnyUserSets != null) | .DisplayAnyUserSets.Configs[] | .[] | .LinkDescription) |= $LinkDescription' $tmp2 > $tmp1 2>/dev/null
    plutil -convert binary1 $tmp1
    sudo cp $tmp1 $plist
  end
  set_color red; echo Done. Reboot your mac to apply changes.; set_color normal;
end
