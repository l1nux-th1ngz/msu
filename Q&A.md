# Naming Files

> Why multiple files per shell?



# Choosing Shell Options

> Why no `set -e` | `set -o errexit`?

> Why no `set -u` | `set -o nounset`?

> Why no `set -f` | `set -o noglob`?

> Why no `shopt -s nullglob`?

> Why `shopt -s failglob`?

One caveat of `failglob` is when you want to match multiple globs, some of which may be empty.
For example:

```sh
rm "$dir"/*.txt "$dir"/*.tmp
```

If there are no `.tmp` files, then this will fail with `failglob`.
To prevent this, make use of the following, courtesy of `extglob`:

```sh
rm "$dir"/*@(.txt|.tmp)
```
