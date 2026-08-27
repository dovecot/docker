#!/usr/bin/env bash
#
# Generic Dovecot Flavor Build Script
# Supports interactive wizard mode and non-interactive scripted mode.

set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────
# Styling & Helpers
# ──────────────────────────────────────────────────────────────────────────

if [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && [[ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]]; then
  BOLD=$(tput bold); RESET=$(tput sgr0)
  BLUE=$(tput setaf 4); GREEN=$(tput setaf 2); YELLOW=$(tput setaf 3); RED=$(tput setaf 1); CYAN=$(tput setaf 6)
else
  BOLD=""; RESET=""; BLUE=""; GREEN=""; YELLOW=""; RED=""; CYAN=""
fi

say()   { printf '  %s\n' "$1"; }
info()  { printf '%sℹ%s %s\n' "$CYAN" "$RESET" "$1"; }
ok()    { printf '%s✓%s %s\n' "$GREEN" "$RESET" "$1"; }
warn()  { printf '%s⚠%s %s\n' "$YELLOW" "$RESET" "$1"; }
err()   { printf '%s✗%s %s\n' "$RED" "$RESET" "$1" >&2; }
stage() { printf '\n%s%s=== %s ===%s\n\n' "$BOLD" "$BLUE" "$1" "$RESET"; }

# ──────────────────────────────────────────────────────────────────────────
# Discovery & Defaults
# ──────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

VERSION="${VERSION:-2.4.1}"
CONFIG_VERSION="${CONFIG_VERSION:-1.0.0}"
BASE_IMAGE_PREFIX="${BASE_IMAGE_PREFIX:-dovecot/dovecot:}"
DOVECOT_REPO_URL="${DOVECOT_REPO_URL:-https://github.com/dovecot/core}"
PIGEONHOLE_REPO_URL="${PIGEONHOLE_REPO_URL:-https://github.com/dovecot/pigeonhole}"
DOVECOT_BRANCH="${DOVECOT_BRANCH:-$VERSION}"
PIGEONHOLE_BRANCH="${PIGEONHOLE_BRANCH:-$VERSION}"

CONTAINER_ENGINE="${CONTAINER_ENGINE:-}"

FLAVOR="${FLAVOR:-}"
PLATFORMS="${PLATFORMS:-}"
TARGETS="${TARGETS:-all}"
BUILD_BASE="${BUILD_BASE:-auto}" # auto | always | never
INTERACTIVE=""
EXTRA_BUILD_ARGS=()

SET_FLAVOR="false"
SET_VERSION="false"
SET_PLATFORMS="false"
SET_TARGETS="false"

HOST_ARCH="$(uname -m)"
case "$HOST_ARCH" in
  x86_64) HOST_ARCH="amd64" ;;
  aarch64|arm64) HOST_ARCH="arm64" ;;
esac

TARGET_STAGES=()

# Detect or validate container engine (docker, podman, etc.)
detect_engine() {
  if [[ -n "$CONTAINER_ENGINE" ]]; then
    if ! command -v "$CONTAINER_ENGINE" >/dev/null 2>&1; then
      err "Configured container engine '$CONTAINER_ENGINE' not found in PATH."
      exit 1
    fi
    return 0
  fi

  if command -v docker >/dev/null 2>&1; then
    CONTAINER_ENGINE="docker"
  elif command -v podman >/dev/null 2>&1; then
    CONTAINER_ENGINE="podman"
  else
    err "Neither 'docker' nor 'podman' container engine was found in PATH."
    say "Please install Docker or Podman, or specify the binary using: $0 -e <engine> or CONTAINER_ENGINE=<cmd>"
    exit 1
  fi
}


# Architecture flags
amd64_CFLAGS="-g -O2 -mtune=generic -mavx -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer -flto=auto -ffat-lto-objects -fstack-clash-protection -fcf-protection -mharden-sls=all"
arm64_CFLAGS="-g -O2 -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer -fstack-clash-protection -mharden-sls=all -mbranch-protection=standard"
amd64_LDFLAGS="-Wl,-Bsymbolic-functions -flto=auto -ffat-lto-objects"
arm64_LDFLAGS="-Wl,-Bsymbolic-functions"

