#!/usr/bin/env sh

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch bar example
polybar -r top1 > /dev/null 2> ~/.config/polybar/top1-error.log &
polybar -r top2 > /dev/null 2> ~/.config/polybar/top2-error.log &

echo "Polybar launched"

