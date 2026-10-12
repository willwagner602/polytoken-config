#!/bin/sh
# Bootstrap Polytoken on a fresh Linux/macOS instance.
#
# Installs the Polytoken CLI with the official shell installer (stable
# channel), then pulls the Polytoken config from a git repo and installs it
# into ~/.config/polytoken. Only git-tracked files are copied, so stray local
# edits in the clone never leak into the live config.
#
# The clone is kept at $CLONE_DIR, so re-running this script refreshes the
# config with a fast pull instead of a re-clone.
#
# Environment:
#   POLYTOKEN_REPO    config repo to pull        (default willwagner602/polytoken-config)
#   PT_CHANNEL        installer channel          (default stable)
#   CONFIG_DIR        live Polytoken config dir  (default ~/.config/polytoken)
#   CLONE_DIR         where the config is cloned (default ~/.local/share/polytoken-config)
#   PT_INSTALL_DIR    installer override, e.g. ~/.bin (passed through)
#   DRY_RUN=1         print what would happen without changing anything
#
# Usage:
#   sh install-polytoken.sh
#   DRY_RUN=1 sh install-polytoken.sh
set -eu

REPO_URL=${POLYTOKEN_REPO:-https://github.com/willwagner602/polytoken-config.git}
PT_CHANNEL=${PT_CHANNEL:-stable}
CONFIG_DIR=${CONFIG_DIR:-"${XDG_CONFIG_HOME:-$HOME/.config}/polytoken"}
CLONE_DIR=${CLONE_DIR:-"${XDG_DATA_HOME:-$HOME/.local/share}/polytoken-config"}

DRY_RUN=${DRY_RUN:-}

log() { printf '%s\n' "install-polytoken: $*"; }
die() { printf '%s\n' "install-polytoken: ERROR: $*" >&2; exit 1; }

# run CMD ARGS... — execute, or just print under DRY_RUN=1.
run() {
    if [ -n "$DRY_RUN" ]; then
        printf '  [dry-run] %s\n' "$*"
    else
        "$@"
    fi
}

[ -n "$DRY_RUN" ] && log "dry run: no changes will be made"

# --- dependencies -----------------------------------------------------------

ensure_cmd() {
    command -v "$1" >/dev/null 2>&1 && return 0
    log "$1 not found; installing..."
    if command -v apt-get >/dev/null 2>&1; then
        SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"
        run $SUDO apt-get update -qq
        run $SUDO apt-get install -y -qq "$2"
    elif command -v dnf >/dev/null 2>&1; then
        SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"
        run $SUDO dnf install -y -q "$2"
    elif command -v pacman >/dev/null 2>&1; then
        SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"
        run $SUDO pacman -S --noconfirm --quiet "$2"
    else
        die "please install '$1' (package '$2') and re-run"
    fi
}

ensure_cmd curl curl
ensure_cmd git  git

# --- install the Polytoken CLI ----------------------------------------------

# The installer picks ~/.local/bin (or ~/bin) when it is on PATH; make sure
# both are visible to this script so a fresh install is found immediately.
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) PATH="$HOME/.local/bin:$PATH" ;;
esac
case ":$PATH:" in
    *":$HOME/bin:"*) ;;
    *) PATH="$HOME/bin:$PATH" ;;
esac

if command -v polytoken >/dev/null 2>&1 && [ "${PT_FORCE:-0}" != "1" ]; then
    log "polytoken already installed: $(command -v polytoken)"
else
    log "installing polytoken (channel: $PT_CHANNEL)..."
    if [ -n "$DRY_RUN" ]; then
        printf '  [dry-run] curl -fsS https://get.polytoken.dev | env PT_CHANNEL=%s bash\n' "$PT_CHANNEL"
    else
        curl -fsS https://get.polytoken.dev | env PT_CHANNEL="$PT_CHANNEL" bash
    fi
fi

if [ -z "$DRY_RUN" ] && ! command -v polytoken >/dev/null 2>&1; then
    die "polytoken was installed but is not on PATH; add \$HOME/.local/bin to PATH and re-run"
fi

# --- pull the config repo ----------------------------------------------------

if [ -d "$CLONE_DIR/.git" ]; then
    log "updating existing clone at $CLONE_DIR..."
    run git -C "$CLONE_DIR" pull --ff-only
else
    log "cloning $REPO_URL into $CLONE_DIR..."
    run git clone --depth 1 "$REPO_URL" "$CLONE_DIR"
fi

# --- sync tracked files into the live config dir -----------------------------

run mkdir -p "$CONFIG_DIR"

# Back up an existing config.yaml before overwriting it, so a local change
# that was never pushed to the repo is not lost.
if [ -z "$DRY_RUN" ] && [ -f "$CONFIG_DIR/config.yaml" ] && [ -f "$CLONE_DIR/config.yaml" ]; then
    if ! cmp -s "$CONFIG_DIR/config.yaml" "$CLONE_DIR/config.yaml"; then
        BACKUP="$CONFIG_DIR/config.yaml.bak.$(date +%Y%m%dT%H%M%S)"
        cp "$CONFIG_DIR/config.yaml" "$BACKUP"
        log "existing config.yaml differs from repo; backed up to $BACKUP"
    fi
fi

log "installing tracked files into $CONFIG_DIR..."
if [ -n "$DRY_RUN" ]; then
    printf '  [dry-run] git -C %s archive HEAD | tar -x -C %s\n' "$CLONE_DIR" "$CONFIG_DIR"
else
    git -C "$CLONE_DIR" archive HEAD | tar -x -C "$CONFIG_DIR"
fi

log "installed:"
if [ -n "$DRY_RUN" ]; then
    printf '  [dry-run] (files from %s)\n' "$REPO_URL"
else
    ( cd "$CONFIG_DIR" && find . -type f -not -name '*.bak.*' | sort | sed 's/^/  /' )
fi

# --- validate -----------------------------------------------------------------

if [ -z "$DRY_RUN" ] && command -v polytoken >/dev/null 2>&1; then
    log "validating config..."
    if polytoken config validate; then
        log "config valid"
    else
        die "polytoken config validate failed — check $CONFIG_DIR/config.yaml"
    fi
fi

log "done. run 'polytoken doctor' to inspect registered servers."
