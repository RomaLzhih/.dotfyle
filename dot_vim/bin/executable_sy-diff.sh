#!/bin/sh
# vim-signify diff wrapper with untracked-file support.
#
# signify's default `git diff -- %f` / `hg diff -- %f` show nothing for a new
# (untracked) file, so no signs appear. coc-git marked such files as fully
# added; this restores that: for an untracked file we emit a diff against the
# empty tree so every line is an "added" sign.
#
# Exit status is a protocol, in two halves:
#
#   * Every DIFF-PRODUCING branch must exit 0 -- signify's check_diff_{git,hg}
#     discard the output when the command exits non-zero, and `git diff --no-index`
#     / `diff` exit 1 when files differ, so their status must not leak out.
#
#   * The "this is not my VCS" probes must exit NON-ZERO. signify drops a backend
#     only when its command fails: s:check_diff_hg returns [0,[]] on a non-zero exit
#     (autoload/sy/repo.vim:182-184) and s:handle_diff then logs "No valid diff found.
#     Disabling this VCS" (repo.vim:154-156); on a zero exit it APPENDS the vcs to
#     sy.vcs (repo.vim:150-151) and every later refresh loops over all of them
#     (autoload/sy.vim:67-75). These probes used to `exit 0`, so inside a pure git
#     tree the hg backend looked successful and got registered: b:sy.vcs was
#     ['hg','git'] on kernel/fork.c, and every CursorHold spawned sh+hg (~10ms) for
#     nothing. sy#sign#process_diff only trims sy.vcs to one winner once a diff
#     actually produces hunks (sy/sign.vim:189-199), which never happens on a clean
#     file, so a clean buffer kept both backends forever.
#
#     It also leaked signify's detection counter: repo.vim:9-10 increments
#     g:signify_detecting per vcs, but s:handle_diff only decrements in the
#     `empty(sy.vcs)` branch (repo.vim:137-140). With hg winning the race and
#     appending itself, git's callback saw a non-empty sy.vcs and never decremented --
#     measured g:signify_detecting == 1 after opening a single file. sy#start() bails
#     out at `if g:signify_detecting > 50` (sy.vim:13-16), so after ~51 buffers in a
#     session every sign would silently stop updating.
#     (Residual upstream bug: repo.vim:137-140 still leaks if two backends both
#     genuinely succeed for the same buffer, e.g. a git-backed Sapling checkout.)
#
# Args: $1 = vcs (git|hg), $2 = file (git: repo-relative basename in cwd=file dir;
# hg: absolute path). cwd is the file's directory.

vcs=$1
f=$2

case "$vcs" in
  git)
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 1
    out=$(git diff --no-color --no-ext-diff -U0 -- "$f" 2>/dev/null)
    if [ -n "$out" ]; then
      printf '%s\n' "$out"
      exit 0
    fi
    # No tracked diff. If the file is untracked, show the whole file as added.
    if ! git ls-files --error-unmatch -- "$f" >/dev/null 2>&1; then
      git diff --no-color --no-ext-diff -U0 --no-index -- /dev/null "$f" 2>/dev/null
    fi
    exit 0
    ;;
  hg)
    hg root >/dev/null 2>&1 || exit 1
    out=$(hg --config alias.diff=diff diff --color=never --nodates -U0 -- "$f" 2>/dev/null)
    if [ -n "$out" ]; then
      printf '%s\n' "$out"
      exit 0
    fi
    # Untracked in Sapling/hg (status '?') -> synthesize an all-added diff.
    if [ -n "$(hg status -nu -- "$f" 2>/dev/null)" ]; then
      diff -U0 /dev/null "$f" 2>/dev/null
    fi
    exit 0
    ;;
esac
exit 0