# Discover available flavors
discover_flavors() {
  (cd "${SCRIPT_DIR}" && ls -d */ 2>/dev/null | tr -d /)
}

# ──────────────────────────────────────────────────────────────────────────
# Usage & Help
# ──────────────────────────────────────────────────────────────────────────

show_help() {
  cat <<EOF
${BOLD}Dovecot Container Flavor Build Tool${RESET}

${BOLD}USAGE:${RESET}
  $(basename "$0") [OPTIONS] [FLAVOR]

${BOLD}ARGUMENTS:${RESET}
  FLAVOR                     Flavor name (e.g. chronos)

${BOLD}OPTIONS:${RESET}
  -f, --flavor <name>        Name of the flavor to build
  -v, --version <version>    Dovecot base version (default: ${VERSION})
  -c, --config-version <ver> Config version (default: ${CONFIG_VERSION})
  -p, --platform <archs>     Comma-separated platforms: amd64, arm64, or local (default: host architecture)
  -t, --target <targets>     Targets to build: all, prod, dev, root, or comma-separated (default: all)
  -e, --engine <command>     Container engine executable (e.g. podman or docker)
  --base-prefix <prefix>     Base image prefix (default: ${BASE_IMAGE_PREFIX})
  --build-base               Force building base images before flavor build
  --no-build-base            Skip building base images (fail if missing)
                             Flavor builds never pull images from a remote registry
                             (built with --pull=never): base images must exist
                             locally, built from ${ROOT_DIR}/Dockerfile. Use
                             --build-base or --base-prefix to match them.
  --repo-url <url>           Override flavor upstream git repository URL
  --branch <branch>          Override flavor git branch / tag
  --build-arg <KEY=VAL>      Pass additional build argument to docker build
  -i, --interactive          Force interactive wizard mode
  -n, --non-interactive      Force non-interactive mode
  -h, --help                 Show this help menu

${BOLD}AVAILABLE FLAVORS:${RESET}
$(for f in $(discover_flavors); do echo "  - $f"; done)

${BOLD}EXAMPLES:${RESET}
  # Interactive wizard:
  $(basename "$0")

  # Build Chronos flavor for host platform:
  $(basename "$0") chronos

  # Build Chronos for specific version and multi-arch:
  $(basename "$0") -f chronos -v 2.4.1 -p amd64,arm64 --build-base

  # Build only the dev container variant:
  $(basename "$0") chronos -t dev

EOF
}

# ──────────────────────────────────────────────────────────────────────────
# Parse CLI Options
# ──────────────────────────────────────────────────────────────────────────

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        show_help
        exit 0
        ;;
      -f|--flavor)
        FLAVOR="$2"; SET_FLAVOR="true"; shift 2 ;;
      -v|--version)
        VERSION="$2"; SET_VERSION="true"; shift 2 ;;
      -c|--config-version)
        CONFIG_VERSION="$2"; shift 2 ;;
      -p|--platform)
        PLATFORMS="$2"; SET_PLATFORMS="true"; shift 2 ;;
      -t|--target)
        TARGETS="$2"; SET_TARGETS="true"; shift 2 ;;
      -e|--engine)
        CONTAINER_ENGINE="$2"; shift 2 ;;
      --base-prefix)
        BASE_IMAGE_PREFIX="$2"; shift 2 ;;
      --build-base)
        BUILD_BASE="always"; shift ;;
      --no-build-base)
        BUILD_BASE="never"; shift ;;
      --repo-url)
        EXTRA_BUILD_ARGS+=("--build-arg" "FLAVOR_REPO_URL=$2")
        shift 2 ;;
      --branch)
        EXTRA_BUILD_ARGS+=("--build-arg" "FLAVOR_BRANCH=$2")
        shift 2 ;;
      --build-arg)
        EXTRA_BUILD_ARGS+=("--build-arg" "$2")
        shift 2 ;;
      -i|--interactive)
        INTERACTIVE="true"; shift ;;
      -n|--non-interactive)
        INTERACTIVE="false"; shift ;;
      -*)
        err "Unknown option: $1"
        show_help
        exit 1
        ;;
      *)
        if [[ -z "$FLAVOR" ]]; then
          FLAVOR="$1"
          SET_FLAVOR="true"
        else
          err "Unexpected argument: $1"
          show_help
          exit 1
        fi
        shift
        ;;
    esac
  done
}

