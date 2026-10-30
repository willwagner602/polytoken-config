# polytoken-config

Polytoken configuration for `willwagner602`, plus a bootstrap script for
fresh machines.

## Bootstrap a new machine

`install-polytoken.sh` installs the Polytoken CLI, clones this repo, and
copies the tracked config into `~/.config/polytoken`.

```sh
curl -fsSLO https://raw.githubusercontent.com/willwagner602/polytoken-config/main/install-polytoken.sh
sh install-polytoken.sh
```

Preview what it will do without changing anything:

```sh
DRY_RUN=1 sh install-polytoken.sh
```

Only git-tracked files are copied, so stray local edits in the clone never
reach the live config. If an existing `~/.config/polytoken/config.yaml`
differs from the repo, it is backed up to `config.yaml.bak.<timestamp>`
before being overwritten.

Re-running is safe: the clone is kept at `~/.local/share/polytoken-config`
and updated with a fast-forward pull instead of a re-clone.

### Options

All are environment variables; none are required.

| Variable | Default | Purpose |
|---|---|---|
| `POLYTOKEN_REPO` | `willwagner602/polytoken-config` | Config repo to pull |
| `PT_CHANNEL` | `stable` | Installer release channel |
| `CONFIG_DIR` | `~/.config/polytoken` | Live config destination |
| `CLONE_DIR` | `~/.local/share/polytoken-config` | Where the repo is cloned |
| `PT_INSTALL_DIR` | installer default | Override binary location, e.g. `~/.bin` |
| `PT_FORCE` | `0` | Set to `1` to reinstall over an existing binary |
| `DRY_RUN` | unset | Set to `1` to print actions only |

Example — install a specific channel into a custom config dir:

```sh
PT_CHANNEL=next CONFIG_DIR=~/scratch/polytoken sh install-polytoken.sh
```

The script adds the binary's directory to your shell profile if it is not
already on `PATH`, then runs `polytoken config validate` and fails loudly
if the config does not parse.

## Repository layout

| Path | Contents |
|---|---|
| `config.yaml` | Main Polytoken config: model groups, providers, MCP servers |
| `skills/`, `subagents/` | Custom skill and subagent definitions |
| `install-polytoken.sh` | Bootstrap script described above |

## Notes

- `config.yaml` is the live source of truth. Edit it here, commit, then
  re-run the bootstrap script on machines that need the update.
- Local backups (`config.yaml.bak-*`), `prompt_history`, and
  `permissions.local.yaml` are gitignored, so they never leave the machine
  they were created on.
