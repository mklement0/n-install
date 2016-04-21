	# Since we rely on paths relative to the Makefile location, abort if make isn't being run from there.
$(if $(findstring /,$(MAKEFILE_LIST)),$(error Please only invoke this makefile from the directory it resides in))
	# Run all shell commands with bash.
SHELL := bash
	# Add the local npm packages' bin folder to the PATH, so that `make` can find them even when invoked directly (not via npm).
	# !! Note that this extended path only takes effect in (a) recipe commands that are (b) true shell commands (not optimized away) - when in doubt, simply append ';'
	# !! To also use the extended path in $(shell ...) function calls, use $(shell PATH="$(PATH)" ...),
export PATH := $(PWD)/node_modules/.bin:$(PATH)
	# Sanity check: git repo must exist.
$(if $(shell [[ -d .git ]] && echo ok),,$(error No git repo found in current dir. Please at least initialize one with 'git init'))
	# Sanity check: make sure dev dependencies (and npm) are installed - skip this check only for certain generic targets (':' is the pseudo target used by the `list` target's recipe.)
$(if $(or $(shell [[ '$(MAKECMDGOALS)' =~ list|: ]] && echo ok), $(shell [[ -d ./node_modules/semver ]] && echo 'ok')),,$(error Did you forget to run `npm install` after cloning the repo (Node.js must be installed)? At least one of the required dev dependencies not found))
	# Determine the editor to use for modal editing. Use the same as for git, if configured; otherwise $EDITOR, then fall back to vi (which may be vim).
EDITOR := $(shell git config --global --get core.editor || echo "$${EDITOR:-vi}")

	# Default target (by virtue of being the first non '.'-prefixed target in the file).
.PHONY: _no-target-specified
_no-target-specified:
	$(error Please specify the target to make - `make list` shows targets. Alternatively, use `npm test` to run the default tests; `npm run` shows all commands)

# Lists all targets defined in this makefile.
.PHONY: list
list:
	@$(MAKE) -pRrn -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | grep -Ev -e '^[^[:alnum:]]' -e '^$@$$' | sort

# Open this package's online repository URL (typically, on GitHub) in the default browser.
# Note: Supported on OSX and Freedesktop-compliant systems, which includes many Linux and BSD variants.
.PHONY: browse
browse:
	@exe=; url=`json -f package.json repository.url` || exit; \
	 [[ `uname` == 'Darwin' ]] && exe='open'; \
	 [[ -n `command -v xdg-open` ]] && exe='xdg-open'; \
	 [[ -n $$exe ]] || { echo "Don't know how to open $$url in the default browser on this platform." >&2; exit 1; }; \
	 "$$exe" "$$url"

# Open this package's page in the npm registry.
# Note: Supported on OSX and Freedesktop-compliant systems, which includes many Linux and BSD variants.
.PHONY: browse-npm
browse-npm:
	@exe=; [[ `json -f package.json private` == 'true' ]] && { echo "This package is marked private (not for publication in the npm registry)." >&2; exit 1; }; \
	 url="https://www.npmjs.com/package/`json -f package.json name`" || exit; \
	 [[ `uname` == 'Darwin' ]] && exe='open'; \
	 [[ -n `command -v xdg-open` ]] && exe='xdg-open'; \
	 [[ -n $$exe ]] || { echo "Don't know how to open $$url in the default browser on this platform." >&2; exit 1; }; \
	 "$$exe" "$$url"

.PHONY: test
# To optionally skip tests in the context of target 'release', for instance, invoke with NOTEST=1; e.g.: make release NOTEST=1
test:
ifeq ($(NOTEST),1)
	@echo Note: Skipping tests, as requested. >&2
