# Local Onion build (lid-support branch)

Personal build of OnionUI/Onion with Miyoo Mini Flip lid support. Upstream puts
lid support only on `v4.5-dev` (PR #1860 + #1873), which has no release.
`main` has the 4.4.0-beta releases. Branch `lid-support` is a linear stack on
top of `origin/main` (cherry-picked from `origin/v4.5-dev`, no merge commits):
MainUI-285 (#1873), the Flip lid/hardware PR (#1860), clang-format, then our
build script + this file. Keep it linear so `git rebase origin/main` works.

On top of that, Flip lid fixes in `src/keymon/keymon.c` (and one label in
`src/tweaks/menus.h`), one commit each: wake on lid open while charging;
ignore buttons while lid closed during suspend; suspend again if lid still
closed after wake (5s); debounce lid sensor reads; run lid check on every main
loop pass (`handle_lid`); rename lid close option to "Save & shutdown".

Research: /Users/kelsin/src/sync-roms/reports/Miyoo Mini Flip lid in Onion.md
(lid = poll `/sys/devices/soc0/soc/soc:hall-mh248/hallvalue`, 1=open, 0=closed;
logic is all in `src/keymon/keymon.c`; known unfixed bugs are listed there).
The lid sends no input event: tested on hardware, `event0`, `event1` and `mice`
stay silent on lid open/close, so polling `hallvalue` is the only option.

## Build

```bash
scripts/kelsin-build.sh kelsin-001
```

Produces `out/release/Onion-v<upstream VERSION>-kelsin-001.zip` (gitignored).
Version is read from `VERSION=` in the Makefile; the suffix is applied with
`VERSION_OVERRIDE`. Bump the suffix number per build. Needs Docker running;
the toolchain image is amd64-only (emulated on Apple Silicon, slow).
Don't build in the bind mount directly: `sed -i` fails there ("couldn't open
temporary file ... Permission denied"), hence the container-local copy.

## When upstream releases a new version

1. `git fetch origin --tags`. Upstream publishes betas as GitHub releases, not
   tags; `main`'s Makefile `VERSION=` is the release version.
2. Check whether lid support is now upstream:
   `git grep -l hall-mh248 origin/main` (and whether 4.5 shipped). If it is,
   drop this branch and build `origin/main` directly (`scripts/kelsin-build.sh`
   still works on it).
3. Otherwise: `git checkout lid-support && git rebase origin/main`. Resolve
   conflicts, usually `Makefile` version bumps, `runtime.sh`, `keymon.c`.
   If `v4.5-dev` gained new lid commits, cherry-pick them onto the stack
   (before our build-script commit, via `git rebase -i`) rather than merging.
4. Confirm lid code is in the build: after building,
   `strings -a out/build/.tmp_update/bin/keymon | grep -E "hallvalue|lidCloseAction"`
   and the same for `tweaks`.
5. Build with the next suffix and commit locally. Not tested on hardware as of
   the first build (kelsin-001): check the "Lid close action" option appears in
   Tweaks > System (a self-built v4.5-dev once reportedly didn't show it). If
   it is missing, run `cat /tmp/deviceModel` on the device; it must be `285`
   (the item is gated on `DEVICE_ID == MIYOO285`).
