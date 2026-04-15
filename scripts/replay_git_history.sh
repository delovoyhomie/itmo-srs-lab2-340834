#!/bin/zsh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${TMPDIR:-/tmp}/itmo-srs-lab2-replay"
REPO_DIR="$BUILD_DIR/repo"

RED_NAME="${RED_NAME:-user1}"
RED_EMAIL="${RED_EMAIL:-user1@example.com}"
BLUE_NAME="${BLUE_NAME:-user2}"
BLUE_EMAIL="${BLUE_EMAIL:-user2@example.com}"

TIMESTAMPS=(
  '2026-04-10T10:12:00+0300'
  '2026-04-10T10:19:00+0300'
  '2026-04-10T10:27:00+0300'
  '2026-04-10T10:34:00+0300'
  '2026-04-10T10:42:00+0300'
  '2026-04-10T10:51:00+0300'
  '2026-04-10T10:58:00+0300'
  '2026-04-10T11:06:00+0300'
  '2026-04-10T11:13:00+0300'
  '2026-04-10T11:21:00+0300'
  '2026-04-10T11:30:00+0300'
  '2026-04-10T11:39:00+0300'
  '2026-04-10T11:47:00+0300'
  '2026-04-10T11:56:00+0300'
  '2026-04-10T12:05:00+0300'
  '2026-04-10T12:13:00+0300'
  '2026-04-10T12:22:00+0300'
  '2026-04-10T12:31:00+0300'
  '2026-04-10T12:40:00+0300'
  '2026-04-10T12:48:00+0300'
  '2026-04-10T12:57:00+0300'
  '2026-04-10T13:06:00+0300'
  '2026-04-10T13:15:00+0300'
  '2026-04-10T13:24:00+0300'
  '2026-04-10T13:32:00+0300'
  '2026-04-10T13:41:00+0300'
  '2026-04-10T13:49:00+0300'
  '2026-04-10T13:58:00+0300'
  '2026-04-10T14:07:00+0300'
  '2026-04-10T14:16:00+0300'
  '2026-04-10T14:25:00+0300'
  '2026-04-10T14:34:00+0300'
  '2026-04-10T14:43:00+0300'
  '2026-04-10T14:52:00+0300'
  '2026-04-10T15:01:00+0300'
)

timestamp_for_rev() {
  local rev="$1"
  echo "${TIMESTAMPS[$((rev + 1))]}"
}

sync_snapshot() {
  local rev="$1"
  rsync -a --checksum --delete --exclude '.git' "$ROOT/commit${rev}/" "$REPO_DIR"/
}

commit_rev() {
  local rev="$1"
  local branch="$2"
  local user="$3"
  local email="$4"
  local message="$5"
  local ts
  ts="$(timestamp_for_rev "$rev")"

  git -C "$REPO_DIR" switch "$branch" >/dev/null
  sync_snapshot "$rev"
  git -C "$REPO_DIR" add -A
  GIT_AUTHOR_NAME="$user" \
  GIT_AUTHOR_EMAIL="$email" \
  GIT_COMMITTER_NAME="$user" \
  GIT_COMMITTER_EMAIL="$email" \
  GIT_AUTHOR_DATE="$ts" \
  GIT_COMMITTER_DATE="$ts" \
  git -C "$REPO_DIR" commit --allow-empty -m "r${rev}: ${message}" >/dev/null
  git -C "$REPO_DIR" tag -f "r${rev}" >/dev/null
}

merge_rev() {
  local rev="$1"
  local target="$2"
  local source="$3"
  local user="$4"
  local email="$5"
  local message="$6"
  local ts
  ts="$(timestamp_for_rev "$rev")"

  git -C "$REPO_DIR" switch "$target" >/dev/null
  if ! git -C "$REPO_DIR" merge --no-ff --no-commit "$source" >/dev/null 2>&1; then
    true
  fi
  sync_snapshot "$rev"
  git -C "$REPO_DIR" add -A
  GIT_AUTHOR_NAME="$user" \
  GIT_AUTHOR_EMAIL="$email" \
  GIT_COMMITTER_NAME="$user" \
  GIT_COMMITTER_EMAIL="$email" \
  GIT_AUTHOR_DATE="$ts" \
  GIT_COMMITTER_DATE="$ts" \
  git -C "$REPO_DIR" commit --allow-empty -m "r${rev}: ${message}" >/dev/null
  git -C "$REPO_DIR" tag -f "r${rev}" >/dev/null
}

mkdir -p "$BUILD_DIR"
rm -rf "$REPO_DIR"
git init -b main "$REPO_DIR" >/dev/null
git -C "$REPO_DIR" config user.name "$RED_NAME"
git -C "$REPO_DIR" config user.email "$RED_EMAIL"

sync_snapshot 0
git -C "$REPO_DIR" add -A
GIT_AUTHOR_NAME="$RED_NAME" \
GIT_AUTHOR_EMAIL="$RED_EMAIL" \
GIT_COMMITTER_NAME="$RED_NAME" \
GIT_COMMITTER_EMAIL="$RED_EMAIL" \
GIT_AUTHOR_DATE="$(timestamp_for_rev 0)" \
GIT_COMMITTER_DATE="$(timestamp_for_rev 0)" \
git -C "$REPO_DIR" commit --allow-empty -m "r0: initial import" >/dev/null
git -C "$REPO_DIR" tag r0 >/dev/null

