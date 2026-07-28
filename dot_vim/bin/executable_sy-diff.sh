#!/bin/sh
# vim-signify diff wrapper -- see g:signify_vcs_cmds in ~/.vimrc
#
#   usage: sy-diff.sh <git|hg> <file>
#
# Signify runs this with the buffer's directory as cwd. It only parses the
# "@@ -a,b +c,d @@" hunk headers out of stdout, and it reads the exit code as
# "is this the right VCS for this file": 0 means the diff is authoritative
# (an empty diff is a valid "no changes"), non-zero means "not this VCS, try
# the next one in g:signify_vcs_list".
#
# The one thing this adds over signify's stock commands: an untracked file
# produces no diff at all from git/hg, so it would get no signs. Here it is
# rendered as an all-added hunk instead, matching what coc-git used to show.

set -u

vcs=${1:-}
file=${2:-}

if [ -z "$vcs" ] || [ -z "$file" ]; then
    echo "usage: sy-diff.sh <git|hg> <file>" >&2
    exit 2
fi

# Emit an all-added unified diff (@@ -0,0 +1,N @@) for a file with no VCS base.
# Empty file => no output, which correctly yields no signs.
diff_against_nothing() {
    diff -U0 -- /dev/null "$1" 2>/dev/null
    # diff exits 1 when the files differ, which is the normal case here.
    [ $? -le 1 ]
}

case "$vcs" in
git)
    # Not a work tree (or no git) => let signify move on to the next VCS.
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 1

    if git ls-files --error-unmatch -- "$file" >/dev/null 2>&1; then
        # Tracked: signify's stock git command.
        git diff --no-color --no-ext-diff -U0 -- "$file"
        exit $?
    fi

    # Untracked. Ignored files stay unsigned; everything else reads as added.
    if git check-ignore -q -- "$file" 2>/dev/null; then
        exit 0
    fi
    [ -f "$file" ] || exit 0
    diff_against_nothing "$file" || exit 1
    exit 0
    ;;

hg)
    # Sapling (sl) drives fbsource-style working copies; fall back to hg.
    if command -v sl >/dev/null 2>&1; then
        hgbin=sl
    elif command -v hg >/dev/null 2>&1; then
        hgbin=hg
    else
        exit 1
    fi

    "$hgbin" root >/dev/null 2>&1 || exit 1

    # A leading '?' in status means untracked; 'I' means ignored.
    case $("$hgbin" status --unknown --ignored -- "$file" 2>/dev/null | cut -c1) in
    '?')
        [ -f "$file" ] || exit 0
        diff_against_nothing "$file" || exit 1
        exit 0
        ;;
    I)
        exit 0
        ;;
    esac

    "$hgbin" --config alias.diff=diff diff --color=never --nodates -U0 -- "$file"
    exit $?
    ;;

*)
    echo "sy-diff.sh: unknown vcs '$vcs'" >&2
    exit 2
    ;;
esac
