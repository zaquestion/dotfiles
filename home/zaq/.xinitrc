xset r rate 200 100
xrdb -merge ~/.Xresources
sleep 7 && google-chrome &
sleep 5 && slack &
sleep 5 && (source /home/zaq/env/consul && st -n devhost -e tmux new-session "ssh dp-zaq01-dev.sea1.office.priv" &)
sleep 5 && st -n mat -e tmux new-session -c /home/zaq/projects/go/src/gitlab.corp.tune.com/engineering/measurement &
sleep 5 && st -n leg -e tmux new-session -c /home/zaq/projects/php/tracking_engine &
sleep 5 && st -n qa -e tmux new-session -c /home/zaq/projects/python/tracking_qa &

$GOPATH/bin/gods &
exec dwm
