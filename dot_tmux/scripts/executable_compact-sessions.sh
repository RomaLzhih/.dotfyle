#!/bin/sh
# Compact purely-numeric tmux session names down to 0, 1, 2, ... preserving
# their order, so killing a session closes the gap it leaves behind and a new
# session lands on the lowest free number.
#
# Sessions with non-numeric names are left alone and do not consume a number.
# Called from the session-created / session-closed hooks in ~/.tmux.conf.

# Rename by session id, not name: names shift underneath us as we go.
#
# Ascending order matters. Every target number is <= the session's current
# number, and whichever session held that target has already been renamed
# further down, so a rename never collides with a live name.
tmux list-sessions -F '#{session_id} #{session_name}' 2>/dev/null |
awk '{ id = $1; name = substr($0, index($0, " ") + 1)
       if (name ~ /^[0-9]+$/) print name, id }' |
sort -n |
{
    n=0
    while read -r name id; do
        [ "$name" = "$n" ] || tmux rename-session -t "$id" "$n"
        n=$((n + 1))
    done
}
