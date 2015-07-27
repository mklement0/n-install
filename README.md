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

**Installs [`n`](https://github.com/tj/n)**, the **[Node.js](https://nodejs.org/) and [io.js](https://iojs.org/) version manager**, on Unix-like platforms, **without needing to install Node.js or io.js first**.  
Additionally, installs scripts `n-update` for later on-demand updating of `n`, and `n-uninstall` for uninstalling.

The simplest case is **installation of `n` with confirmation prompt**, with subsequent **installation of the latest stable Node.js version**:

```shell
curl -L http://git.io/n-install | bash
```

This is by far **the simplest way to get started with both `n` and Node.js** - even if you're looking to install only the latest stable Node.js version, with no (immediate) plans to install _multiple_ versions.

`n` is installed as follows:

* The installation target is a **dedicated directory**, which **defaults to `~/n`** and can be overridden with environment variable `N_PREFIX`; n itself as well as the active Node.js/io.js version are placed there.
    * When overriding, it is advisable to choose a user location - typically, a subfolder of `~` (at any level) - so as to avoid the need to use `sudo` for installation of global `npm` packages.
    * Either way, the target directory must either not exist yet or be empty.
    * Using a dedicated directory to hold both `n` and the Node.js/io.js versions greatly simplifies later uninstallation.
* If your shell is **`bash`, `ksh`, or `zsh`, the relevant shell initialization file is modified**:
    * Environment variable `N_PREFIX` is defined to point to the installation directory.
    * Directory `$N_PREFIX/bin` is appended to the `$PATH`, unless already present.
    * For other shells, these modification must be performed manually; instructions are provided during installation.
* By default, the latest stable Node.js version is installed; you can suppress that or even specify multiple Node.js/io.js versions to install.

<!-- ACTIVATE THIS ONCE n ITSELF SUPPORTS WGET
```shell
# Platforms with `curl`:
curl -L http://git.io/n-install | bash

# Platforms with `wget`:
wget -qO- http://git.io/n-install | bash
``` -->

* Note that any preexisting `n`, Node.js, or io.js installation must be removed before using this installation method.
* All installation prerequisites are met by default on OSX and some Linux distros; notably, `git` and `curl` must be present - see [Installing n](#installing-n) for details.
* After installation, **be sure to open a new terminal tab or window** before attempting to use `n` / Node.js / io.js.

See examples [below](#examples), and [Installing n](#installing-n) for prerequisites and installation options.

# Examples

See [Installation options](#installation-options) for details.

<!-- ACTIVATE THIS ONCE n ITSELF SUPPORTS WGET
Note: The examples use only `curl` for brevity; to run a given command with `wget` instead, replace `curl -L` with `wget -qO-`.
-->

* Installation with confirmation prompt to default location `$HOME/n` and installation of the latest stable Node.js version:

```shell
curl -L http://git.io/n-install | bash
```

* Automated installation to default location `$HOME/n` and installation of the latest stable Node.js version:

```shell
curl -L http://git.io/n-install | bash -s -- -y
```

* Automated installation to the default location, with subsequent installation of the latest stable Node.js and io.js versions, as well as the latest 0.10.x Node.js version:

```shell
curl -L http://git.io/n-install | bash -s -- -y stable io:stable 0.10
```

* Automated installation to custom location `~/util/n`, with subsequent installation of the latest stable Node.js version:

```shell
curl -L http://git.io/n-install | N_PREFIX=~/util/n bash -s -- -y
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
`bash` and `curl` are also required by `n` itself.

Irrespective of the installation method chosen below, no further steps are required if your default shell is either **Bash, Ksh, or Zsh**.  
For other shells, manual updating of the relevant initialization file is required; detailed instructions are provided during installation.


## Installation from GitHub

```shell
curl -L http://git.io/n-install | [N_PREFIX=<dir>] bash [-s -- [-y] [version...]]
```

After installation, a new terminal window must be opened before using `n` and any installed Node.js / io.js versions.

<!-- ACTIVATE THIS ONCE n ITSELF SUPPORTS wget
**With `curl`:**

```shell
curl -L http://git.io/n-install | [N_PREFIX=<dir>] bash [-s -- [-y] [version...]]
```

**With `wget`:**

```shell
wget -qO- http://git.io/n-install | [N_PREFIX=<dir>] bash [-s -- [-y] [version...]]
```
-->

See below for an explanation of the options; `-s --` is required by Bash itself in order to pass options through to the script piped from stdin.

## Manual installation

* Download [this `bash` script](http://git.io/n-install) as `n-install`.
* Make it executable with `chmod +x`.
* Move or symlink it to a directory in your `$PATH`.
* Invoke `n-install` as detailed below.

## Installation options

<!-- DO NOT EDIT THE FENCED CODE BLOCK and RETAIN THIS COMMENT: The fenced code block below is updated by `make update-readme/release` with CLI usage information. -->

```nohighlight
$ n-install --help

SYNOPSIS
  n-install [-t] [-y] [version...]

DESCRIPTION
  Installs n, the Node.js version manager, which bypasses the need to manually
  install a Node.js version first.

  Additionally, installs n-update for updating n,
  and n-uninstall for uninstallation.

  On successful installation of n, the specified Node.js/io.js version(s)
  are installed; by default, this is the latest stable Node.js version;
  To opt out, specify '-' as the only version argument.
  'stable' installs the latest stable version, available, 'latest' the latest
  available overall; otherwise, specify an explicit version numer, such as
  '0.12' or '0.10.35'.
  To install io.js versions, prefix the version with 'io:'; e.g., 'io:stable'.
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
  For any other shell you'll have to make these modifications yourself.

  Options:

  -t
    Merely tests if all installation prerequisites are met, which is signaled
    with an exit code of 0.

  -y
    Assumes yes as the reply to all prompts; in other words: runs unattended
    by auto-confirming the confirmation prompt.

  For more information, see http://git.io/n-install-repo

PREREQUISITES
  bash ... to run this script and n itself.
  curl ... to download helper scripts from GitHub and run n itself.
  git ... to clone n's GitHub repository and update n later.
  GNU make ... to run n's installation procedure.
  
EXAMPLES
    # Install n and the latest stable Node.js version, with 
    # interactive prompt:
  n-install 
    # Only test if installation to the specified location would work.
  N_PREFIX=~/util/n n-install -t
    # Automated installation of n, without installing the latest
    # stable Node.js version.
  n-install -y -
    # Automated installation of n, followed by automated installation
    # of the latest stable and unstable Node.js versions, as well
    # as the latest 0.8.x version.
  n-install -y stable latest 0.8
```

# Updating n

Run `n-update` on demand to update `n` itself to the latest version.  
`n-update -y` skips the confirmation prompt.

## Manual updating

If, for some reason, `n-update` doesn't work or isn't available, run the following to update `n`:

* `cd "$N_PREFIX/n/.repo" && git pull && PREFIX="$N_PREFIX" make install && cd -`

# Uninstalling n

Run `n-uninstall` to uninstall `n` as well as the Node.js / io.js versions that were installed with it.
`n-uninstall -y` skips the confirmation prompt - **use with caution**.

## Manual uninstallation

If, for some reason, `n-uninstall` doesn't work, do the following:

* Remove the `N_PREFIX` environment-variable definition and associated `PATH` modification from your shell's initialization file.

* Remove the directory that `N_PREFIX` points to:
    * Be sure that that directory contains no content unrelated to `n` that you may want to preserve.
    * If `$N_PREFIX` is not defined, look in the default installation location, `~/n`.


<!-- DO NOT EDIT THE NEXT CHAPTER and RETAIN THIS COMMENT: The next chapter is updated by `make update-readme/release` with the contents of 'LICENSE.md'. ALSO, LEAVE AT LEAST 1 BLANK LINE AFTER THIS COMMENT. -->

# License

Copyright (c) 2015 Michael Klement <mklement0@gmail.com> (http://same2u.net), released under the [MIT license](https://spdx.org/licenses/MIT#licenseText).

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
