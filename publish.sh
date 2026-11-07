#!/bin/bash

# Builds, packages and releases Power Timer. Run by the Publish workflow, see
# .github/workflows/publish.yml, and can be run locally as well (Git Bash on
# Windows), see help(). Building needs lazbuild and fpc on the PATH.

# Default values
COMMAND="build"
BRANCH=""
COMMIT=""
MESSAGE=""
VERSION="auto"
BUMP_TYPE="patch"
PREVIEW="auto"
UNATTENDED="false"
# The major version stream: "auto" is the major of the latest release or
# preview tag, but never below FIRST_MAJOR, the major the versions start at
BASE_VER="auto"
FIRST_MAJOR="1"

APP_LPI="src/PowerTimer.lpi"
TESTS_LPI="tests/PowerTimerTests.lpi"
WIN_EXE="src/bin/x86_64-win64/PowerTimer.exe"
ARCH="win-x64"

# Allowed values
_command_values=("build" "package" "release" "version")
_bump_type_values=("major" "minor" "patch")
_preview_values=("auto" "true" "false")
_unattended_values=("true" "false")

# Semantic Versioning 2.0.0, see https://semver.org
_semver_regex='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-(0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*)(\.(0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*))*)?(\+[0-9a-zA-Z-]+(\.[0-9a-zA-Z-]+)*)?$'

# Colors
Color_Off='\033[0m'
Color_Green='\033[0;32m'
Color_Yellow='\033[0;33m'

function main() {
  read_args "$@"

  case "$COMMAND" in
    "build") build ;;
    "package") package ;;
    "release") release ;;
    "version") version_cmd ;;
  esac
}

function build() {
  # The tests are built for the platform of fpc, e.g. x86_64-win64
  local target exe_ext=""
  target="$(fpc -iTP)-$(fpc -iTO)"
  if [[ ! $? -eq 0 ]]; then exit 1; fi
  case "$target" in
    *-win*) exe_ext=".exe" ;;
  esac

  lazbuild -B "$TESTS_LPI"
  if [[ ! $? -eq 0 ]]; then exit 1; fi

  "tests/bin/$target/PowerTimerTests$exe_ext"
  if [[ ! $? -eq 0 ]]; then exit 1; fi

  # The version is written into a copy of the project file, which is put
  # back when the script ends, also if the build fails
  local lpi_backup
  lpi_backup=$(mktemp)
  cp "$APP_LPI" "$lpi_backup"
  # shellcheck disable=SC2064 # expanded now, lpi_backup is local
  trap "mv -f '$lpi_backup' '$APP_LPI'" EXIT
  set_version_info

  lazbuild -B --build-mode=Release "$APP_LPI"
  if [[ ! $? -eq 0 ]]; then exit 1; fi # exit if build failed or canceled

  echo
  echo -e "${Color_Green}Build OK${Color_Off}"
}

# Writes VERSION into the version info of APP_LPI: x.y.z is the file version
# (x.y.z.0) and the whole version, e.g. 1.2.0-preview.1, the product version.
# The numbers are removed first, because Lazarus does not store those that
# are 0.
function set_version_info() {
  local major minor patch
  IFS='.' read -r major minor patch <<< "${VERSION%%[-+]*}"

  if ! grep -q '<UseVersionInfo Value="True"/>' "$APP_LPI" || ! grep -q '<StringTable ' "$APP_LPI"; then
    echo "Error. $APP_LPI has no version info, enable it in Project Options > Version Info."
    exit 1
  fi

  sed -i -E \
    -e '/<(MajorVersionNr|MinorVersionNr|RevisionNr|BuildNr) Value=/d' \
    -e "s#<UseVersionInfo Value=\"True\"/>#&\n      <MajorVersionNr Value=\"$major\"/>\n      <MinorVersionNr Value=\"$minor\"/>\n      <RevisionNr Value=\"$patch\"/>#" \
    -e 's# ProductVersion="[^"]*"##' \
    -e "s#<StringTable #<StringTable ProductVersion=\"$VERSION\" #" \
    "$APP_LPI"
}