# ──────────────────────────────────────────────────────────────────────────
# Validation
# ──────────────────────────────────────────────────────────────────────────

resolve_target_stages() {
  TARGET_STAGES=()
  local raw_targets
  IFS=',' read -r -a raw_targets <<< "${TARGETS// /}"
  for t in "${raw_targets[@]}"; do
    case "$t" in
      all) TARGET_STAGES=("-root" "-dev" "") ;;
      prod|production) TARGET_STAGES+=("") ;;
      dev|development) TARGET_STAGES+=("-dev") ;;
      root) TARGET_STAGES+=("-root") ;;
      *) err "Unknown target '$t'. Valid targets: all, prod, dev, root."; exit 1 ;;
    esac
  done
}

# ──────────────────────────────────────────────────────────────────────────
# Interactive Wizard Mode
# ──────────────────────────────────────────────────────────────────────────

run_wizard() {
  printf '\n%s%s╔══════════════════════════════════════════════════════════╗%s\n' "$BOLD" "$CYAN" "$RESET"
  printf '%s%s║          Dovecot Container Flavor Build Wizard           ║%s\n' "$BOLD" "$CYAN" "$RESET"
  printf '%s%s╚══════════════════════════════════════════════════════════╝%s\n\n' "$BOLD" "$CYAN" "$RESET"

  info "Container engine: $CONTAINER_ENGINE"
  printf '\n'

  local available_flavors=($(discover_flavors))
  if [[ ${#available_flavors[@]} -eq 0 ]]; then
    err "No flavors found in ${SCRIPT_DIR}"
    exit 1
  fi

  # Step 1: Select Flavor
  if [[ "$SET_FLAVOR" != "true" || -z "$FLAVOR" ]]; then
    printf '%sSelect flavor to build:%s\n' "$BOLD" "$RESET"
    local idx=1
    for f in "${available_flavors[@]}"; do
      printf '  %s%d)%s %s\n' "$CYAN" "$idx" "$RESET" "$f"
      ((idx++))
    done
    while true; do
      printf 'Enter choice [1-%d]: ' "${#available_flavors[@]}"
      read -r choice
      if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#available_flavors[@]} )); then
        FLAVOR="${available_flavors[$((choice - 1))]}"
        break
      fi
      warn "Invalid choice, please try again."
    done
  fi
  ok "Flavor: $FLAVOR"

  # Step 2: Version
  if [[ "$SET_VERSION" != "true" ]]; then
    printf '\n%sDovecot base version%s [%s]: ' "$BOLD" "$RESET" "$VERSION"
    read -r input_version
    [[ -n "$input_version" ]] && VERSION="$input_version"
  fi
  ok "Base version: $VERSION"

  # Step 3: Architecture / Platforms
  if [[ "$SET_PLATFORMS" != "true" ]]; then
    printf '\n%sSelect target platform(s):%s\n' "$BOLD" "$RESET"
    printf '  %s1)%s Host architecture only (%s)\n' "$CYAN" "$RESET" "$HOST_ARCH"
    printf '  %s2)%s amd64\n' "$CYAN" "$RESET"
    printf '  %s3)%s arm64\n' "$CYAN" "$RESET"
    printf '  %s4)%s Both amd64 and arm64\n' "$CYAN" "$RESET"
    printf 'Enter choice [1-4] (default: 1): '
    read -r pchoice
    case "${pchoice:-1}" in
      1) PLATFORMS="$HOST_ARCH" ;;
      2) PLATFORMS="amd64" ;;
      3) PLATFORMS="arm64" ;;
      4) PLATFORMS="amd64,arm64" ;;
      *) PLATFORMS="$HOST_ARCH" ;;
    esac
  fi
  ok "Platforms: $PLATFORMS"

  # Step 4: Target variants
  if [[ "$SET_TARGETS" != "true" ]]; then
    printf '\n%sSelect image target(s):%s\n' "$BOLD" "$RESET"
    printf '  %s1)%s All variants (production, dev, root)\n' "$CYAN" "$RESET"
    printf '  %s2)%s Production only (minimal rootless)\n' "$CYAN" "$RESET"
    printf '  %s3)%s Development only (rootless with tools)\n' "$CYAN" "$RESET"
    printf '  %s4)%s Root only (traditional root container)\n' "$CYAN" "$RESET"
    printf 'Enter choice [1-4] (default: 1): '
    read -r tchoice
    case "${tchoice:-1}" in
      1) TARGETS="all" ;;
      2) TARGETS="prod" ;;
      3) TARGETS="dev" ;;
      4) TARGETS="root" ;;
      *) TARGETS="all" ;;
    esac
  fi
  ok "Target variants: $TARGETS"
}