else
	@exists() { [ -e "$$1" ]; }; exists ./test/* || { echo "(No tests defined.)" >&2; exit 0; }; \
	 if [[ -n $$(json -f package.json main) ]]; then tap ./test; else urchin ./test; fi
endif

# Commits (with prompt for message) and pushes to the branch of the same name in remote repo 'origin', 
# but *without* tags, so as to allow quick pushing of changes without running into problems with tag redefinitions.
# (Tags are only pushed - forcefully - with `make release`.)
.PHONY: push
push: _need-clean-ws-or-no-untracked-files
	@[[ -z $$(git status --porcelain || echo no) ]] && echo "-- (Nothing to commit.)" || { git commit || exit; echo "-- Committed."; }; \
	 targetBranch=`git symbolic-ref --short HEAD` || exit; \
	 git push origin "$$targetBranch" || exit; \
	 echo "-- Pushed."


# Reports the current version number - both from package.json and as defined by the latest git tag
# Implementation note: simply uses 'version' as a prerequisite, which queries $(MAKECMDGOALS) to adjust its behavior based on the caller.
.PHONY: verinfo
verinfo: version

# Increments the package's version number:
# Unless called via 'make verinfo', the workspace must be clean or at least have no untracked files.
# If VER is *not* specified in the environment:
#   Reports the current version number - both from package.json and as defined by the latest git tag.
#   If 'make version' was called directly, then prompts to change the version number.
#   If called via 'make release', only prompts to change the version number if the git tag version number is the same as the package's.
#   VER is set to the value entered and processing continues below.
# If VER *is* specified or continuing from above:
#   Validates the new version number:
#      If an increment specifier was given, increments from the latest package.json version number (as the version numbers stored in source files are assumed to be in sync with package.json).
#      	 Implementation note: semver, as of v4.3.6, does not validate increment specifiers and simply defaults to 'patch' in case of an valid specifier; thus, we roll our own validation here.
#      An increment specifier starting with 'pre' increments [to] a prerelease version number. By default, this simply appends or increments '-<num>', whereas '--preid <id>' can be used
#      to append '-<id><num>' instead; however, we don't expose that, at least for now, though the user may specify an explicit, full pre-release version number.
#      We use tag 'pre' with npm publish --tag, so as to have the latest prerelease be installable with <pkg>@pre, analogous to the (implicit) 'latest' tag that tracks production releases.
#      An explicitly specified version number must be *higher* than the current one; pass variable FORCE=1 to override this in exceptional situations.
#   Updates the version number in package.json and in source files in ./bin and ./lib.
.PHONY: version
version:
	@[[ '$(MAKECMDGOALS)' == *verinfo* ]] && infoOnly=1 || infoOnly=0; \
	 gitTagVer=`git describe --abbrev=0 --match 'v[0-9]*.[0-9]*.[0-9]*' 2>/dev/null || echo '(none)'` || exit; gitTagVer=$${gitTagVer#v}; \
	 pkgVer=`json -f package.json version` || exit; \
	 if [[ -z $$VER ]]; then \
	  printf 'CURRENT version:\n\t%s (package.json)\n\t%s (git tag)\n' "$$pkgVer" "$$gitTagVer"; \
	  (( infoOnly )) && exit; \
	  [[ $$pkgVer != "$$gitTagVer" && $$pkgVer != '0.0.0' ]] && { alreadyBumped=1 || alreadyBumped=0; }; \
	  if [[ '$(MAKECMDGOALS)' == 'release' && $$alreadyBumped -eq 1 ]]; then \
	    printf "=== `[[ $$pkgVer == *-* ]] && printf 'PRE-'`RELEASING:\n\t%s -> **%s** \n===\n" "$$gitTagVer" "$$pkgVer"; \
	    read -p '(Y)es or (c)hange (y/c/N)?: ' -re response && [[ "$$response" == [yYcC] ]] || { echo 'Aborted.' >&2; exit 2; }; \
	    [[ $$response =~ [yY] ]] && exit 0; \
	    alreadyBumped=0; \
	  fi; \
	  if [[ '$(MAKECMDGOALS)' == 'version' || $$alreadyBumped -eq 0 ]]; then \
	    echo "==="; \
	    echo "Enter new version number in full or as one of: 'patch', 'minor', 'major', optionally prefixed with 'pre', or 'prerelease'."; \
	    echo "(Alternatively, pass a value from the command line with 'VER=<new-ver>'.)"; \
	    read -p "NEW VERSION number (just Enter to abort)?: " -re VER && { [[ -z $$VER ]] && echo 'Aborted.' >&2 && exit 2; }; \
	  fi; \
	fi; \
  oldVer=$$pkgVer; \
  newVer=$${VER#v}; \
  if printf "$$newVer" | grep -q '^[0-9]'; then \
    semver "$$newVer" >/dev/null || { echo "Invalid semver version number specified: $$VER" >&2; exit 2; }; \
    [[ "$(FORCE)" != '1' ]] && { semver -r "> $$oldVer" "$$newVer" >/dev/null || { echo "Invalid version number specified: $$VER - must be HIGHER than $$oldVer. To force this change, use FORCE=1 on the command line." >&2; exit 2; }; } \
  else \
    [[ $$newVer =~ ^(patch|minor|major|prepatch|preminor|premajor|prerelease)$$ ]] && newVer=`semver -i "$$newVer" "$$oldVer"` || { echo "Invalid version-increment specifier: $$VER" >&2; exit 2; } \
  fi; \
  printf "=== About to BUMP VERSION:\n\t$$oldVer -> **$$newVer**\n===\nProceed (y/N)?: " && read -re response && [[ "$$response" = [yY] ]] || { echo 'Aborted.' >&2; exit 2; };  \
  for dir in ./bin ./lib; do [[ -d $$dir ]] && { replace --quiet --recursive "v$${oldVer//./\\.}" "v$${newVer}" "$$dir" || exit; }; done; \
  [[ `json -f package.json version` == "$$newVer" ]] || { npm version $$newVer --no-git-tag-version >/dev/null && printf $$'\e[0;33m%s\e[0m\n' 'package.json' || exit; }; \
  [[ $$gitTagVer == '(none)' ]] && newVerMdSnippet="**v$$newVer**" || newVerMdSnippet="**[v$$newVer](`json -f package.json repository.url | sed 's/.git$$//'`/compare/v$$gitTagVer...v$$newVer)**"; \
  grep -Eq "\bv$${newVer//./\.}[^[:digit:]-]" CHANGELOG.md || { { sed -n '1,/^<!--/p' CHANGELOG.md && printf %s $$'\n* '"$$newVerMdSnippet"$$' ('"`date +'%Y-%m-%d'`"$$'):\n  * ???\n' && sed -n '1,/^<!--/d; p' CHANGELOG.md; } > CHANGELOG.tmp.md && mv CHANGELOG.tmp.md CHANGELOG.md; }; \
  printf -- "-- Version bumped to v$$newVer in source files and package.json (only just-now updated files were printed above, if any).\n   Describe changes in CHANGELOG.md ('make release' will prompt for it).\n   To update the read-me file, run 'make update-readme' (also happens during 'make release').\n"

# make release [VER=<newVerSpec>] [NOTEST=1]
# Increments the version number, runs tests, then commits and tags, pushes to origin, prompts to publish to the npm-registry; NOTEST=1 skips tests.
# VER=<newVerSpec> is mandatory, unless the version number in package.json is ahead of the latest Git version tag.
.PHONY: release
release: _need-origin _need-npm-credentials _need-master-branch _need-clean-ws-or-no-untracked-files version test
	@newVer=`json -f package.json version` || exit; [[ $$newVer == *-* ]] && isPreRelease=1 || isPreRelease=0; \
	 echo '-- Opening changelog...'; \
	 $(EDITOR) CHANGELOG.md; \
	 changelogEntries=`sed -En -e '/\*\*\[?'"v$$newVer"'(\*|\])/,/^\* / { s///; t' -e 'p; }' CHANGELOG.md`; \
	 [[ -n $$changelogEntries ]] || { echo "ABORTED: No changelog entries provided for new version v$$newVer." >&2; exit 2; }; \
	 commitMsg="v$$newVer"$$'\n'"$$changelogEntries"; \
	 echo "-- Updating documentation, if applicable..."; \
	 $(MAKE) -f $(lastword $(MAKEFILE_LIST)) update-doc || exit; \
	 echo "-- Updating README.md..."; \
	 $(MAKE) -f $(lastword $(MAKEFILE_LIST)) update-license-year update-readme || exit; \
	 echo '-- Opening README.md for final inspection...'; \
	 $(EDITOR) README.md; \
	 grep -E '(^|[[:blank:]])\?\?\?([[:blank:]]|$$)' README.md && { echo "ABORTED: README.md still contains '???', the placeholder for missing information." >&2; exit 2; }; \
	 read -re -p "Ready to COMMIT, TAG, PUSH$$([[ `json -f package.json private` != 'true' ]] && echo ", and PUBLISH (prompted for separately)") (y/N)?: " response && [[ "$$response" =~ [yY] ]] || { echo 'Aborted.' >&2; exit 2; }; \
	 echo '-- Committing...'; \
	 git add --update . || exit; \
	 [[ -z $$(git status --porcelain || echo no) ]] && echo "-- (Nothing to commit.)" || { git commit -m "$$commitMsg" || exit; echo "-- v$$newVer committed."; }; \
	 git tag -f -a -m "$$commitMsg" "v$$newVer" || exit; { git tag -f "`(( isPreRelease )) && printf 'pre' || printf 'stable'`" || exit; }; \
	 echo "-- Tag v$$newVer created."; \
	 git push origin master || exit; git push -f origin master --tags; \
	 echo "-- v$$newVer pushed to origin."; \
	 if [[ `json -f package.json private` != 'true' ]]; then \
	 		latestPreReleaseTag='pre'; \
	 		printf "=== About to PUBLISH TO npm REGISTRY as `(( isPreRelease )) && printf 'PRE-RELEASE' || printf 'LATEST'` version:\n\t**`json -f package.json name`@$$newVer**\n===\nType 'publish' to proceed; anything else to abort: " && read -er response; \
	 		[[ "$$response" == 'publish' ]] || { echo 'Aborted. Run `npm publish` on demand.' >&2; exit 2; };  \
	 		{ (( isPreRelease )) && npm publish --tag "$$latestPreReleaseTag" || npm publish; } || exit; \
	 		echo "-- Published to npm`(( isPreRelease )) && printf " and tagged with '$$latestPreReleaseTag' to mark the latest pre-release"`."; \
	 else \
	 		echo "-- (Package marked as private; not publishing to npm registry.)"; \
	 fi; \
	 echo "-- Done."

# Updates README.md as follows:
#  - Replaces the '## Usage' chapter with the command-line help output by this package's CLI, if applicable.
#  - Replaces the '### License' chapter with the contents of LICENSE.md
#  - Replaces the '### npm Dependencies' chapter with the current list of dependencies.
#  - Replaces the '## Changelog' chapter with the contents of CHANGELOG.md
#  - Finally, places an auto-generated TOC at the top, if configured.
.PHONY: update-readme
update-readme: _update-readme-usage _update-readme-license _update-readme-dependencies _update-readme-changelog update-toc
	@[[ '$(MAKECMDGOALS)' == 'update-readme' ]] && grep -E '(^|[[:blank:]])\?\?\?([[:blank:]]|$$)' README.md && echo "WARNING: README.md still contains '???', the placeholder for missing information." >&2; \
	 echo "-- README.md updated."

# If turned on: Updates the TOC in README.md - there is *generally* no need to call this *directly*, because the TOC is updated as part of the 'update-readme' target and, indirectly, the 'release' target.
# If this feature is turned off, this is a no-op.
# !! Note that a \n is prepended to the title to work around a npmjs.com rendering bug: without it, doctoc's comments would directly abut the title, which unexepctedly disables Markdown rendering (as of 31 May 2015).
.PHONY: update-toc
update-toc:
	@[[ `json -f package.json net_same2u.make_pkg.tocOn` == 'true' ]] || { [[ '$(MAKECMDGOALS)' == 'update-toc' ]] && echo "WARNING: TOC generation is currently turned OFF. Use 'make toggle-toc' to activate." >&2; exit 0; }; \
	 doctoc --title $$'\n'"`json -f package.json net_same2u.make_pkg.tocTitle`" README.md >/dev/null || exit; \
	 [[ '$(MAKECMDGOALS)' == 'update-toc' ]] && echo "-- TOC in README.md updated." || :; \

# Note: For now, generating documentation is only supported for CLIs.
.PHONY: update-doc
update-doc: update-man

# If turned on: Extracts the Markdown-formatted man-page source assumed to be output by this package's CLI 
# with --man-source and:
#  - creates a man page (in ROFF format) in ./man/<cli>.1 with marked-man
#  - extracts the Markdown source to ./doc/<cli>.md.
# If this package has no CLI or the feature is turned off, this is a no-op.
.PHONY: update-man
update-man: 
	@read -r cliName cliPath < <(json -f package.json bin | json -Ma key value | head -n 1) || { [[ '$(MAKECMDGOALS)' == 'update-man' ]] && echo "WARNING: Nothing to do; no CLI is defined for this package." >&2; exit 0; }; \
	 [[ `json -f package.json net_same2u.make_pkg.manOn` == 'true' ]] || { [[ '$(MAKECMDGOALS)' == 'update-man' ]] && echo "WARNING: man-page creation is currently turned OFF. Use 'make toggle-man' to activate." >&2; exit 0; }; \
	 ver='v'$$(json -f package.json version) || exit; \
	 mkdir -p doc man; \
	 printf '<!-- DO NOT EDIT THIS FILE: It is auto-generated by `make update-man` -->\n\n' > doc/"$$cliName".md; \
	 "$$cliPath" --man-source >> doc/"$$cliName".md || { printf "ERROR: Failed to extract man-page source.\nPlease ensure that '$$cliName --man-source' outputs the Markdown-formatted man-page source.\n" | fold -s >&2; exit 1; }; \
	 "$$cliPath" --man-source | marked-man --version "$$ver" > man/"$$cliName".1 || { echo "Do you need to install marked-man (npm install marked-man --save-dev)?" | fold -s >&2; exit 1; }; \
	 [[ '$(MAKECMDGOALS)' == 'update-man' ]] && echo "-- 'doc/$$cliName.md' and 'man/$$cliName.1' updated."$$'\n'"To view the latter as a man page, run: man man/$$cliName.1"$$'\n'"To update and view in one step, run: make view-man" || :

# If man-page creation is turned on: recreate the man page and view it with `man`.
.PHONY: view-man
view-man: update-man
	@manfile=`json -f package.json man`; [[ -n $$manfile ]] || { echo "ERROR: No 'man' property found in 'package.json'." >&2; exit 2; }; \
	 man "$$manfile"

# Toggles inclusion of an auto-updating TOC in README.md via doctoc.
.PHONY: toggle-toc
toggle-toc:
	@isOn=$$([[ `json -f package.json net_same2u.make_pkg.tocOn` == 'true' ]] && printf 1 || printf 0); \
	 nowState=`(( isOn )) && printf 'ON' || printf 'OFF'`; otherState=`(( isOn )) && printf 'OFF' || printf 'ON'`; \
	 echo "Inclusion of an auto-updating TOC for README.md is currently $$nowState."; \
	 read -re -p "Turn it $$otherState (y/N)?: " response && [[ "$$response" =~ [yY] ]] || { exit 0; }; \
	 json -I -f package.json -e 'this.net_same2u || (this.net_same2u  = {}); this.net_same2u.make_pkg || (this.net_same2u.make_pkg = {}); this.net_same2u.make_pkg.tocOn = '`(( isOn )) && printf 'false' || printf 'true'`'; this.net_same2u.make_pkg.tocTitle || (this.net_same2u.make_pkg.tocTitle = "**Contents**")' || exit; \
	 if (( isOn )); then \
	 	 echo "NOTE: To be safe, no attempt was made to remove any existing TOC from README.md, if present." | fold -s >&2; \
	 else \
	 	 echo "-- Automatic TOC generation for README.md activated."; \
	 	 printf "Run 'make update-toc' to insert a TOC now.\n'make update-readme' and 'make release' will now update it automatically.\n" | fold -s; \
	 fi

# Toggles generation of a man page via marked-man, based on a Markdown-formatted document
# that the package's CLI must output with --man-source.
.PHONY: toggle-man
toggle-man:
	@isOn=$$([[ `json -f package.json net_same2u.make_pkg.manOn` == 'true' ]] && printf 1 || printf 0); \
	 nowState=`(( isOn )) && printf 'ON' || printf 'OFF'`; otherState=`(( isOn )) && printf 'OFF' || printf 'ON'`; \
	 echo "Generating a man page for this package's CLI is currently $$nowState."; \
	 read -re -p "Turn it $$otherState (y/N)?: " response && [[ "$$response" =~ [yY] ]] || { exit 0; }; \
	 if (( ! isOn )); then \
	 	 read -r cliName cliPath < <(json -f package.json bin | json -Ma key value | head -n 1); \
	 	 [[ -n $$cliName ]] || { echo "ERROR: No CLI declared in 'package.json'; please declare a CLI via the 'bin' property and try again." | fold -s >&2; exit 1; }; \
	 fi; \
	 json -I -f package.json -e 'this.net_same2u || (this.net_same2u = {}); this.net_same2u.make_pkg || (this.net_same2u.make_pkg = {}); this.net_same2u.make_pkg.manOn = '`(( isOn )) && printf 'false' || printf 'true'` || exit; \
	 if (( isOn )); then \
	 	 echo "-- Man-page creation is now OFF."; \
	 	 echo "NOTE: To be safe, a 'man' property, if present, was not removed from 'package.json', and no attempt was made to uninstall the 'marked-man' package, if present. Please make required changes manually." | fold -s >&2; \
	 else \
	 	 [[ -n `json -f package.json devDependencies.marked-man` ]] || { echo "-- Installing marked-man as a dev. dependency..."; npm install --save-dev marked-man || exit; }; \
	 	 [[ -n `json -f package.json man` ]] && { echo "NOTE: Retaining existing 'man' property in 'package.json'." >&2; } || \
	 	                                        { json -I -f package.json -e "this.man = \"./man/$$cliName.1\"" || exit; }; \
	 	 echo "-- Man-page creation is now ON."; echo "Run 'make update-man' to generate the man page now."$$'\n'"Note that '$$cliName --man-source' must output the man-page source in Markdown format for this to work." | fold -s; \
	 fi


# Updates LICENSE.md if the stated calendar year (e.g., '2015') / the end point in a calendar-year range (e.g., '2014-2015')
# lies in the past; E.g., if the current calendary year is 2016, the first example is updated to '2015-2016', and the second
# one to '2014-2016'.
.PHONY: update-license-year
update-license-year:
	@f='LICENSE.md'; thisYear=`date +%Y`; yearRange=`sed -n 's/.*(c) \([0-9]\{4\}\)\(-[0-9]\{4\}\)\{0,1\}.*/\1\2/p' "$$f"`; \
	 [[ -n $$yearRange ]] || { echo "Failed to extract calendar year(s) from '$$f'." >&2; exit 1; }; laterYear=$${yearRange#*-}; \
   if (( laterYear < thisYear )); then \
     replace -s '(\(c\) )([0-9]{4})(-[0-9]{4})?' '$$1$$2-'"$$thisYear" "$$f" || exit; \
     echo "NOTE: '$$f' updated to reflect current calendar year, $$thisYear."; \
   elif [[ '$(MAKECMDGOALS)' == 'update-license-year' ]]; then \
   	 echo "('$$f' calendar year(s) are up-to-date: $$yearRange)"; \
   fi