git -C "$REPO_DIR" switch -c blue-base r0 >/dev/null
commit_rev 1 blue-base "$BLUE_NAME" "$BLUE_EMAIL" "branch blue-base from r0"

git -C "$REPO_DIR" switch -c red-lower r1 >/dev/null
commit_rev 2 red-lower "$RED_NAME" "$RED_EMAIL" "branch red-lower from r1"
commit_rev 3 red-lower "$RED_NAME" "$RED_EMAIL" "continue red-lower"
commit_rev 4 red-lower "$RED_NAME" "$RED_EMAIL" "prepare split to blue-upper"

git -C "$REPO_DIR" switch -c blue-upper r4 >/dev/null
commit_rev 5 blue-upper "$BLUE_NAME" "$BLUE_EMAIL" "branch blue-upper from r4"

commit_rev 6 blue-base "$BLUE_NAME" "$BLUE_EMAIL" "continue blue-base"
commit_rev 7 main "$RED_NAME" "$RED_EMAIL" "continue main"

git -C "$REPO_DIR" switch -c blue-mid r7 >/dev/null
commit_rev 8 blue-mid "$BLUE_NAME" "$BLUE_EMAIL" "branch blue-mid from r7"

commit_rev 9 red-lower "$RED_NAME" "$RED_EMAIL" "continue red-lower"
commit_rev 10 blue-upper "$BLUE_NAME" "$BLUE_EMAIL" "continue blue-upper"
commit_rev 11 blue-mid "$BLUE_NAME" "$BLUE_EMAIL" "continue blue-mid"

git -C "$REPO_DIR" switch -c red-side r3 >/dev/null
commit_rev 12 red-side "$RED_NAME" "$RED_EMAIL" "branch red-side from r3"

merge_rev 13 blue-mid red-side "$BLUE_NAME" "$BLUE_EMAIL" "merge red-side into blue-mid"
commit_rev 14 blue-upper "$BLUE_NAME" "$BLUE_EMAIL" "continue blue-upper"
commit_rev 15 blue-mid "$BLUE_NAME" "$BLUE_EMAIL" "continue blue-mid"
commit_rev 16 blue-base "$BLUE_NAME" "$BLUE_EMAIL" "continue blue-base"
commit_rev 17 main "$RED_NAME" "$RED_EMAIL" "continue main"

git -C "$REPO_DIR" switch -c red-feature r17 >/dev/null
commit_rev 18 red-feature "$RED_NAME" "$RED_EMAIL" "branch red-feature from r17"

commit_rev 19 blue-upper "$BLUE_NAME" "$BLUE_EMAIL" "continue blue-upper"
commit_rev 20 red-feature "$RED_NAME" "$RED_EMAIL" "continue red-feature"
commit_rev 21 red-feature "$RED_NAME" "$RED_EMAIL" "continue red-feature"
commit_rev 22 blue-upper "$BLUE_NAME" "$BLUE_EMAIL" "continue blue-upper"
commit_rev 23 blue-base "$BLUE_NAME" "$BLUE_EMAIL" "continue blue-base"
commit_rev 24 blue-upper "$BLUE_NAME" "$BLUE_EMAIL" "finish blue-upper before merge"
merge_rev 25 blue-base blue-upper "$BLUE_NAME" "$BLUE_EMAIL" "merge blue-upper into blue-base"
commit_rev 26 red-lower "$RED_NAME" "$RED_EMAIL" "continue red-lower"
commit_rev 27 red-feature "$RED_NAME" "$RED_EMAIL" "finish red-feature before merge"
merge_rev 28 red-lower red-feature "$RED_NAME" "$RED_EMAIL" "merge red-feature into red-lower"
commit_rev 29 red-lower "$RED_NAME" "$RED_EMAIL" "continue red-lower after merge"
commit_rev 30 blue-base "$BLUE_NAME" "$BLUE_EMAIL" "continue blue-base after merge"
merge_rev 31 blue-mid blue-base "$BLUE_NAME" "$BLUE_EMAIL" "merge blue-base into blue-mid"
merge_rev 32 red-lower blue-mid "$RED_NAME" "$RED_EMAIL" "merge blue-mid into red-lower"
commit_rev 33 red-lower "$RED_NAME" "$RED_EMAIL" "last red-lower commit"
merge_rev 34 main red-lower "$RED_NAME" "$RED_EMAIL" "merge red-lower into main"

git -C "$REPO_DIR" log --graph --decorate --oneline --all > "$BUILD_DIR/graph.txt"
git -C "$REPO_DIR" shortlog -sne --all > "$BUILD_DIR/authors.txt"
git -C "$REPO_DIR" log --date=iso-strict --format='%h %ad %an <%ae>' --all | sort > "$BUILD_DIR/dates.txt"

echo "Replay repository: $REPO_DIR"
echo "Graph: $BUILD_DIR/graph.txt"
echo "Authors: $BUILD_DIR/authors.txt"
echo "Dates: $BUILD_DIR/dates.txt"
echo
git -C "$REPO_DIR" log --graph --decorate --oneline --all
