---
description: Save the currently open Konsole tabs as a startup snapshot and restore their shell tabs on login.
---

# Save and restore Konsole tabs on GNOME

Use the helper at `~/.local/bin/konsole-tab-snapshot` to capture currently open tabs into `~/.config/konsole/startup-tabs`. The user has GNOME, not Plasma; GNOME session restore is not the mechanism used here.

## Save the open tabs

Run:

```sh
~/.local/bin/konsole-tab-snapshot save
```

This queries the live Konsole D-Bus window and writes a `--tabs-from-file` compatible snapshot. Review the output and report any tabs it could not capture. Save again whenever the desired tab set changes; this is a snapshot, not continuous synchronization.

## Restore

At GNOME login, `~/.config/autostart/konsole-restore.desktop` starts Konsole with `--tabs-from-file ~/.config/konsole/startup-tabs`. To test without logging out, run:

```sh
konsole --tabs-from-file ~/.config/konsole/startup-tabs
```

The snapshot preserves tab title, working directory when detectable, and Konsole profile. It recreates new shells; it cannot revive previous shell processes, command history in their memory, foreground programs, or split-view state. Do not put passwords or other secrets in commands in a tabs file.
