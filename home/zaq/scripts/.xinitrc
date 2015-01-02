xrandr --newmode "2160x1440_59.90"  262.75  2160 2320 2552 2944  1440 1441 1444 1490  -HSync +Vsync
xrandr --addmode Virtual1 2160x1440_59.90
xrandr --output Virtual1 --mode 2160x1440_59.90
exec i3
