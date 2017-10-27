# Changelog

Versioning complies with [semantic versioning (semver)](http://semver.org/).

<!-- NOTE: An entry template for a new version is automatically added each time `make version` is called. Fill in changes afterwards. -->

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