# --------- Aux. targets

# If applicable, replaces the usage read-me chapter with the current CLI help output, 
# enclosed in a fenced codeblock and preceded by '$ <cmd> --help'.
# Replacement is attempted if the project at hand has a (at least one) CLI, as defined in the 'bin' key in package.json.
# is an *object* that has (at least 1) property (rather than containing a string-scalar value that implies the package name as the CLI name).
#  - If 'bin' has *multiple* properties, the *1st* is the one whose usage info is to be used.
#    To change this, modify CLI_HELP_CMD in the shell command below.
.PHONY: _update-readme-usage
# The arguments to pass to the CLI to have it output its help.
CLI_HELP_ARGS:= --help
# Note that the recipe exits right away if no CLIs are found in 'package.json'.
# TO DISABLE THIS RULE, REMOVE ALL OF ITS RECIPE LINES.
_update-readme-usage:
	@read -r cliName cliPath < <(json -f package.json bin | json -Ma key value | head -n 1) || exit 0; \
	 CLI_HELP_CMD=( "$$cliPath" $(CLI_HELP_ARGS) ); \
	 CLI_HELP_CMD_DISPLAY=( "$${CLI_HELP_CMD[@]}" ); CLI_HELP_CMD_DISPLAY[0]="$$cliName"; \
	 newText="$${CLI_HELP_CMD_DISPLAY[@]}"$$'\n\n'"$$( "$${CLI_HELP_CMD[@]}" )" || { echo "Failed to update read-me chapter: usage: invoking CLI help failed: $${CLI_HELP_CMD[@]}" >&2; exit 1; }; \
	 newText="$${newText//\$$/$$\$$}"; \
	 newText="$${newText//~/\~}"; \
	 replace --count --quiet --multiline=false '(\n)(<!-- DO NOT EDIT .*usage.*?-->\n\s*?\n```nohighlight\n\$$ )[\s\S]*?(\n```\n|$$)' '$$1$$2'"$$newText"'$$3' README.md | grep -Fq ' (1)' || { echo "Failed to update read-me chapter: usage." >&2; exit 1; }