function package() {
  local release_path="release"
  local archive_name="PowerTimer_${VERSION}_${ARCH}.zip"

  if [ ! -f "$WIN_EXE" ]; then
    echo "Error. $WIN_EXE not found, run the build command on Windows first."
    exit 1
  fi

  # The executable must be the one built for this version
  if command -v powershell.exe > /dev/null; then
    local built
    built=$(powershell.exe -NoProfile -Command "(Get-Item '$WIN_EXE').VersionInfo.ProductVersion" | tr -d '\r')
    if [ "$built" != "$VERSION" ]; then
      echo "Error. $WIN_EXE was not built for version $VERSION, its product version is '$built'."
      exit 1
    fi
  else
    echo -e "${Color_Yellow}powershell.exe not found, the version of $WIN_EXE is not checked${Color_Off}"
  fi

  rm -rf "$release_path"
  mkdir -p "$release_path"

  # Only the file name is stored, not its folder
  if command -v zip > /dev/null; then
    zip -9 -j "$release_path/$archive_name" "$WIN_EXE"
  elif command -v 7z > /dev/null; then
    7z a -tzip -mx=9 "$release_path/$archive_name" "./$WIN_EXE"
  else
    echo "Error. zip or 7z is needed to create $archive_name"
    false
  fi
  if [[ ! $? -eq 0 ]]; then exit 1; fi

  # Written as "<hash>  <name>" on every platform; sha256sum in Git Bash
  # would mark the file as binary ("<hash> *<name>")
  local sha256
  sha256=$(sha256sum "$release_path/$archive_name" | cut -d ' ' -f 1)
  echo "$sha256  $archive_name" > "$release_path/checksums.txt"
  cat "$release_path/checksums.txt"

  echo -e "${Color_Green}Package OK${Color_Off}"
}

function release() {
  if [ ! $UNATTENDED = "true" ]
  then
    read -p "Do you want to continue to git tag, push...? (y/n) " yn
    if [ ! $yn = "y" ]; then exit; fi
  fi

  local tag="v$VERSION"
  local tagged
  tagged=$(git rev-parse -q --verify "refs/tags/$tag^{commit}")
  # The tag can exist on this commit when a failed release is run again
  if [ -z "$tagged" ]; then
    git tag "$tag"
    if [[ ! $? -eq 0 ]]; then exit 1; fi
  elif [ "$tagged" != "$COMMIT" ]; then
    echo "Error. Tag $tag already exists on another commit: $tagged"
    exit 1
  fi

  git push origin "$tag"
  if [[ ! $? -eq 0 ]]; then exit 1; fi

  local url="$(git remote get-url origin | sed -E 's/\.git$//')/releases/tag/$tag"
  echo -e "${Color_Yellow}Version $VERSION released${Color_Off}"
  echo -e "URL: $url"
  echo -e "${Color_Green}All done${Color_Off}"
}

function version_cmd() {
  echo "$VERSION"
}

