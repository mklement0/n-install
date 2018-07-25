[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/mklement0/n-install/blob/master/LICENSE.md)

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

**Contents**

- [n-install &mdash; introduction](#n-install-&mdash-introduction)
- [Examples](#examples)
- [Installing n](#installing-n)
  - [Installation from GitHub](#installation-from-github)
  - [Manual installation](#manual-installation)
  - [Installation options](#installation-options)
- [Updating n](#updating-n)
  - [Manual updating](#manual-updating)
- [Uninstalling n](#uninstalling-n)
  - [Manual uninstallation](#manual-uninstallation)
- [License](#license)
  - [Acknowledgements](#acknowledgements)
  - [npm dependencies](#npm-dependencies)
- [Changelog](#changelog)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# n-install &mdash; introduction

**Installs [`n`](https://github.com/tj/n)**, the **[Node.js](https://nodejs.org/) version manager**, on Unix-like platforms, **without needing to install Node.js first**.  
Additionally, installs scripts `n-update` for later on-demand updating of `n`, and `n-uninstall` for uninstalling.

The simplest case is **installation of `n` with confirmation prompt**, with subsequent **installation of the latest LTS Node.js version**:

```shell
curl -L https://git.io/n-install | bash
```

This is by far **the simplest way to get started with both `n` and Node.js** - even if you're looking to install only the latest LTS (long-term support) Node.js version, with no (immediate) plans to install _multiple_ versions.

`n` is installed as follows:

* The installation target is a **dedicated directory**, which **defaults to `~/n`** and can be overridden with environment variable `N_PREFIX`; n itself as well as the active Node.js version are placed there.
    * When overriding, it is advisable to choose a user location - typically, a subfolder of `~` (at any level) - so as to avoid the need to use `sudo` for installation of global `npm` packages.
    * Either way, the target directory must either not exist yet or be empty.
    * Using a dedicated directory to hold both `n` and the Node.js versions greatly simplifies later uninstallation.
* If your shell is **`bash`, `ksh`, or `zsh`, the relevant shell initialization file is modified**:
    * Environment variable `N_PREFIX` is defined to point to the installation directory.
    * Directory `$N_PREFIX/bin` is appended to the `$PATH`, unless already present.
    * For other shells, these modification must be performed manually; instructions are provided during installation.
    * You can also explicitly suppress modification with the `-n` option.
* By default, the latest LTS Node.js version is installed; you can suppress that or even specify multiple Node.js versions to install.
* Note that any preexisting `n`, Node.js installation must be removed before using this installation method.
* All installation prerequisites are met by default on OSX and some Linux distros; notably, `git` and `curl` must be present - see [Installing n](#installing-n) for details.
* After installation, **be sure to open a new terminal tab or window or reload your shell initialization file** before attempting to use `n` / Node.js - see 
  
See examples [below](#examples), and [Installing n](#installing-n) for prerequisites and installation options.

# Examples

See [Installation options](#installation-options) for details.

<!-- ACTIVATE THIS ONCE n ITSELF SUPPORTS WGET
Note: The examples use only `curl` for brevity; to run a given command with `wget` instead, replace `curl -L` with `wget -qO-`.
-->

* Installation with confirmation prompt to default location `$HOME/n` and installation of the latest LTS Node.js version:

```shell
curl -L https://git.io/n-install | bash
```

* Automated installation to default location `$HOME/n` and installation of the latest LTS Node.js version:

```shell
curl -L https://git.io/n-install | bash -s -- -y
```

* Automated, _quiet_ installation to default location `$HOME/n` and installation of the latest LTS Node.js version; _no status information_
is displayed:

```shell
curl -sL https://git.io/n-install | bash -s -- -q
```

* Automated installation to the default location, with subsequent installation of the latest LTS
  (Long Term Support) version, and the latest 0.10.x release:

```shell
curl -L https://git.io/n-install | bash -s -- -y lts 0.10
```

* Automated installation to custom location `~/util/n`, with subsequent installation of the latest LTS Node.js version:

```shell
curl -L https://git.io/n-install | N_PREFIX=~/util/n bash -s -- -y
```

# Installing n

**Supported platforms and prerequisites**

Among the platforms supported by `n`, any Unix-like platform with the following is supported:

* [`bash`](http://www.gnu.org/software/bash/)
* [`curl`](http://curl.haxx.se/)
* [`git`](http://git-scm.com/)
* [GNU `make`](http://www.gnu.org/software/make/)

These prerequisites are met by default on OSX and on at least some Linux platforms.
What's missing from some by default is `git` and/or `curl`, which, however, are easy to install from the respective package managers (e.g., `sudo apt-get install git curl` on Debian, or `sudo yum install git` on Fedora).
`bash` and `curl` are required by `n` itself as well.

Irrespective of the installation method chosen below, no further steps are required if your default shell is either **Bash, Ksh, or Zsh**.  
For other shells, manual updating of the relevant initialization file is required; detailed instructions are provided during installation.

## Installation from GitHub

```shell
curl -L https://git.io/n-install | [N_PREFIX=<dir>] bash [-s -- [-y] [<version>...]]
```

See below for an explanation of the options; `-s --` is required by Bash itself in order to pass options through to the script piped from stdin.

**Before you can use `n` and any installed Node.js versions**, you must **open a new terminal tab/window _or_ reload your shell initialization file**.  
For instance, if your shell is Bash and you're on **Linux**, you'd use **`. ~/.bashrc`**; on **OSX**, you'd use **`. ~/.bash_profile`**;
the installer will tell you the specific file to reload on successful installation.  

_Caveat_: If you **reload the initialization file from a _script_** (rather than interactively) - so that you can make use of `n` or Node.js in the remainder of the script, e.g.,
in order to preinstall global npm packages - 
**make sure that you account for initialization files that prevent (re)sourcing from a _non-interactive_ shell**.  
For instance, **Debian** and **Ubuntu** come with a default `~/.bashrc` file that - needlessly - categorically prevents sourcing (loading) if the shell is not interactive, using the following line at the start of the script:  
`[ -z "$PS1" ] && return`  
To bypass that:

* In `bash`, precede the reload (sourcing) command with `set -i` to simulate an interactive environment:

          set -i       # turn on interactive mode
          . ~/.bashrc  # reload (source) the initialization file
          set +i       # turn interactive mode back off

* Alternatively, invoke your script as a whole with `bash --norc --noprofile -i <script>`, which processes it in interactive (`-i`) mode.
  * This would work analogously for `ksh` and `zsh` as well.


## Manual installation

* Download [this `bash` script](https://git.io/n-install) as `n-install`.
* Make it executable with `chmod +x`.
* Move or symlink it to a directory in your `$PATH`.
* Invoke `n-install` as detailed below.
* Open a new terminal tab/window or reload your shell initialization file before using `n` and any installed Node.js versions - see GitHub instructions above.

**Note**: Even when executing `n-install` locally, downloading from this repository
occurs; specifically, helper scripts `n-update` and `n-uninstall` are downloaded - see below.

## Installation options

<!-- DO NOT EDIT THE FENCED CODE BLOCK and RETAIN THIS COMMENT: The fenced code block below is updated by `make update-readme/release` with CLI usage information. -->

```nohighlight
$ n-install --help

SYNOPSIS
  n-install [-t] [-y|-q] [-n] [-a <arch>] [<version>...]

DESCRIPTION
  Directly installs n, the Node.js version manager, which bypasses the need to
  manually install a Node.js version first.

  Additionally, installs n-update for updating n,
  and n-uninstall for uninstallation.

  On successful installation of n, the specified Node.js <version>(s)
  are installed; by default, this is the latest LTS Node.js version.
  
  To opt out, specify '-' as the only version argument.

  Supported version specifiers:

  * lts    ... the LTS (long-term stability) version
  * latest ... the latest version available overall
  * otherwise, specify an explicit version number, such as '0.12' or '0.10.35'
  
  If multiple versions are specified, the first one will be made active.

  The default installation directory is:

    ~/n
  
  which can be overridden by setting environment variable N_PREFIX to an
  absolute path before invocation; either way, however, the installation
  directory must either not exist yet or be empty.

  If your shell is Bash, Ksh, or Zsh, the relevant initialization file will be
  modified so as to:
   - export environment variable $N_PREFIX to point to the installation dir.
   - ensure that the directory containing the n executable, $N_PREFIX/bin,
     is in the $PATH.
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

  For more information, see https://git.io/n-install-repo

PREREQUISITES
  bash ... to run this script and n itself.
  curl ... to download helper scripts from GitHub and run n itself.
  git ... to clone n's GitHub repository and update n later.
  GNU make ... to run n's installation procedure.
  
EXAMPLES
    # Install n and the latest LTS Node.js version, with 
    # interactive prompt:
  n-install 
    # Only test if installation to the specified location would work.
  N_PREFIX=~/util/n n-install -t
    # Automated installation of n, without installing Node.js
  n-install -y -
    # Automated installation of n, followed by automated installation
    # of the latest LTS and the latest-overall Node.js versions, as well
    # as the latest 0.8.x version.
  n-install -y lts latest 0.8
```

# Updating n

Run `n-update` on demand to update `n` itself to the latest version.  
`n-update -y` skips the confirmation prompt.

## Manual updating

If, for some reason, `n-update` doesn't work or isn't available, run the following to update `n`:

* `cd "$N_PREFIX/n/.repo" && git fetch --depth 1 --quiet && git reset --hard origin/master --quiet && PREFIX="$N_PREFIX" make install && cd -`

# Uninstalling n

Run `n-uninstall` to uninstall `n` as well as the Node.js versions that were installed with it.  
`n-uninstall -y` skips the confirmation prompt - **use with caution**.

## Manual uninstallation

If, for some reason, `n-uninstall` doesn't work, do the following:

* Remove the `N_PREFIX` environment-variable definition and associated `PATH` modification from your shell's initialization file.

* Remove the directory that `N_PREFIX` points to:
    * Be sure that that directory contains no content unrelated to `n` that you may want to preserve.
    * If `$N_PREFIX` is not defined, look in the default installation location, `~/n`.


<!-- DO NOT EDIT THE NEXT CHAPTER and RETAIN THIS COMMENT: The next chapter is updated by `make update-readme/release` with the contents of 'LICENSE.md'. ALSO, LEAVE AT LEAST 1 BLANK LINE AFTER THIS COMMENT. -->

# License

Copyright (c) 2015-2018 Michael Klement <mklement0@gmail.com> (http://same2u.net), released under the [MIT license](https://spdx.org/licenses/MIT#licenseText).

## Acknowledgements

This project gratefully depends on the following open-source components, according to the terms of their respective licenses.

[npm](https://www.npmjs.com/) dependencies below have optional suffixes denoting the type of dependency; the *absence* of a suffix denotes a required *run-time* dependency: `(D)` denotes a *development-time-only* dependency, `(O)` an *optional* dependency, and `(P)` a *peer* dependency.

<!-- DO NOT EDIT THE NEXT CHAPTER and RETAIN THIS COMMENT: The next chapter is updated by `make update-readme/release` with the dependencies from 'package.json'. ALSO, LEAVE AT LEAST 1 BLANK LINE AFTER THIS COMMENT. -->

## npm dependencies

* [doctoc (D)](https://github.com/thlorenz/doctoc)
* [json (D)](https://github.com/trentm/json)
* [replace (D)](https://github.com/harthur/replace)
* [semver (D)](https://github.com/npm/node-semver#readme)
* [tap (D)](https://github.com/isaacs/node-tap)
* [urchin (D)](https://github.com/tlevine/urchin)

<!-- DO NOT EDIT THE NEXT CHAPTER and RETAIN THIS COMMENT: The next chapter is updated by `make update-readme/release` with the contents of 'CHANGELOG.md'. ALSO, LEAVE AT LEAST 1 BLANK LINE AFTER THIS COMMENT. -->

# Changelog

Versioning complies with [semantic versioning (semver)](http://semver.org/).

<!-- NOTE: An entry template for a new version is automatically added each time `make version` is called. Fill in changes afterwards. -->

* **[v0.5.0](https://github.com/mklement0/n-install/compare/v0.4.1...v0.5.0)** (2018-07-25):
  * [breaking change] It is now the LTS version (long-term support, `lts`) version that is installed by default,
    because the previous default, `stable`, is obsolete and no longer meaningful: the minor
    version number being odd or even no longer carries meaning since Node.js embraced semantic versioning.
    See https://nodesource.com/blog/nodejs-is-semver/ and https://nodejs.org/en/blog/release/v6.0.0/#current-what-happened-to-stable.
    From now on, choose either `lts` for the latest LTS version or `latest` for the
    latest in-development version, which [Node.Js](https://nodejs.org/) now calls _current_.

* **[v0.4.1](https://github.com/mklement0/n-install/compare/v0.4.0...v0.4.1)** (2018-07-24):
  * Adds support for pass-thru option `-a <arch>`, so as to allow overriding the target architecture when installing
    the initial Node.js version(s) - implements [request #22](https://github.com/mklement0/n-install/issues/22).

* **[v0.4.0](https://github.com/mklement0/n-install/compare/v0.3.7...v0.4.0)** (2017-10-26):
  * [enhancement] The integrity of helper scripts `n-update` and `n-uninstall`, which are downloaded by `n-install` from
    this repo, is now verified via SHA-256 checksums embedded in `n-install`.

* **[v0.3.7](https://github.com/mklement0/n-install/compare/v0.3.6...v0.3.7)** (2017-10-25):
  * [doc] Clarified that even during local execution after having manually downloaded `n-install` helper scripts are downloaded from this repo.

* **[v0.3.6](https://github.com/mklement0/n-install/compare/v0.3.5...v0.3.6)** (2017-09-03):
  * [enhancement] Installation and updating of `n` now guards against unexpected core.autocrlf settings.
  * [enhancement] Status and error messages improved to consistently mention version spec. 'lts' 

* **[v0.3.5](https://github.com/mklement0/n-install/compare/v0.3.4...v0.3.5)** (2017-02-25):
  * [doc] Fixed manual `n` update instructions, added LTS version hints to CLI help.

* **[v0.3.4](https://github.com/mklement0/n-install/compare/v0.3.2...v0.3.3)** (2017-01-27):
  * [fix] for [#10](https://github.com/mklement0/n-install/issues/10): `n-update` could fail to update `n` due to how it updated the local
    copy of the `n` repo.  
    To update an already-installed copy of `n-update`, run the following:
      * `cd "$N_PREFIX/bin"`
      * `curl https://raw.githubusercontent.com/mklement0/n-install/stable/bin/n-update > n-update`
      * and then run `n-update` again.


* **[v0.3.3](https://github.com/mklement0/n-install/compare/v0.3.2...v0.3.3)** (2016-06-01):
  * [security] Switched to https:// URLs.

* **[v0.3.2](https://github.com/mklement0/n-install/compare/v0.3.1...v0.3.2)** (2016-02-20):
  * [enhancement] New option `-q` (quiet mode) skips prompts, like `-y`, and additionally suppresses all status output.

* **[v0.3.1](https://github.com/mklement0/n-install/compare/v0.3.0...v0.3.1)** (2016-02-05):
  * [optimization] `git clone` and `git pull` now use `--depth 1` to only get the latest
    revision of `n`, which is all that is needed; tip of the hat to @steelbrain.

* **[v0.3.0](https://github.com/mklement0/n-install/compare/v0.2.0...v0.3.0)** (2016-01-14):
  * [enhancement] Support for `n`'s symbolic `lts` version specifier that installs
    the latest LTS (Long Term Support) version.

* **[v0.2.0](https://github.com/mklement0/n-install/compare/v0.1.9...v0.2.0)** (2015-12-24):
  * [enhancement] New option `-n` allows suppressing modification of shell-initialization files, to allow for setups where
    all exports are "out-sourced" to an external file that is then sourced from the shell-initialization file; note that use of `-n`
    therefore requires performing the modifications _manually_. 

* **[v0.1.9](https://github.com/mklement0/n-install/compare/v0.1.8...v0.1.9)** (2015-12-18):
  * [fix] Runtime Bash version check fixed; verified to work on at least 3.1.x - unclear, how far back it'll work.

* **[v0.1.8](https://github.com/mklement0/n-install/compare/v0.1.7...v0.1.8)** (2015-12-18):
  * [enhancement] Added runtime check to ensure that the Bash version running `n-install` is 3.2 or higher.

* **[v0.1.7](https://github.com/mklement0/n-install/compare/v0.1.6...v0.1.7)** (2015-11-23):
  * [doc] Removed references to io.js, now the project has merged with Node.js.
  * [doc] Added better tip for simulating an interactive environment for reloading a Bash initialization file.

* **[v0.1.6](https://github.com/mklement0/n-install/compare/v0.1.5...v0.1.6)** (2015-10-08):
  * [doc] CLI usage-help corrections.

* **[v0.1.5](https://github.com/mklement0/n-install/compare/v0.1.4...v0.1.5)** (2015-08-09):
  * [doc] Improved post-installation instructions.

* **[v0.1.4](https://github.com/mklement0/n-install/compare/v0.1.3...v0.1.4)** (2015-07-27):
  * [enhancement] Success message now mentions manually re-sourcing the shell initialization file as an alternative to opening a new terminal tab/window.

* **[v0.1.3](https://github.com/mklement0/n-install/compare/v0.1.2...v0.1.3)** (2015-07-04):
  * [robustness] If `make` is found not to be _GNU_ `make`, an attempt is made to use `gmake` instead.
  * [doc] `--version` now also outputs the project's home URL; read-me improvements.

* **[v0.1.2](https://github.com/mklement0/n-install/compare/v0.1.1...v0.1.2)** (2015-06-21):
  * [doc] Examples revised.

* **[v0.1.1](https://github.com/mklement0/n-install/compare/v0.1.0...v0.1.1)** (2015-06-21):
  * [doc] Examples revised.

* **v0.1.0** (2015-06-20):
  * Initial release.