# !! REGRETTABLY, the ``` sequences in the line above break syntax coloring for the rest of the file in Sublime Text 3 - ?? unclear, how to work around that.

#  - Replaces the '## License' chapter with the contents of LICENSE.md
.PHONY: _update-readme-license
# TO DISABLE THIS RULE, REMOVE ALL OF ITS RECIPE LINES.
_update-readme-license:
	@newText=$$'\n'"$$(< LICENSE.md)"$$'\n'; \
	 newText="$${newText//\$$/$$\$$}"; \
	 replace --count --quiet --multiline=false '(^|\n)(#+ License\n)[\s\S]*?(\n([ \t]*<!-- .*? -->\s*?\n)?#|$$)' '$$1$$2'"$$newText"'$$3' README.md | grep -Fq ' (1)' || { echo "Failed to update read-me chapter: license." >&2; exit 1; }

#  - Replaces the dependencies chapter with the current list of dependencies.
.PHONY: _update-readme-dependencies
# A regex that matches the chapter heading to replace in README.md; watch for unintentional trailing whitespace. '#' must be represented as '\#'.
README_HEADING_DEPENDENCIES := \#+ npm dependencies
# TO DISABLE THIS RULE, REMOVE ALL OF ITS RECIPE LINES.
_update-readme-dependencies:
	@newText=$$'\n'$$( \
	 keys=( dependencies peerDependencies devDependencies  optionalDependencies ); \
	 qualifiers=( ''     '(P)'            '(D)'            '(O)'); \
	 i=0; \
	 for key in "$${keys[@]}"; do \
	 json -f ./package.json $$key | json -ka | { \
	   while read -r pn; do \
	     hp=$$(json -f "./node_modules/$$pn/package.json" homepage); \
	     echo "* [$$pn$${qualifiers[i]:+ $${qualifiers[i]}}]($$hp)"; \
	   done \
	 }; \
	 (( ++i )); \
	 done)$$'\n'; \
	 [[ -n $$newText ]] || { echo "Failed to determine npm dependencies." >&2; exit 1; }; \
	 newText="$${newText//\$$/$$\$$}"; \
	 replace --count --quiet --multiline=false '(^|\n)($(README_HEADING_DEPENDENCIES)\n)[\s\S]*?(\n([ \t]*<!-- .*? -->\s*?\n)?#|$$)' '$$1$$2'"$$newText"'$$3' README.md | grep -Fq ' (1)' || { echo "Failed to update read-me chapter: npm dependencies." >&2; exit 1; }

