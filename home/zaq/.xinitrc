xset r rate 200 100
xrdb -merge ~/.Xresources
sleep 5 && google-chrome &
sleep 5 && slack &
$GOPATH/bin/gods &
exec dwm
