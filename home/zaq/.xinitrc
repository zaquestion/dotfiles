xset r rate 200 100
sleep 2 && google-chrome &
sleep 2 && slack &
sleep 2 && st -n lab -e tmux new-session -c /home/zaq/projects/go/src/github.com/zaquestion/lab &
sleep 2 && st -n labtest -e tmux new-session -c /home/zaq/projects/go/src/github.com/zaquestion/testdata/test &

xautolock -time 5 -locker slock &
$GOPATH/bin/gods &
xrandr --output eDP-1 --scale 0.5x0.5
exec dwm