function read_args() {
  while [ "${1:-}" != "" ]; do
    case "$1" in
      "-h" | "--help")
        help
        exit 0
        ;;
      "-v" | "--version")
        shift
        VERSION="$1"
        ;;
      "-b" | "--bump_type")
        shift
        if is_in_array "$1" "${_bump_type_values[@]}"; then
            BUMP_TYPE="$1"
        else
            invalid_argument "$1" "${_bump_type_values[*]}"
            exit 1
        fi
        ;;
      "-p" | "--preview")
        shift
        if is_in_array "$1" "${_preview_values[@]}"; then
            PREVIEW="$1"
        else
            invalid_argument "$1" "${_preview_values[*]}"
            exit 1
        fi
        ;;
      "-u" | "--unattended")
        shift
        if is_in_array "$1" "${_unattended_values[@]}"; then
            UNATTENDED="$1"
        else
            invalid_argument "$1" "${_unattended_values[*]}"
            exit 1
        fi
        ;;
      "-M" | "--base_ver")
        shift
        # Empty is auto, as for the version
        if [ -z "$1" ] || [ "$1" = "auto" ]; then
            BASE_VER="auto"
        elif [[ "$1" =~ ^(0|[1-9][0-9]*)$ ]]; then
            BASE_VER="$1"
        else
            invalid_argument "$1" "auto 1 2 ..."
            exit 1
        fi
        ;;
      *)
        if is_in_array "$1" "${_command_values[@]}"; then
            COMMAND="$1"
        else
            invalid_argument "$1" "${_command_values[*]}"
            exit 1
        fi
        ;;
    esac
    shift
  done

  if [ "$BASE_VER" = "auto" ]; then
    BASE_VER=$(latest_major)
  fi

  if [ -n "$GITHUB_REF_NAME" ]; then
    BRANCH="$GITHUB_REF_NAME"
  else
    BRANCH=$(git branch --show-current)
  fi

  COMMIT=$(git log -n 1 --format="%H")
  MESSAGE=$(git log -n 1 --format="%s")

  if [ "$PREVIEW" = "auto" ]; then
    if [ "$BRANCH" != "master" ]; then
      PREVIEW="true"
    else
      PREVIEW="false"
    fi
  fi

  if [ -z "$VERSION" ] || [ "$VERSION" = "auto" ]; then
    local latest_stable=$(git tag --sort=-version:refname \
      | grep -E "^v${BASE_VER}\.[0-9]+\.[0-9]+$" | head -1 | sed 's/^v//')
    local latest_preview=$(git tag --sort=-version:refname \
      | grep -E "^v${BASE_VER}\.[0-9]+\.[0-9]+-preview\.[0-9]+$" | head -1 | sed 's/^v//')

    if [ "$COMMAND" != "version" ]; then
      echo "BASE_VER:     $BASE_VER"
      echo "STABLE_VER:   $latest_stable"
      echo "PREVIEW_VER:  $latest_preview"
    fi

    if [[ -z "$latest_stable" && -z "$latest_preview" ]]; then
      # No tags exist yet for this major stream — start fresh
      if [[ "$PREVIEW" == "true" ]]; then
        VERSION="${BASE_VER}.0.0-preview.1"
      else
        VERSION="${BASE_VER}.0.0"
      fi
    else
      # Determine current_version: whichever is truly latest overall within this stream
      local current_version="$latest_stable"
      if [[ -n "$latest_preview" ]]; then
        local preview_main="${latest_preview%-preview.*}"
        version_compare "$preview_main" "${latest_stable:-0.0.0}"
        if [[ $? -eq 1 ]]; then
          current_version="$latest_preview"  # preview cycle is ahead of stable
        fi
      fi
      VERSION=$(bump_version "$current_version" "$BUMP_TYPE" "$PREVIEW")
    fi
  else
    BUMP_TYPE="-"
    PREVIEW="-"
  fi

  if [[ ! "$VERSION" =~ $_semver_regex ]]; then
    echo "Error. Invalid version: $VERSION"
    echo "It must be a semantic version, e.g. 1.1.0 or 1.1.0-preview.1"
    exit 1
  fi

  # The release command accepts an existing tag on this commit, see release()
  if [ "$COMMAND" != "release" ] && git rev-parse -q --verify "refs/tags/v$VERSION" > /dev/null; then
    echo "Error. Version $VERSION is already released: tag v$VERSION exists"
    exit 1
  fi

  if [ "$COMMAND" != "version" ]; then
    echo "COMMAND:      $COMMAND"
    echo "VERSION:      $VERSION"
    echo "BUMP_TYPE:    $BUMP_TYPE"
    echo "PREVIEW:      $PREVIEW"
    echo "BASE_VER:     $BASE_VER"
    echo "BRANCH:       $BRANCH"
    echo "COMMIT:       $COMMIT"
    echo "MESSAGE:      $MESSAGE"
  fi

  if [ "$COMMAND" = "version" ]; then
    : # no countdown for version query
  elif [ $UNATTENDED = "true" ]
  then
    for i in {3..0..1}; do echo -en "\rContinue in $i" && if [ "$i" -gt "0" ]; then sleep 1; fi; done
    echo -en "\r             "
    echo
  else
    read -p "Press any key to continue..." -n1 -s; echo
    echo
  fi
}

function help() {
  echo "Usage:"
  echo "  ./publish.sh <command> [options]"
  echo ""
  echo "Commands:"
  echo "  build                          Step 1: run the tests, build PowerTimer.exe with the version"
  echo "  package                        Step 2: zip PowerTimer.exe, write the checksum to release/"
  echo "  release                        Step 3: execute git tag, push..."
  echo "  version                        Print computed version and exit"
  echo ""
  echo "Options:                         Allowed values:"
  echo "  -v, --version <VERSION>        auto*, x.y.z, x.y.z-preview.N"
  echo "  -b, --bump_type <BUMP_TYPE>    major, minor, patch*"
  echo "  -p, --preview <PREVIEW>        auto*, true, false"
  echo "  -M, --base_ver <BASE_VER>      auto*, 1, 2, ..."
  echo "  -u, --unattended <UNATTENDED>  true, false*"
  echo "  -h, --help"
  echo "                                 * Default value"
  echo ""
  echo "Examples:"
  echo "  ./publish.sh build"
  echo "  ./publish.sh build -v 1.2.0"
  echo "  ./publish.sh package -v 1.2.0"
  echo "  ./publish.sh version"
  echo "  ./publish.sh version -b minor"
  echo "  ./publish.sh version -M 1"
}

