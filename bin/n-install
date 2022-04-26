#!/usr/bin/env bash

# !! CAVEAT: 
# !! On FreeBSD, process substitution (<(...)) is by default NOT ENABLED - AVOID PROCESS SUBSTITUTIONS IN THIS SCRIPT.
# !! (hypothetical, for now, because n as of 1.3.0 doesn't support FreeBSD, given that binary Node.js packages aren't available for it)

#
# Script-global constants
# 

kMIN_BASH_VERSION='3.2'  # due to use of =~, we require at least 3.2

##### IMPORTANT: These names must, at least in part, be kept in sync with their counterparts in 'n-update' and 'n-uninstall'.
kINSTALLER_NAME=n-install  # This script's name; note that since we'll typically be running via curl directly from GitHub, using $(basename "$BASH_SOURCE") to determine the name is not an option.
#  Note: The actual *installation* URL is http://bit.ly/n-install which redirects to https://raw.githubusercontent.com/mklement0/n-install/stable/bin/n-install
kTHIS_REPO_URL='https://bit.ly/n-install-repo' # This script's source repository - SHORT, git.io-based form.
kTHIS_REPO_URL_LONG='https://github.com/mklement0/n-install' # This script's source repository in LONG form - needed for deriving raw.githubusercontent.com URLs from it.
kPREFIX_DIR=${N_PREFIX:-$HOME/n} # The target prefix directory, inside which both a dir. for n itself and the active node version's dirs. will be located.
## For updating the relevant shell initialization file: The string that identifies the line added by us.
## !! IMPORTANT:
## !!   Now that this project has been published, we HARD-CODE this ID string to ensure that old installations are found.
## !!   Notably, we've changed from:
## !!     http:// to https:// URLs later
## !!     http://git.io/n-install-repo to https://bit.ly/n-install-repo after retirment of git.io
## !!   but the ID STRING MUST CONTINUE TO USE "http://git.io/n-install-repo" to avoid breaking later uninstalls / reinstalls. 
kINIT_FILE_LINE_ID=" # Added by n-install (see http://git.io/n-install-repo)."
kREGEX_CONFLICTING_LINE='^[^#]*\bN_PREFIX=' # Regex that identifies relevant existing lines.
##### 

kTHIS_NAME=$kINSTALLER_NAME

kN_REPO_URL='https://github.com/tj/n' # n's GitHub repo URL
kN_DIRNAME='n' # The name of the subdir. of the $kPREFIX_DIR that *n itself assumes* it is installed in.
kSUBDIRS=( "$kN_DIRNAME" bin include lib share ) # (informational) all subdirs. of N_PREFIX into which files will be installed as of node 0.12

## Names, download URLs, and checksums for the helper scripts
kUPDATE_SCRIPT='n-update' # Filename of the custom update script.
kUNINSTALL_SCRIPT='n-uninstall' # Filename of the custom uninstall script.
kHELPER_SCRIPTS=( 
  "$kUPDATE_SCRIPT"
  "$kUNINSTALL_SCRIPT"
) 
latestOrStable='stable'
[[ -n $N_INSTALL_TEST_OVERRIDE_SHELL_INIT_FILE ]] && latestOrStable='master' # override for testing: use the latest code from the 'master' branch rather than the officially stable code from the 'stable' label.
kHELPER_SCRIPT_URLS=( 
  "${kTHIS_REPO_URL_LONG/\/\/github.com\////raw.githubusercontent.com/}/$latestOrStable/bin/$kUPDATE_SCRIPT" 
  "${kTHIS_REPO_URL_LONG/\/\/github.com\////raw.githubusercontent.com/}/$latestOrStable/bin/$kUNINSTALL_SCRIPT" 
)
  # SHA-256 checksum for the helper scripts.
  # !! These checksums must be updated whenever `n-update` and `n-uninstall`
  # !! are modified, which also happens when merely the version number is
  # !! bumped. 
  # !! The Makefile takes care of updating after every version bump 
  # !! (`make version`` or implicitly with `make release``), but you can do it on
  # !! demand with `make update-checksums`.
  # !! DO NOT MODIFY THE *FORMAT* OF THIS ARRAY LITERAL - `util/update-checksums`
  # !! and a test rely on it.
kSHA256_SUMS=(
  "0741efcc06bb5e4754167206e17534ddac0f2a62e18e3f1f8c8a25ba45080ac1  $kUPDATE_SCRIPT"
  "73a44d510c828f71fe8454e78bd6ed78ada0e01dfe975b4a883bbd437e293e1c  $kUNINSTALL_SCRIPT"
)
##

# 
# BEGIN: Helper functions
#

# SYNOPIS
#   isMinBashVersion <major[.minor]>
# DESCRIPTION
#   Indicates via exit code whether the Bash version running this script meets the minimum version number specified.
# EXAMPLES
#   isMinBashVersion 3.2
#   isMinBashVersion 4
isMinBashVersion() {
  local minMajor minMinor thisMajor thisMinor
  IFS=. read -r minMajor minMinor <<<"$1"
  [[ -z $minMinor ]] && minMinor=0
  thisMajor=${BASH_VERSINFO[0]}
  thisMinor=${BASH_VERSINFO[1]}
  (( thisMajor > minMajor || (thisMajor == minMajor && thisMinor >= minMinor) ))
}

# !! ========== IMPORTANT:
# !! Since Bash's parsing of the script FAILS BELOW on versions < 3.2 due to use of `=~`,
# !! we do the version check HERE, right after definining the function, which should work.
# !! Verified on Bash 3.1 - unclear, how far back it works, however.
isMinBashVersion "$kMIN_BASH_VERSION" || { echo "FATAL ERROR: This script requires Bash $kMIN_BASH_VERSION or higher. You're running: $BASH_VERSION" >&2; exit 1; }
# !! ==========

