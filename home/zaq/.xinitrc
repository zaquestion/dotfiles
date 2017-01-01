xset r rate 200 100
xrdb -merge ~/.Xresources
$GOPATH/bin/gods &
exec dwm
