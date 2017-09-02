# Look into whether it's safe to always check out the latest commit from the `n` master branch

Development happens in the master branch, so there's a chance that the latest commit isn't bug-free.

It would take something like the following to identify the latest release (note the need for CLI `semver`).

    git tag | xargs semver | tail -n 1

The following would work, but only if there are no *pre*releases in the history.

    git describe --tags --match v[0-9]*.[0-9

It's also at odds with our current approach of using --depth 1 to only get the most recent commit.

If we had a way of reliably getting the latest release without needing a local repo,
we could just download and unzip it (which gives us the repo snapshot without the repo itself).

Unfortunately, the latest release isn't reliably tagged as such, because only
*explicitly* created releases are reachable by the "Latest Release" URL,  .../releases/latest
See https://www.evernote.com/shard/s69/nl/1988793911/8fd5ee6f-0bb1-40df-8a58-874b3f67b996/

# Consider temporarily changing git's checkout line-ending configuration to LF

If files are checked out with CRLF, running `n` itself breaks.

See https://github.com/mklement0/n-install/issues/17