#  - Replaces the changelog chapter with the contents of CHANGELOG.md
.PHONY: _update-readme-changelog
# A regex that matches the chapter heading to replace in README.md; watch for unintentional trailing whitespace. '#' must be represented as '\#'.
README_HEADING_CHANGELOG := \#+ Changelog
# TO DISABLE THIS RULE, REMOVE ALL OF ITS RECIPE LINES.
_update-readme-changelog:
	@newText=$$'\n'"$$(tail -n +3 CHANGELOG.md)"$$'\n'; \
	 newText="$${newText//\$$/$$\$$}"; \
	 replace --count --quiet --multiline=false '(^|\n)($(README_HEADING_CHANGELOG)\n)[\s\S]*?(\n([ \t]*<!-- .*? -->\s*?\n)?#|$$)' '$$1$$2'"$$newText"'$$3' README.md | grep -Fq ' (1)' || { echo "Failed to update read-me chapter: changelog." >&2; exit 1; }

.PHONY: _need-master-branch
_need-master-branch:
	@[[ `git symbolic-ref --short HEAD` == 'master' ]] || { echo 'Please release from the master branch only.' >&2; exit 2; }

# Ensures that the git workspace is clean or contains no untracked files - any tracked files are implicitly added to the index.
.PHONY: _need-clean-ws-or-no-untracked-files
_need-clean-ws-or-no-untracked-files:
	@git add --update . || exit
	@[[ -z $$(git status --porcelain | awk -F'\0' '$$2 != " " { print $$2 }') ]] || { echo "Workspace must either be clean or contain no untracked files; please add untracked files to the index first (e.g., \`git add .\`) or delete them." >&2; exit 2; }

# Ensure that a remote git repo named 'origin' is defined.
.PHONY: _need-origin
_need-origin:
	@git remote | grep -Fqx 'origin' || { echo "ERROR: Remote git repo 'origin' must be defined." >&2; exit 2; }

# Unless the package is marked private, ensure that npm credentials have been saved.
.PHONY: _need-npm-credentials
_need-npm-credentials:
	@[[ `json -f package.json private` == 'true' ]] && exit 0; \
	 grep -Eq '^//registry.npmjs.org/:(_password|_authToken)=' ~/.npmrc || { echo "ERROR: npm-registry credentials not found. Please log in with 'npm login' in order to enable publishing." >&2; exit 2; }; \