# ──────────────────────────────────────────────────────────────────────────
# Base Image Checks & Build
# ──────────────────────────────────────────────────────────────────────────

image_exists() {
  local image_tag="$1"
  "$CONTAINER_ENGINE" image inspect "$image_tag" >/dev/null 2>&1
}

ensure_base_images() {
  local platform="$1"
  local needed_stages=("-build" "${TARGET_STAGES[@]}")

  local missing_stages=()
  for stage in "${needed_stages[@]}"; do
    local img="${BASE_IMAGE_PREFIX}${VERSION}${stage}-${platform}"
    local alt_img="${BASE_IMAGE_PREFIX}${VERSION}${stage}"
    if ! image_exists "$img" && ! image_exists "$alt_img"; then
      missing_stages+=("$stage")
    fi
  done

  if [[ "$BUILD_BASE" == "always" || ${#missing_stages[@]} -gt 0 ]]; then
    if [[ "$BUILD_BASE" == "never" ]]; then
      err "Required base image(s) missing for platform $platform and --no-build-base was specified: ${missing_stages[*]}"
      exit 1
    fi

    if [[ "$BUILD_BASE" == "auto" && -t 0 && "${INTERACTIVE:-false}" != "false" ]]; then
      warn "Base images for Dovecot $VERSION ($platform) are missing or incomplete (${missing_stages[*]})."
      printf '  %sWould you like to build the required base images now using %s? [Y/n]: %s' "$BOLD" "$CONTAINER_ENGINE" "$RESET"
      read -r confirm
      if [[ "$confirm" =~ ^[Nn] ]]; then
        err "Cannot proceed without base images."
        exit 1
      fi
    fi

    stage "Building Base Images ($platform) with $CONTAINER_ENGINE"
    local p_cflags="${platform}_CFLAGS"
    local p_ldflags="${platform}_LDFLAGS"

    local stages_to_build
    if [[ "$BUILD_BASE" == "always" ]]; then
      stages_to_build=("-build" "-root" "-dev" "")
    else
      stages_to_build=("${missing_stages[@]}")
    fi

    for stage in "${stages_to_build[@]}"; do
      local target_name="production${stage}"
      local tag_arch="${BASE_IMAGE_PREFIX}${VERSION}${stage}-${platform}"
      local tag_generic="${BASE_IMAGE_PREFIX}${VERSION}${stage}"

      info "Building base target: ${target_name} -> ${tag_arch}"
      "$CONTAINER_ENGINE" build \
        --platform "linux/${platform}" \
        --build-arg CFLAGS="${!p_cflags:-}" \
        --build-arg LDFLAGS="${!p_ldflags:-}" \
        --build-arg DOVECOT_VERSION="$VERSION" \
        --build-arg PIGEONHOLE_VERSION="${PIGEONHOLE_VERSION:-$VERSION}" \
        --build-arg DOVECOT_REPO_URL="$DOVECOT_REPO_URL" \
        --build-arg DOVECOT_BRANCH="${DOVECOT_BRANCH:-$VERSION}" \
        --build-arg PIGEONHOLE_REPO_URL="$PIGEONHOLE_REPO_URL" \
        --build-arg PIGEONHOLE_BRANCH="${PIGEONHOLE_BRANCH:-$VERSION}" \
        --build-arg CONFIG_VERSION="$CONFIG_VERSION" \
        --target "$target_name" \
        --tag "$tag_arch" \
        --tag "$tag_generic" \
        -f "${ROOT_DIR}/Dockerfile" \
        "$ROOT_DIR"
    done
    ok "Base images built successfully for $platform."
  fi
}

# ──────────────────────────────────────────────────────────────────────────
# Flavor Build Execution
# ──────────────────────────────────────────────────────────────────────────

build_flavor() {
  local flavor_dir="${SCRIPT_DIR}/${FLAVOR}"
  local dockerfile="${flavor_dir}/Dockerfile"

  if [[ ! -f "$dockerfile" ]]; then
    err "Dockerfile not found for flavor '$FLAVOR' at $dockerfile"
    exit 1
  fi

  # Determine platforms list
  local platform_list=()
  if [[ -z "$PLATFORMS" || "$PLATFORMS" == "local" ]]; then
    platform_list=("$HOST_ARCH")
  else
    IFS=',' read -r -a platform_list <<< "${PLATFORMS// /}"
  fi

  local built_images=()

  stage "Starting Build for Flavor: ${FLAVOR}"
  info "Engine       : $CONTAINER_ENGINE"
  info "Base Version : $VERSION"
  info "Platforms    : ${platform_list[*]}"
  info "Targets      : ${TARGETS}"
  info "Flavor Dir   : ${flavor_dir}"

  for platform in "${platform_list[@]}"; do
    ensure_base_images "$platform"

    local p_cflags="${platform}_CFLAGS"
    local p_ldflags="${platform}_LDFLAGS"

    for stage_suffix in "${TARGET_STAGES[@]}"; do
      local target_name="${FLAVOR}${stage_suffix}"
      local image_tag="${BASE_IMAGE_PREFIX}${VERSION}-${FLAVOR}${stage_suffix}-${platform}"
      local latest_tag="${BASE_IMAGE_PREFIX}latest-${FLAVOR}${stage_suffix}-${platform}"

      stage "Building ${FLAVOR} target: ${target_name} [${platform}]"

      "$CONTAINER_ENGINE" build \
        --pull=never \
        --platform "linux/${platform}" \
        --build-arg BASE_IMAGE_PREFIX="$BASE_IMAGE_PREFIX" \
        --build-arg BASE_TAG="$VERSION" \
        --build-arg CFLAGS="${!p_cflags:-}" \
        --build-arg LDFLAGS="${!p_ldflags:-}" \
        "${EXTRA_BUILD_ARGS[@]}" \
        --target "$target_name" \
        --tag "$image_tag" \
        --tag "$latest_tag" \
        -f "$dockerfile" \
        "$flavor_dir"

      built_images+=("$image_tag" "$latest_tag")
      ok "Successfully built: $image_tag"
    done
  done

  stage "Build Complete"
  ok "All requested targets for flavor '${FLAVOR}' built successfully."
  say "Images:"
  for img in "${built_images[@]}"; do
    say "  $img"
  done
}

# ──────────────────────────────────────────────────────────────────────────
# Main Entry Point
# ──────────────────────────────────────────────────────────────────────────

main() {
  parse_args "$@"
  detect_engine

  # podman stores local images under localhost/; without the prefix the name
  # resolves to docker.io and the flavor build silently extends a pulled
  # upstream image instead of the one this repo's Dockerfile produced.
  if [[ "$CONTAINER_ENGINE" == "podman" && "$BASE_IMAGE_PREFIX" != localhost/* ]]; then
    BASE_IMAGE_PREFIX="localhost/${BASE_IMAGE_PREFIX}"
  fi

  # Run interactive wizard by default in a terminal unless -n / --non-interactive is specified
  if [[ "$INTERACTIVE" == "true" || ( "$INTERACTIVE" != "false" && -t 0 ) ]]; then
    run_wizard
  fi

  if [[ -z "$FLAVOR" ]]; then
    err "No flavor specified."
    show_help
    exit 1
  fi

  resolve_target_stages
  build_flavor
}

main "$@"

