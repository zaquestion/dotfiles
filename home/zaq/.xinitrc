xset r rate 200 100
xrdb -merge ~/.Xresources
sleep 2 && chromium &
sleep 2 && slack &
sleep 2 && st -n mat -e tmux new-session -c /home/zaq/projects/go/src/gitlab.corp.tune.com/engineering/measurement &
sleep 2 && st -n leg -e tmux new-session -c /home/zaq/projects/php/tracking_engine &
sleep 2 && st -n qa -e tmux new-session -c /home/zaq/projects/python/tracking_qa &

xautolock -time 5 -locker slock &
$GOPATH/bin/gods &
exec dwm