# SYNOPSIS
#   echoColored colorNum [text...]
# DESCRIPTION
#   Prints input in the specified color, which must be an ANSI color code (e.g., 31 for red).
#   Input is either provided via the TEXT operands, or, in their absence, from stdin.
#   If input is provided via TXT operands, a trailing \n is added.
#   NOTE: 
#     - Unlike echo, uses stdin, if no TEXT arguments are specified; you MUST either specify
#       at least one input operand OR stdin input; in that sense, this function is like a hybrid
#       between echo and cat. However, *interactive* stdin input makes no sense, and therefore
#       a newline is simply printed - as with echo without arguments - if stdin is connected to
#       a terminal and neither operands nor stdin input is provided.
#     - Coloring is suppressed, if the variable kNO_COLOR exists and is set to 1.
#       An invoking script may set this in case output is NOT being sent to a terminal.
#       (E.g., test -t 1 || kNO_COLOR=1)
# EXAMPLES
#   echoColored 31 "I'm red"
#   cat file | echoColored 32 # file contents is printed in green
echoColored() {
  local pre="\033[${1}m" post='\033[0m'
  (( kNO_COLOR )) && { pre= post=; }
  shift # skip the color argument
  if (( $# )); then
    printf "${pre}%s${post}\n" "$*"
  else
    [[ -t 0 ]] && { printf '\n'; return; } # no interactive stdin input
    printf "$pre"; cat; printf "$post"
  fi  
}

# SYNOPSIS
#   dieSyntax [msg|-]
# DESCRIPTION
#   Prints a red error message to stderr and exits with exit code 2, meant to indicate a 
#   syntax problem (invalid arguments).
#   A standard message is provided, if no arguments are given.
#   If the first (and only) argument is '-', input is taken from stdin; otherwise, the 
#   first argument specifies the message to print.
#   Either way, a preamble with this script's name and the type of message is printed.
# NOTES
#   Uses echoColored(), whose coloring may be suppressed with kNO_COLOR=1.
dieSyntax() { 
  local kPREAMBLE="$kTHIS_NAME: ARGUMENT ERROR:"
  if [[ $1 == '-' ]]; then # from stdin
    { 
      printf '%s\n' "$kPREAMBLE"
      sed 's/^/  &/'
    } | echoColored 31 # red
  else # from operands
    echoColored 31 "$kPREAMBLE: ${1:-"Invalid argument(s) specified."} Use -h for help."
  fi
  exit 2
} >&2

# SYNOPSIS
#   die [msg|- [exitCode]]
# DESCRIPTION
#   Prints a red error message to and by default exits with exit code 1, meant to indicate
#   a runtime problem.
#   A standard message is provided, if no arguments are given.
#   If the first (and only) argument is '-', input is taken from stdin; otherwise, the 
#   first argument specifies the message to print.
#   Either way, a preamble with this script's name and the type of message is printed.
# NOTES
#   Uses echoColored(), whose coloring may be suppressed with kNO_COLOR=1.
die() { 
  local kPREAMBLE="$kTHIS_NAME: ERROR:"
  if [[ $1 == '-' ]]; then # from stdin
    { 
      printf '%s\n' "$kPREAMBLE"
      sed 's/^/  &/'
    } | echoColored 31 # red
  else # from operands
    echoColored 31 "$kPREAMBLE ${1:-"ABORTING due to unexpected error."}"
  fi
  exit ${2:-1}
} >&2

# SYNOPSIS
#   warn [msg|-]
# DESCRIPTION
#   Prints a yellow warning message to stderr.
#   If the first (and only) argument is '-', input is taken from stdin; otherwise, the 
#   first argument specifies the message to print.
#   Either way, a preamble with this script's name and the type of message is printed.
# NOTES
#   Uses echoColored(), whose coloring may be suppressed with kNO_COLOR=1.
warn() {
  local kPREAMBLE="$kTHIS_NAME: WARNING:"
  [[ $1 == '-' ]] && shift # for consistency with die() and dieSyntax(), accept '-' as an indicator that stdin input should be used.
  if (( $# == 0 )); then # from stdin
    { 
      printf '%s\n' "$kPREAMBLE"
      sed 's/^/  &/'
    } | echoColored 33 # yellow
  else # from operands
    echoColored 33 "$kPREAMBLE $*"
  fi
} >&2

# -- Coloring convenience output functions
#    They're based on echoColored(), and thus take either operands or stdin input.
#    If input is provided via arguments, a trailing \n is added.
green()  { echoColored 32 "$@"; }
red()    { echoColored 31 "$@"; }
blue()   { echoColored 34 "$@"; }
yellow() { echoColored 33 "$@"; }

isDirEmpty() {
  [[ -d ${1:-.} ]] || { echo "$FUNCNAME: ERROR: Argument not found or not a directory: $1" >&2; return 2; }
  [[ $(shopt -s nullglob dotglob; cd "$1"; echo *) =~ ^$|^\.DS_Store$ ]]
}

# SYNOPIS
#   rreadlink fileOrDirPath
# DESCRIPTION
#   Resolves fileOrDirPath to its ultimate target.
#   This is a POSIX-compliant implementation of what GNU readlink's -f option does.
#   Edge cases: won't work with filenames with embedded newlines or filenames containing the string ' -> '.
# EXAMPLE
#   In a shell script, use the following to get that script's true directory of origin:
#     $(dirname -- "$(rreadlink "$0")")
rreadlink() ( # Execute the function in a *subshell* to localize variables and the effect of `cd`.

  target=$1 fname= targetDir=

  # Try to make the execution environment as predictable as possible:
  # All commands below are invoked via `command -p`, so we must make sure that `command`
  # itself is not redefined as an alias or shell function.
  # `command` is a *builtin* in bash, dash, ksh, zsh, and some platforms do not even have
  # an external utility version of it (e.g, Ubuntu).
  # `command` bypasses aliases and shell functions, and `-p` searches for external utilities
  # in standard locations only, but note that this does *not* come into play if a *builtin*
  # by the given name exists. zsh requires that option POSIX_BUILTINS be on to also find
  # builtins with `command`.
  { CDPATH=; \unalias command; \unset -f command; } >/dev/null 2>&1
  [ -n "$ZSH_VERSION" ] && options[POSIX_BUILTINS]=on # make zsh find *builtins* with `command` too.

  while :; do # Resolve potential symlinks until the ultimate target is found.
      [ -L "$target" ] || [ -e "$target" ] || { printf '%s\n' "ERROR: '$target' does not exist." >&2; return 1; }
      command -p cd "$(command -p dirname -- "$target")" # Change to target dir; necessary for correct resolution of target path.
      fname=$(command -p basename -- "$target") # Extract filename.
      if [ -L "$fname" ]; then
        # Extract [next] target path, which may be defined
        # *relative* to the symlink's own directory.
        # Note: We parse `ls -l` output to find the symlink target
        #       which is the only POSIX-compliant, albeit somewhat fragile, way,
        target=$(command -p ls -l "$fname")
        target=${target#* -> }
        continue # Resolve [next] symlink target.
      fi
      break # Ultimate target reached.
  done
  targetDir=$(command -p pwd -P) # Get canonical dir. path
  # Output the ultimate target's canonical path.
  command -p printf '%s\n' "${targetDir%/}/$fname"
)


# SYNOPSIS
#   clearDir dir
# DESCRIPTION
#   !!!!!!!!!!! USE WITH CAUTION !!!!!!!!!!!!!!
#   Clears the contents of the specified directory.
#   Exit code 0 indicates that clearing succeeded.
clearDir() ( # execute in subshell to localize effect of shopt
  local d=${1?Missing directory argument} itms=()
  [[ -d $d ]] || return 1 # Makes sure that dir. exists.
  shopt -s dotglob nullglob # Make sure that hidden files are included when expanding `*` and that the result is empty if there are no items at all.
  itms=( "$d"/* ) # Collect items, if any.
  (( ${#itms[@]} == 0 )) && return 0 # If there are no items at all, return with exit code 0.
  # There are items: try to remove them all - if there are permission problems, the exit code will be set to a non-zero value.
  rm -rf "${itms[@]}"
)

# SYNOPSIS
#   getShellInitFile
# DESCRIPTION
#   Returns the full path of the initalization file of the shell identified
#   via (environment variable) $SHELL, the user's default shell.
#   If $SHELL refers to an *unsupported* shell, the empty string is returned.
getShellInitFile() {
  local initFile=''

  # IMPORTANT:
  #   This STATEMENT MUST BE KEPT IN SYNC with cleanUpShellInitFile() in n-uninstall.
  case "$(basename -- "$SHELL")" in
    'bash')
      # !! Sadly, bash ONLY reads ~/.bash_profile in LOGIN shells, and on macOS (Darwin) ALL shells are login shells, so on macOS we must target ~/.bash_profile.
      [[ $(uname) == 'Darwin' ]] && initFile=~/.bash_profile || initFile=~/.bashrc
      ;;
    'ksh')
      initFile=~/.kshrc
      ;;
    'zsh')
      initFile=${ZDOTDIR:-~}/.zshrc
      ;;
    'fish')
      initFile=${XDG_CONFIG_HOME:-~/.config}/fish/config.fish
      ;;
    'pwsh') # PowerShell
      initFile=${XDG_CONFIG_HOME:-~/.config}/powershell/Microsoft.PowerShell_profile.ps1
      ;;
  esac

  printf %s "$initFile"

}

# Print the line that a shell initialization file must contain for `n` (and 
# `n-update` and `n-uninstall`) to work correctly.
getShellInitFileLine() {

    local cmd_setEnvVar cmd_addToPath

    # Synthesize the - single - line to add to the init file.
    # Definition of the N_PREFIX environment variable plus ensuring that
    # $N_PREFIX/bin is in the $PATH, followed by the identifying comment.
    # E.g.:
    #   POSIX-compatible shells:
    #      export N_PREFIX="$HOME/n"; [[ :$PATH: == *":$N_PREFIX/bin:"* ]] || PATH+=":$N_PREFIX/bin"  # Added by n-install (see http://git.io/n-install-repo).
    #   fish:
    #      set -x N_PREFIX "$HOME/n"; contains $N_PREFIX $PATH; or set -a PATH $N_PREFIX # Added by n-install (see http://git.io/n-install-repo).
    #   pwsh (PowerShell):
    #      $env:N_PREFIX="$HOME/n"; if ($env:PATH -split ":" -notcontains "$env:N_PREFIX/bin") { $env:PATH += ":$env:N_PREFIX/bin" } # Added by n-install (see http://git.io/n-install-repo).

    # IMPORTANT:
    #   To facilitate language-neutral, regex-based extracton of the $N_PREFIX value in in `n-uninstall`:
    #     * Use NO WITHESPACE AROUND "=" in `...N_PREFIX="..."...` and EXACTLY ONE SPACE in `...NPREFIX "..."`
    #     * Use ONLY VARIABLE REFERENCES IN THE FORM `$FOO` - fortunately, even though PowerShell generally requires
    #       the form $env:FOO for environment variables, it does have a built-in $HOME variable too.
    case "$(basename -- "$SHELL")" in
      'fish')
        cmd_setEnvVar="set -x N_PREFIX \"${N_PREFIX/#$HOME/\$HOME}\""
        cmd_addToPath='contains "$N_PREFIX/bin" $PATH; or set -a PATH "$N_PREFIX/bin"'
        ;;
      'pwsh') # PowerShell      
        cmd_setEnvVar="\$env:N_PREFIX=\"${N_PREFIX/#$HOME/\$HOME}\"" # !! Use `$HOME`, not `$env:HOME` - see above.
        cmd_addToPath='if ($env:PATH -split ":" -notcontains "$env:N_PREFIX/bin") { $env:PATH += ":$env:N_PREFIX/bin" }'
        ;;
      *) # all POSIX-compatible shells
        cmd_setEnvVar="export N_PREFIX=\"${N_PREFIX/#$HOME/\$HOME}\""
        cmd_addToPath='[[ :$PATH: == *":$N_PREFIX/bin:"* ]] || PATH+=":$N_PREFIX/bin"'
        ;;
    esac

    # NOTE: This currently relies on ALL supported shells using:
    #         ";" as the statement separator
    #         "#" as the comment character. 
    printf '%s; %s %s' "$cmd_setEnvVar" "$cmd_addToPath" "$kINIT_FILE_LINE_ID"
}

# SYNOPSIS
#   modifyShellInitFile
# DESCRIPTION
#   Modifies the relevant initialization file for the current user's shell by
#   adding a SINGLE line composed of:
#     - export N_PREFIX=... command 
#     - an add-bin-Dir-to-$PATH-if not-yet-there command.
#  Outputs the full path of the initialization file modified.
modifyShellInitFile() {

  local line initFile existingLine initFileContents

  # Get the path to the init file as well as the line to add to it.
  initFile="$(getShellInitFile)"
  line="$(getShellInitFileLine)"

  # Determine the shell-specific initialization file.
  if [[ -n $N_INSTALL_TEST_OVERRIDE_SHELL_INIT_FILE ]]; then # override for testing
      initFile=$N_INSTALL_TEST_OVERRIDE_SHELL_INIT_FILE
  elif [[ -z $initFile ]]; then
    warn - <<EOF
Automatic modification of the initialization file for shell
$SHELL is not supported.
For n and the Node.js versions managed by it to work correctly,
you must MANUALLY ADD THE EQUIVALENT OF THE FOLLOWING TO YOUR SHELL'S
INITIALIZATION FILE:

$line
EOF
    return 0
  fi

  # To be safe: create the directory for the initialization file on demand.
  # Presumably this is only ever necessary for PowerShell (pwsh).
  mkdir -p "$(dirname -- "$initFile")" || die

  if [[ -f $initFile ]]; then

    existingLine=$(grep -E "$kREGEX_CONFLICTING_LINE" "$initFile")
    (( $(grep -c '^' <<<"$existingLine") > 1 )) &&
      die - <<EOF
Aborting, because multiple existing definitions of \$N_PREFIX were found in
'$initFile':

$existingLine

Please remove them and try again.
EOF

  fi
  
  if [[ -n $existingLine && $existingLine != *$kINIT_FILE_LINE_ID* ]]; then # A "foreign" 'export N_PREFIX=' line was found.

    die - <<EOF
Aborting, because an existing definition of \$N_PREFIX added by someone else
was found in '$initFile':

$existingLine

Please remove it and try again.
EOF

  else # No existing line was found, or one we ourselves previously added.
    errMsg="Aborting, because shell initialization file '$initFile' could not be updated."
    if [[ -z $existingLine ]]; then # Simplest case: no traces of an old installation were found.
      # Simply append to file (which may get created on demand.)
      printf '\n%s\n' "$line" >>"$initFile" || { echo "$errMsg" >&2; return 1; }
    elif [[ "$existingLine" != "$line" ]]; then # A line from a previous installation of ours was found: update it.
      # !! We do NOT use sed -i, because that is not safe, notably because it
      # !! would destroy a symlink, if the target file happens to be one.
      # !! Instead, we read the entire contents into memory, and rewrite
      # !! the modified string using simply '>', which DOES preserve the
      # !! existing inode and thus file attributes including symlink status.
      # !! Also note that for simplicity and consistency we add the new line at the *end*.
      initFileContents=$(grep -Ev "$kREGEX_CONFLICTING_LINE" "$initFile")
      printf '%s\n\n%s\n' "$initFileContents" "$line" > "$initFile" || die "$errMsg"
    fi
  fi
  
  printf '%s\n' "$initFile"

  return 0
}

# SYNOPSIS
#   parseSemVer [-2] version
# DESCRIPTION
#   Parses the specified semver-2.0-compatible version into its components (see http://semver.org/).
#   If you specify option -2, only the <major>.<minor> part must be present.
#   Nothing is output if the version is not semver-compatible, and the return value is set to 1.
#   Each component is returned on its own line, up to and including the last component found:
#   Line 1 == major, line 2 == minor, line 3 == patch, line 4 == pre-release ID, line 5 == build metadata
#   Thus, you get 2-5 lines of output, but note that if build metada was specified without also
#   specifying a pre-release ID, line 4 will be empty.
# EXAMPLES
#   parseSemVer 0.5.12 # -> $'0\n5\n12'
#   parseSemVer 0.5.12 # -> $'0\n5\n12'
#   parseSemVer 0.5.12-pre # -> $'0\n5\n12\npre'
#   parseSemVer 0.5.12-pre+build7 # -> $'0\n5\n12\npre\nbuild7'
#   parseSemVer 0.5.12+build7 # -> $'0\n5\n12\n\nbuild7'
parseSemVer() {
  local onlyMajorMinorRequired=0
  [[ $1 == '-2' ]] && { onlyMajorMinorRequired=1; shift; }
  (( $# == 1 )) || return 2

  # Parse into major, minor, patch, and *roughly* into pre-release identifiers and metadata.
  local num='([0-9]|[1-9][0-9]+)' # a decimal integer, but leading zeros are not allowed
  local idList='([0-9A-Za-z.-]+)' # looser-than-required expression for the sub-identifiers making up the pre-release and metada parts; additional validation required
  # [[ $1 =~ ^$num\.$num(\.$num(-$idList(\+$idList)?)?)?$ ]] || return 1
  [[ $1 =~ ^$num\.$num(\.$num(-$idList)?(\+$idList)?)?$ ]] || return 1

  # See if we have at least major, minor, patch, or, if -2 was specified, major and minor.
  local n major=${BASH_REMATCH[1]} minor=${BASH_REMATCH[2]} patch=${BASH_REMATCH[4]} prId=${BASH_REMATCH[6]} buildMd=${BASH_REMATCH[8]}
  [[ -n $patch ]] || (( onlyMajorMinorRequired )) || return 1

  # Validate the optional pre-release part and the metadata part, each composed of
  # a list of non-empty, dot-separated sub-identifiers that are either decimal integers without
  # leading zeros or strings composed of any mix of [0-9A-Za-z-]
  local id ids=()
  for n in prId buildMd; do
    if [[ -n ${!n} ]]; then
      IFS=. read -ra ids <<<"${!n}" # break into '.'-separated sub-IDs
      [[ ${!n} =~ \.$ ]] && return 1 # must not end in '.' (if the last char. is an IFS char, `read` ignores it).
      for id in "${ids[@]}"; do
        [[ -z $id ]] && return 1 # empty sub-IDs not allowed.      
        [[ -n $(tr -d '[0-9]' <<<"$id") ]] && continue # sub-ID contains non-digits - no further validation required
        [[ $id =~ ^$num$ ]] || return 1  # otherwise: a decimal integer - make sure it has no leading zeros, as with major, minor, patch.
      done
    fi
  done

  # Output all components found.
  local all=0
  [[ -n $buildMd ]] && all=1
  for n in major minor patch prId buildMd; do
    [[ $all -eq 0 && -z ${!n} ]] && break
    printf '%s\n' "${!n}"
  done

  return 0
}


# 
# END: Helper functions
#

#
# MAIN SCRIPT BODY
#

unset CDPATH  # to prevent unpredictable `cd` behavior
[[ -t 1 ]] || kNO_COLOR=1 # turn off colored output if stdout is not connected to a terminal

# Output version number and exit, if requested. Note that the `ver='...'` statement is automatically updated by `make version VER=<newVer>` - DO keep the 'v' prefix in the variable _definition_.
[[ $1 == '--version' ]] && { ver='v0.6.3'; echo "$kTHIS_NAME ${ver#v}"$'\nFor license information and more, visit https://bit.ly/n-install-repo'; exit 0; }

# !! AS OF n 1.3.0, n ITSELF ONLY WORKS WITH curl, NOT ALSO WITH wget.
# !! Once n also supports wget, mention wget as an alternative in the help text.
if [[ $1 == '--help' || $1 == '-h' ]]; then
  cat <<EOF
SYNOPSIS
  $kTHIS_NAME [-t] [-y|-q] [-n] [-a <arch>] [<version>...]

DESCRIPTION
  Directly installs n, the Node.js version manager, which bypasses the need to
  manually install a Node.js version first.

  Additionally, installs $kUPDATE_SCRIPT for updating n,
  and $kUNINSTALL_SCRIPT for uninstallation.

  On successful installation of n, the specified Node.js <version>(s)
  are installed; by default, this is the latest LTS Node.js version.
  
  To opt out, specify '-' as the only version argument.

  Supported version specifiers:

  * lts    ... the LTS (long-term stability) version
  * latest ... the latest version available overall
  * otherwise, specify an explicit version number, such as '0.12' or '0.10.35'
  
  If multiple versions are specified, the first one will be made active.

  The default installation directory is:

    ${kPREFIX_DIR/#$HOME/~}
  
  which can be overridden by setting environment variable N_PREFIX to an
  absolute path before invocation; either way, however, the installation
  directory must either not exist yet or be empty.

  If your shell is bash, bsh, zsh, fish, or pwsh (PowerShell), the relevant
  initialization file will be modified so as to:
   - export environment variable \$N_PREFIX to point to the installation dir.
   - ensure that the directory containing the n executable, \$N_PREFIX/bin,
     is in the \$PATH.
  Note that you either have to open a new terminal tab/window or re-source
  the relevant initialization file before you can use n and Node.js.
  For any other shell you'll have to make these modifications yourself.
  You can also explicitly opt out of the modification with -n.

  Options:

  -t
    Merely tests if all installation prerequisites are met, which is signaled
    with an exit code of 0.

  -y
    Assumes yes as the reply to all prompts; in other words: runs unattended
    by auto-confirming the confirmation prompt.
 
  -q
    Like -y, except that, additionally, all status messages are suppressed,
    including the information and progress bar normally displayed by n while
    installing Node.js versions.

  -n
    Suppresses updating of the relevant shell initialization file.
    For instance, this allows for custom setups where all exports are 
    "out-sourced" to an external file that is then sourced from the 
    shell-initialization file; however, note that you'll then have to edit 
    the out-sourced file *manually* - instructions will be printed.

  -a <arch>
    Specifies a specific architecture to install the specified or implied
    Node.js version(s) for, e.g. arm64 or x64.
    This overrides the default behavior of auto-selecting binaries that match
    the current system.

  For more information, see $kTHIS_REPO_URL

PREREQUISITES
  bash ... to run this script and n itself.
  curl ... to download helper scripts from GitHub and run n itself.
  git ... to clone n's GitHub repository and update n later.
  GNU make ... to run n's installation procedure.
  
EXAMPLES
    # Install n and the latest LTS Node.js version, with 
    # interactive prompt:
  $kTHIS_NAME 
    # Only test if installation to the specified location would work.
  N_PREFIX=~/util/n $kTHIS_NAME -t
    # Automated installation of n, without installing Node.js
  $kTHIS_NAME -y -
    # Automated installation of n, followed by automated installation
    # of the latest LTS and the latest-overall Node.js versions, as well
    # as the latest 0.8.x version.
  $kTHIS_NAME -y lts latest 0.8
EOF
    exit 0
fi

# Check for prerequisites.
preReqMsg=
# !! AS OF n 1.3.0, n ITSELF ONLY WORKS WITH curl, NOT ALSO WITH wget.
# !! Once n also supports wget, remove 'curl' from this `for` loop and activate
# !! the curl-OR-wget command below.
for exe in curl git; do
  [[ -n $(command -v "$exe") ]] || preReqMsg+="${preReqMsg:+$'\n'}\`$exe\` not found, which is required for operation."
done
#
# !! ACTIVATE THE FOLLOWING ONCE n ITSELF SUPPORTS wget.
# [[ -n $(command -v curl) || -n $(command -v wget) ]] || preReqMsg+="${preReqMsg:+$'\n'}Neither \`curl\` nor \`wget\` found; one of them is required for operation."
#
# !! n's own installation procedure, `make install`, unfortunately currently (1.3.0) requires GNU make (due to use of conditional assignment `?=`), even though it would be simple to make it 
# !! POSIX-compliant; for now, we therefore explicitly require GNU make.
# !! However, this is a hypothetical concern, because, as of n 1.3.0, n only works with *prebuilt* binaries downloadable from https://nodejs.org/dist/, and, as of Node.js v0.12.4,
# !! prebuilt binaries only exist for Linux, Darwin (OSX) (and Windows) - if building Node.js from source were supported, however, GNU make would be required for that, too.
for makeExe in make gmake; do
  "$makeExe" --version 2>/dev/null | grep -Fq "GNU Make" && break
  [[ $makeExe == 'make' ]] && continue # if 'make' isn't GNU Make, try again with 'gmake'.
  preReqMsg+="${preReqMsg:+$'\n'}GNU Make not found, which is required for operation."$'\n'"On FreeBSD and PC-BSD, for instance, you can download it with \`sudo pkg install gmake\`."
done
[[ -z $preReqMsg ]] || die - <<<"$preReqMsg"

# Parse options.
skipPrompts=0 testPrerequisitesOnly=0 skipInitFileUpdate=0 quiet=0 archOverride=
while getopts ':ytnqa:' opt; do
  [[ $opt == '?' ]] && dieSyntax "Unknown option: -$OPTARG"
  [[ $opt == ':' ]] && dieSyntax "Option -$OPTARG is missing its argument."  
  case "$opt" in
    t)
      testPrerequisitesOnly=1
      ;;
    y)
      skipPrompts=1
      ;;
    n)
      skipInitFileUpdate=1
      ;;
    q)
      quiet=1
      ;;
    a)
      archOverride="$OPTARG"
      ;;
    *)
      die "DESIGN ERROR: option -$opt not handled."
      ;;
  esac
done
shift $((OPTIND - 1))

# Determine what Node.js versions to install later.
if (( $# == 0 )); then # no operands
  # Install the latest LTS Node.js version by default.
  # !! Our default used to be 'stable' up to v0.4.1, but 'stable' no longer has 
  # !! meaning - see https://nodejs.org/en/blog/release/v6.0.0/#current-what-happened-to-stable
  # !! and https://nodesource.com/blog/nodejs-is-semver/
  # !! and nowadayas https://nodejs.org only offers *2* downloads prominently: LTS and Current,
  # !! which `n` still calls 'latest' (see below).
  versionsToInstall=( 'lts' )
else # operands specified: interpret them as Node.js versions to install
  # *Syntactically* validate version numbers specified, if any: i.e.,
  # make sure they're one of the following:
  #  * 'lts', 'latest' (or the obsolescent 'stable',
  #     which may become an alias for 'lts' - see
  #     https://github.com/tj/n/issues/335#issuecomment-167899989)
  #  * 'current': The Node.js project now uses 'Current' to refer to the latest 
  #     in-development release.
  #     !! `n` doesn't support 'current' as an identifer (yet?) as of v2.1.12,
  #     !! it still uses 'latest' for that.
  #     !! For now, as a courtesy, we map 'current' to 'latest', which presumes
  #     !! that `n` will either never introduce 'current' or, if it does,
  #     !! make it an alias of 'latest' too.
  #  * <major>.<minor>.<patch> or <major>.<minor>
  #  * '-' suppresses installation of the default version.
  # Note that checking for the actual availability of versions would be too time-consuming.
  versionsToInstall=()
  for ver; do
    case $ver in # Note: We do NOT convert to lowercase, for consistency with `n`, which requires case-exact all-lowercase identifiers.
      -)
        : # means: do NOT install the default Node.Js version; typically, 
          # we expect that to be the *only* operand, since an explicit list
          # of operands always overrides the default, but we don't enforce this.
        ;;
      lts|stable|latest|io:stable|io:latest) # symbolic names for latest LTS / in-development versions; 'stable' is obsolescent
        versionsToInstall+=( "$ver" )
        ;;
      current) # !! See comments above.
        versionsToInstall+=( 'latest' )
        ;;
      *) # must be a version number in the form <major>.<minor>[.<patch>]
        componentCount=$(parseSemVer -2 "${ver#io:}" | wc -l)
        (( componentCount == 2 || componentCount == 3 )) ||
          dieSyntax - <<<"'$ver' is not a valid Node.js version specifier."$'\n'"(Must be 'lts', 'latest', or <major>.<minor>[.<patch>].)" # , optionally prefixed with 'io:'
        versionsToInstall+=( "$ver" )
        ;;
    esac
  done
fi

# !! We prevent installation if the `n` or `npm` or `node` binaries are in the path, implying 
# !! that either n or Node.js are already installed - whether they were installed with
# !! this utility or not.
if [[ $N_INSTALL_TEST_OVERRIDE_SKIP_EXISTING_INSTALLATION_TEST != '1' ]]; then # override for testing
  existingExes=()
  for exe in n node npm; do
    # Note that `command -v` on Linux and OSX supports multiple arguments, but POSIX mandates only 1.
    exePath=$(command -v "$exe") && existingExes+=( "$exePath" )
  done
  if (( ${#existingExes[@]} > 0 )); then

    die - 3 <<EOF
  Aborting, because n and/or Node.js-related binaries are already in your \$PATH:

$(printf '       %s\n' "${existingExes[@]}")

  Please remove any existing n and/or Node.js installation, then try 
  again.
  $([[ -n $(command -v n) ]] && printf %s "If you previously installed n via $kTHIS_REPO_URL,"$'\n'"  run \`$kUNINSTALL_SCRIPT\` to uninstall.")
EOF

  fi
fi

N_PREFIX=$kPREFIX_DIR

# Make sure that N_PREFIX is an *absolute* path.
[[ $N_PREFIX == /* ]] || die "'$N_PREFIX' is not an absolute path; please specify the target directory as an absolute path."

# If the target dir. already exists, make sure it is empty.
didExist=0
if [[ -d $N_PREFIX ]]; then

  didExist=1  
  isDirEmpty "$N_PREFIX" || die - 3 <<EOF
Target directory '$N_PREFIX' already exists and is not empty.
Remove it or make sure it is completely empty, then try again.
EOF

fi

# Make sure we can create n's directory.
nDir=${N_PREFIX}/${kN_DIRNAME}
mkdir -p "$nDir" || die "Failed to create directory '$nDir'."

# Set up a trap to automatically clean up the dir(s) in case the installation
# doesn't finish - irrespective of how the script terminates / is terminated.
sigs=( EXIT HUP INT QUIT TERM )
# A note re exit code: with the exception of the EXIT pseudo-signal in the event
# of *self-initiated* termination, we do not have access to the signal number, 
# and $? will be 0. Unless -t was specified, for which an exit-code override is used,
# this trap (handler) typically kicks in in the event of *failure*,
# so, unless overridden, we ensure that a nonzero exit code is set.
# Again, the exception is the EXIT pseudo-signal in case of *signal-induced* 
# termination, which will *invariably* result in exit code 128 + SIGNUM.
# !! WE CAN ONLY CLEAN UP THE TARGET DIR BECAUSE WE'VE PREVIOUSLY ENSURED THAT 
# !! $N_PREFIX EITHER DIDN'T EXIST BEFORE OR WAS EMPTY.
ecOverride= # Set this to a value to override the exit code that the trap should report.
trap 'ec=${ecOverride:-$?}; [[ $ec -eq 0 && -z $ecOverride ]] && ec=1; (( didExist )) && clearDir "$N_PREFIX" || rm -rf "$N_PREFIX"; exit $ec' "${sigs[@]}"

# If only prerequisite testing was requested, report success and exit here.
if (( testPrerequisitesOnly )); then
    (( quiet )) || echo "Prerequisites for installing to '$N_PREFIX' are met."
    ecOverride=0
    exit
fi

if (( ! (skipPrompts || quiet) )); then

  userDefaultShell="$(basename -- $SHELL)"
  initFile="$(getShellInitFile)"
  [[ -n $initFile ]] && shellIsSupported=1 || shellIsSupported=0

  cat <<EOF
===
You are ABOUT TO INSTALL n, the Node.js VERSION MANAGER, in:

  $(green $N_PREFIX)

Afterwards, THE FOLLOWING Node.js VERSION(S) WILL BE INSTALLED,
and the first one listed will be made active; 
  'lts' refers to the LTS (long-term support) version, 
  'latest' to the latest available version.
  '-' means that *no* version will be installed:

  $( (( ${#versionsToInstall[@]} > 0 )) && green "${versionsToInstall[*]}" || yellow NOTE: Skipping Node.js installation, as requested.)
 
If your shell is bash, bsh, zsh, fish, or pwsh (PowerShell), the relevant 
initialization file will be modified in order to:
 - export environment variable \$N_PREFIX.
 - ensure that \$N_PREFIX/bin is in the \$PATH

$(
  if (( skipInitFileUpdate )); then
    echo "  $(yellow NOTE: Skipping initialization-file update, as requested.)"
  elif (( shellIsSupported )); then
  cat <<EOF4
$(green Your shell, $userDefaultShell, IS supported), and the following initialization
file will be updated:

   $initFile
EOF4

else

  cat <<EOF5
$(red Your shell, $userDefaultShell, is NOT supported for automatic initialization-file modification.)
You will have to make these modifications yourself - details to follow.
EOF5

fi
)

For more information, see $kTHIS_REPO_URL
===
EOF

  # Determine where to read user input from:
  #   If -f ${BASH_SOURCE} is true, we're running from a local script file, such as during testing, so we respect whatever stdin is set to, so that user input can be *simulated*.
  #   Otherwise, the assumption is that we're running via curl ... | bash, in which case we always want to read from /dev/tty - giving us a chance to 
  #   to pipe the script contents via stdin, while soliciting user input from the terminal (unless -y was specified to skipt he confirmation prompt).
  [[ -f ${BASH_SOURCE} ]] && src='/dev/stdin' || src='/dev/tty'

  # Prompt the user:
  while :; do
    read -ep "CONTINUE (y/N)? " promptInput < "$src" || exit # `read` fails only if stdin does NOT come from a terminal
    [[ $promptInput =~ ^[nN]$ || -z $promptInput ]] && { echo "Aborted." >&2; exit 3; }
    [[ $promptInput != [yY] ]] && { echo "Invalid input; please try again." 1>&2; continue; }
    break
  done

fi

# Getting here means that installation prerequisites are fulfilled and the 
# intent to install was [auto-]confirmed.

# Derive additional paths:
nRepoDir=${nDir}/.repo
nBinDir=${N_PREFIX}/bin

# Clone n's repository into "${N_PREFIX}/n/.repo"
# To deal with possible CRLF issues (see below), suppress the normally automatich checkout (populating the working tree).
(( quiet )) || echo "-- Cloning $kN_REPO_URL to '$nRepoDir'..."
git clone --depth 1 --no-checkout --quiet "$kN_REPO_URL" "$nRepoDir/" >/dev/null || die "Aborting, because cloning n's GitHub repository into '$nRepoDir' failed."

(( quiet )) || echo "-- Running local n installation to '$nBinDir'..."
# Note: Since the user may have `core.autocrlf` set to `true` globaly, we must make sure that we turn it off for the `n` repo first.
#       Performing a checkout is only safe afterwards.
(cd "$nRepoDir" && git config core.autocrlf input && git checkout --quiet && PREFIX="$N_PREFIX" "$makeExe" install >/dev/null) || die "Aborting, because n's own installation procedure failed."

# Modify the relevant shell initialization file.
if (( $skipInitFileUpdate )); then

  initFile=
  (( quiet )) || cat <<EOF
-- NOTE: Skipping update of your shell initialization file, as requested.
   Add the following line (or your shell's equivalent) to your initialization
   file:
     $(getShellInitFileLine)
EOF

else 

  initFile=$(modifyShellInitFile) || die
  (( quiet )) || echo "-- Shell initialization file '$initFile' updated."

fi

# Download/copy the helper scripts.
#   Note that we do not abort on failing to download/copy them, because they
#   are not essential for operation.
(( quiet )) || echo "-- Installing helper scripts in '$nBinDir'..."

helpersCopiedLocally=0
if [[ -f ${BASH_SOURCE} ]]; then # running from a local script file

  # TRY to copy the helper scripts from the same location as this script, 
  # to ensure that they match in terms of behavior.
  # However, the helper scripts may not be there, if someone just downloaded
  # this script by itself - in that case we fall back on downloading from
  # GitHub below.

  (cd "$(dirname "$(rreadlink "$BASH_SOURCE")")" &&
    cp "${kHELPER_SCRIPTS[@]}" "$nBinDir/" &&
     { (( quiet )) || echo "(Helper scripts copied from '$PWD'.)"; }
  ) 2>/dev/null && helpersCopiedLocally=1

fi

if (( ! helpersCopiedLocally )); then  # Running from GitHub with `curl ... | bash`, or from a lone local copy of `n-install` without its helper scripts present.

  # Find a SHA-256 checksum utility and construct a verification command.
  shaSumVerifyCmd=
  [[ -n $(command -v sha256sum) ]] && shaSumVerifyCmd=( 'sha256sum' '-c' '--status' ) # Linux
  [[ -z $shaSumVerifyCmd && -n $(command -v shasum) ]] && shaSumVerifyCmd=( 'shasum' '-a' '256' '-c' '--status' ) # macOS

  # Download helper scripts from GitHub.
  if [[ -z $shaSumVerifyCmd ]]; then # No SHA checksum-verification utility found - this should not happen.

    warn - <<EOF
Skipping download of the following helper scripts, because no SHA
checksum-verification utility is available: ${kHELPER_SCRIPTS[@]} 
EOF

  else # SHA utility present, proceed with download.
    cd "$nBinDir" || die
      i=0
      for helperScript in "${kHELPER_SCRIPTS[@]}"; do  

        helperScriptUrl="${kHELPER_SCRIPT_URLS[i]}"
        # Note: The curl / wget command succeeds even if the target file doesn't exist, so we
        #       check the resulting file's 1st line for a shebang line to determine
        #       if a script was truly downloaded or not, and remove a download file
        #       that's not a script.
        [[ -n $(command -v curl) ]] &&
          downloadCmdArgs=( curl -sS "$helperScriptUrl" -O ) ||
          downloadCmdArgs=( wget --quiet "$helperScriptUrl" )
        "${downloadCmdArgs[@]}" && head -n 1 "$helperScript" | grep -q '^#!' && chmod +x "$helperScript" || {
          rm -f "$helperScript" || die
          warn - <<EOF
Failed to download helper script '$helperScriptUrl' to
'$nBinDir/$helperScript'.
For manual procedures, see $kTHIS_REPO_URL.
EOF
        }

        # Verify the checksum
        if [[ -f "$helperScript" ]]; then
          echo "${kSHA256_SUMS[i]}" | "${shaSumVerifyCmd[@]}" || {
            rm -f "$helperScript" || die
            warn - <<EOF
Helper script '$helperScript' was not installed, because its integrity could
not be verified (checksum verification failed).
EOF
          }
        fi

        (( ++i ))

      done
    cd - >/dev/null
  fi

fi

# At this point we consider installation of n itself successful, even if
# installation of Node.js versions below fails or is aborted.
# Therefore, we now deactivate the cleanup handler.
trap - "${sigs[@]}"

# Install the requested Node.js versions, if any.

toInstallCount=${#versionsToInstall[@]}
installedCount=0

if (( toInstallCount > 0 )); then

  (( quiet )) || echo "-- Installing the requested Node.js version(s)..."

  firstInstalledVerArgs=() i=0
  (( quiet )) && exec 3<&1 1> /dev/null  # suppress stdout from `n`
  for ver in "${versionsToInstall[@]}"; do
    (( quiet )) || echo "   $(( ++i )) of ${toInstallCount}: ${ver}..."
    (( quiet )) && args=( '-q' ) || args=()
    [[ $archOverride ]] && args+=( '-a' "$archOverride" )
    [[ $ver == 'io:'* ]] && args+=( io "${ver#io:}" ) || args+=( "$ver" )
    # Note: To be safe, we place $nBinDir FIRST in the path for this invocation.
    if PATH="$nBinDir:$PATH" N_PREFIX="$N_PREFIX" n "${args[@]}"; then
      (( ++installedCount == 1 )) && firstInstalledVerArgs=( "${args[@]}" )
    else
      warn "Failed to install version '$ver'."
    fi
  done
  (( quiet )) && exec 1>&3 3>&- # restore stdout

  # Activate the first successfully installed version (otherwise the last
  # version installed would be the active one).
  if (( installedCount > 1 )); then
     # Note that n uses the same syntax for installing and activating an installed version.
     PATH="$nBinDir:$PATH" N_PREFIX="$N_PREFIX" n "${firstInstalledVerArgs[@]}"|| warn "Failed to activate version '$ver'."
  fi

fi

# Report success and provide further instructions.
# !! Do not use unbalanced single quotes - such as an apostrophe - in the embedded
# !! here-docs below, as they inexplicably break the enclosing here-document in Bash 3.x.
(( quiet )) || cat <<EOF
=== n successfully installed.
$( (( installedCount > 0 )) && 
  echo "  The active Node.js version is: $("$nBinDir"/node --version)" ||
  echo "  Run \`n lts\` to install the latest LTS Node.js version."
)

  Run \`n -h\` for help.
  To update n later, run \`$kUPDATE_SCRIPT\`.
  To uninstall, run \`$kUNINSTALL_SCRIPT\`.

$( [[ -n $initFile ]] && cat <<EOF2 || cat <<EOF3
  IMPORTANT: OPEN A NEW TERMINAL TAB/WINDOW or run \`. ${initFile/#$HOME/~}\`
             before using n and Node.js.
EOF2
  IMPORTANT: Modify your shell initialization file as described above
             before using n and Node.js.
EOF3
)
===
EOF

exit 0