# The highest major of the release and preview tags (v1.2.3, v1.2.3-preview.1),
# or FIRST_MAJOR when there is none or it is lower
function latest_major() {
  local major
  major=$(git tag --list 'v*' \
    | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+(-preview\.[0-9]+)?$' \
    | sed -E 's/^v([0-9]+)\..*/\1/' | sort -n | tail -1)
  if [ -z "$major" ] || ((10#$major < FIRST_MAJOR)); then
    echo "$FIRST_MAJOR"
  else
    echo "$((10#$major))"
  fi
}

function is_in_array() {
  local value="$1"
  shift
  for element in "$@"; do
    if [[ "$element" == "$value" ]]; then
      return 0
    fi
  done
  return 1
}

function invalid_argument() {
  echo "Error. Invalid argument value: $1"
  echo "Allowed values: ${*:2}"
  echo
  help
}

function version_compare() {
  # split the versions into main version and prerelease parts
  IFS='-' read -r main1 pre1 <<< "$1"
  IFS='-' read -r main2 pre2 <<< "$2"

  # compare prerelease versions if main versions are the same
  if [[ $main1 == $main2 ]]; then
    if [[ -z $pre1 && -n $pre2 ]]; then
      return 1 # no pre1: 1.2.3 > 1.2.3-preview.X
    elif [[ -n $pre1 && -z $pre2 ]]; then
      return 2 # no pre2: 1.2.3-preview.X < 1.2.3
    elif [[ -n $pre1 && -n $pre2 ]]; then
      if [[ $pre1 == $pre2 ]]; then
        return 0 # preview.1 = preview.1
      else
        # extract numeric parts for comparison
        p1="${pre1/'preview.'/}"
        p2="${pre2/'preview.'/}"
        if (($p1 > $p2)); then
          return 1 # preview.10 > preview.1
        else
          return 2 # preview.1 < preview.10
        fi
      fi
    else
      return 0 # 1.2.3 = 1.2.3
    fi
  fi

  # compare the main versions numerically
  # src: https://stackoverflow.com/a/4025065; vercomp
  local IFS=.
  local i ver1=($main1) ver2=($main2)
  # fill empty fields in ver1 with zeros
  for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
  do
    ver1[i]=0
  done
  for ((i=0; i<${#ver1[@]}; i++))
  do
    if ((10#${ver1[i]:=0} > 10#${ver2[i]:=0}))
    then
      return 1
    fi
    if ((10#${ver1[i]} < 10#${ver2[i]}))
    then
      return 2
    fi
  done
  return 0
}

function bump_version() {
  local current_version="$1"
  local bump_type="$2"
  local preview="$3"

  IFS='-' read -ra chunks <<< $(echo $current_version | sed 's/-preview./-/')
  local current_main_version="${chunks[0]}"
  local current_prev_version="${chunks[1]:-0}"
  local next_version=""

  if [[ "$preview" == "false" ]]; then
    if [[ "$current_prev_version" -eq 0 ]]; then
      # Regular bump
      next_version=$(bump_version_main "$current_main_version" "$bump_type")
    else
      # Unpreview
      next_version="$current_main_version"
    fi
  else
    if [[ "$current_prev_version" -eq 0 ]]; then
      # First preview
      next_version=$(bump_version_main "$current_main_version" "$bump_type")
      next_version+="-preview.1"
    else
      # Bumping existing preview
      next_version="$current_main_version"
      next_version+="-preview.$((current_prev_version + 1))"
    fi
  fi

  echo "$next_version"
}

function bump_version_main() {
  local current_version="$1"
  local bump_type="$2"

  # Split the version into major, minor, and patch
  IFS='.' read -ra chunks <<< "$current_version"
  local major="${chunks[0]}"
  local minor="${chunks[1]:-0}"
  local patch="${chunks[2]:-0}"

  # Increment version based on bump type
  case "$bump_type" in
    major)
      ((major++))
      minor=0
      patch=0
      ;;
    minor)
      ((minor++))
      patch=0
      ;;
    patch)
      ((patch++))
      ;;
    *)
      echo "Invalid bump type: $bump_type"
      return 1
      ;;
  esac

  echo "${major}.${minor}.${patch}"
}

main "$@"
