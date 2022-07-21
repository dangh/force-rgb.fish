function force-rgb --description "Force RGB mode for monitor that defaults to YPbPr"
  set --local fixed 0
  argparse 'dryrun' -- $argv
  for plist in /Library/Preferences/com.apple.windowserver.displays.plist ~/Library/Preferences/ByHost/com.apple.windowserver.displays.*.plist
    set --local f1 (mktemp)
    set --local f2 (mktemp)
    set --local f3 (mktemp)
    cp $plist $f1
    plutil -convert json $f1
    jq --argjson LinkDescription '{"Range":1,"BitDepth":8,"EOTF":0,"PixelEncoding":0}' '(. | select(.DisplaySets != null) | .DisplaySets.Configs[] | .[] | .LinkDescription) |= $LinkDescription' $f1 > $f2 2>/dev/null
    jq --argjson LinkDescription '{"Range":1,"BitDepth":8,"EOTF":0,"PixelEncoding":0}' '(. | select(.DisplayAnyUserSets != null) | .DisplayAnyUserSets.Configs[] | .[] | .LinkDescription) |= $LinkDescription' $f2 > $f3 2>/dev/null
    echo '{}' | jq --argfile f1 $f1 --argfile f3 $f3 'if $f1 == $f3 then empty else null|halt_error(99) end'
    if not test $status -eq 0
      set_color yellow; echo Fixing $plist; set_color normal;
      set fixed (math $fixed + 1)
      if not set --query _flag_dryrun
        plutil -convert binary1 $f3
        if string match --entire --quiet "$HOME/*" $plist
          cp $f3 $plist
        else
          sudo cp $f3 $plist
        end
      end
    end
  end
  if test $fixed -gt 0
    set_color green; echo Done. Reboot your mac to apply changes.; set_color normal;
  end
end
