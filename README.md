[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/mklement0/n-install/blob/master/LICENSE.md)

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

**Contents**

- [n-install &mdash; introduction](#n-install-&mdash-introduction)
- [Examples](#examples)
- [Installing n](#installing-n)
  - [Options and background information](#options-and-background-information)
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

[DO NOT USE YET.]

**Installs [`n`, the Node.js version manager](https://github.com/tj/n)**, on Unix-like platforms, **without needing to install [Node.js](https://nodejs.org/) first**.  
Additionally, installs scripts `n-update` for later on-demand updating of `n`, and `n-uninstall` for uninstalling.

`n` is installed as follows:

* The installation target is a **dedicated directory**, which **defaults to `~/n`** and can be overridden with environment variable `N_PREFIX`; n itself as well as the active Node.js/io.js version are placed there.
    * When overriding, it is advisable to choose a user location - typically, a subfolder of `~` (at any level) - so as to avoid the need to use `sudo` for installation of global `npm` packages.
    * Using a dedicated directory to hold both `n` and the Node.js/io.js versions greatly simplifies later uninstallation.
* If your shell is **`bash`, `ksh`, or `zsh`, the relevant shell initialization file is updated** to:
    * define environment variable `N_PREFIX` to point to the installation directory
    * append `$N_PREFIX/bin` to the `$PATH`
* By default, the latest stable Node.js version is installed; you can suppress that or even specify multiple Node.js/io.js versions to install.


The simplest case is **installation of `n` with confirmation prompt**, with subsequent **installation of the latest stable Node.js version**:

```shell
curl -L http://git.io/n-install | bash
```

See [more examples](#examples), and [Installing n](#installing-n) for prerequisites and installation options.

# Examples

* With confirmation prompt to confirm installing to `$HOME/n ` and installing the latest stable Node.js version:

```shell
curl -L http://git.io/n-install | bash
```

* Automated installation to default location `$HOME/n` and installation of the latest stable Node.js version:

```shell
curl -L http://git.io/n-install | bash -s -- -y
```

* Automated installation to alternative location `~/util/n`, with subsequent installation of the latest stable Node.js version:

```shell
curl -L http://git.io/n-install | N_PREFIX=~/util/n bash -s -- -y
```

* Automated installation to the default location, with subsequent installation of the specified Node.js and io.js versions:

```shell
curl -L http://git.io/n-install | N_PREFIX=~/util/n bash -s -- -y stable io:stable 0.10
```

# Installing n

**Supported platforms and prerequisites**

Any Unix-like platform with the following installed:

* [`bash`](http://www.gnu.org/software/bash/)
* [`curl`](http://curl.haxx.se/)
* [`git`](http://git-scm.com/)
* [GNU `make`](http://www.gnu.org/software/make/)

These prerequisites are met by default on OSX and most Linux platforms.

Irrespective of the installation method chosen below, no further steps are required if your default shell is either **Bash, Ksh, or Zsh**.  
For other shells, manual updating of their initialization files is required; detailed instructions are provided during installation.

## Options and background information

<!-- DO NOT EDIT THE FENCED CODE BLOCK and RETAIN THIS COMMENT: The fenced code block below is updated by `make update-readme/release` with CLI usage information. -->

```
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
    by auto-confirming the prompts.

  For more information, see http://git.io/n-install-repo

PREREQUISITES
  bash ... to run this script and n itself.
  curl ... to install this script directly from GitHub.
  git ... to clone n's GitHub repository.
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

Run `n-update` on demand to update `n` itself; `n-update -y` skips the confirmation prompt.

## Manual updating

If, for some reason, `n-update` doesn't work or isn't available, run the following to update `n`:

* `cd "$N_PREFIX/n/.repo" && git pull && PREFIX="$N_PREFIX" make install && cd -`

# Uninstalling n

Run `n-uninstall`; `n-uninstall -y` skips the confirmation prompt.

## Manual uninstallation

If, for some reason, `n-uninstall` doesn't work, do the following to uninstall `n`:

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
 
* **v0.0.1** (2015-06-16):
  * Preparing for true initial release (0.1.0).
