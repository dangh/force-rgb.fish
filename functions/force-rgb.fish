function force-rgb --description "Force RGB mode for monitor that defaults to YPbPr"
  set --function fixes 0
  set --function dryrun
  if not isatty stdin
    read --local answer
    if test "$answer" = y
      set --erase dryrun
    end
  end
  for plist in /Library/Preferences/com.apple.windowserver.displays.plist ~/Library/Preferences/ByHost/com.apple.windowserver.displays.*.plist
    set --local f1 (mktemp)
    set --local f2 (mktemp)
    set --local f3 (mktemp)
    cp $plist $f1
    plutil -convert json $f1
    jq --argjson LinkDescription '{"Range":1,"BitDepth":8,"EOTF":0,"PixelEncoding":0}' '(. | select(.DisplaySets != null) | .DisplaySets.Configs | .[] | if type=="array" then . else (select(.DisplayConfig != null) | .DisplayConfig) end | .[] | .LinkDescription) |= $LinkDescription' $f1 > $f2 2>/dev/null
    jq --argjson LinkDescription '{"Range":1,"BitDepth":8,"EOTF":0,"PixelEncoding":0}' '(. | select(.DisplayAnyUserSets != null) | .DisplayAnyUserSets.Configs | .[] | if type=="array" then . else (select(.DisplayConfig != null) | .DisplayConfig) end | .[] | .LinkDescription) |= $LinkDescription' $f2 > $f3 2>/dev/null
    echo '{}' | jq --argfile f1 $f1 --argfile f3 $f3 'if $f1 == $f3 then empty else null|halt_error(99) end'
    if not test $status -eq 0

      set_color yellow
      if set --query --function dryrun
        echo $plist need to be fixed
      else
        echo Fixing $plist
      end
      set_color normal

      set fixes (math $fixes + 1)

      if not set --query --function dryrun
        plutil -convert binary1 $f3
        if string match --entire --quiet "$HOME/*" $plist
          cp $plist $plist.bak
          chflags nouchg $plist
          cp $f3 $plist
          chflags uchg $plist
        else
          sudo cp $plist $plist.bak
          sudo chflags nouchg $plist
          sudo cp $f3 $plist
          sudo chflags uchg $plist
        end
      end
    end
  end

  set_color green
  if test $fixes -gt 0
    if set --query --function dryrun
      echo $fixes files need to be fixed.
    else
     echo $fixes files fixed. Log out BEFORE reboot your Mac to apply changes.
    end
  else
    echo Your Mac is already set.
  end
  set_color normal
end
