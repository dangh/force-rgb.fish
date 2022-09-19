function force-rgb -d "Force RGB mode for monitor that defaults to YPbPr"
  set -f fixes 0
  set -f dryrun
  if not isatty stdin
    read -l answer
    if test "$answer" = y
      set -e dryrun
    end
  end
  for plist in /Library/Preferences/com.apple.windowserver.displays.plist ~/Library/Preferences/ByHost/com.apple.windowserver.displays.*.plist
    set -l original (mktemp)
    set -l patched (mktemp)
    cp $plist $original
    plutil -convert json $original
    jq --argjson LinkDescription '{"Range":1,"BitDepth":8,"EOTF":0,"PixelEncoding":0}' '( .. | select(.CurrentInfo?) | .LinkDescription ) |= $LinkDescription' $original > $patched 2>/dev/null
    echo 'null' | jq --argfile original $original --argfile patched $patched 'if $original != $patched then halt_error(99) else empty end'
    if not test $status -eq 0

      set_color yellow
      if set -q -f dryrun
        echo $plist need to be fixed
        diff --side-by-side (jq '.' $original | psub) $patched
      else
        echo Fixing $plist
      end
      set_color normal

      set fixes (math $fixes + 1)

      if not set -q -f dryrun
        plutil -convert binary1 $patched
        if string match -e -q "$HOME/*" $plist
          cp $plist $plist.bak
          chflags nouchg $plist
          cp $patched $plist
          chflags uchg $plist
        else
          sudo cp $plist $plist.bak
          sudo chflags nouchg $plist
          sudo cp $patched $plist
          sudo chflags uchg $plist
        end
      end
    end
  end

  set_color green
  if test $fixes -gt 0
    if set -q -f dryrun
      echo $fixes files need to be fixed.
    else
     echo $fixes files fixed. Log out BEFORE reboot your Mac to apply changes.
    end
  else
    echo Your Mac is already set.
  end
  set_color normal
end
