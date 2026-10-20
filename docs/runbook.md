# Runbook

Watcher has no separate process. These are the failures the host actually shows.

## The header button never appears

The host did not load the plugin. `dshx.yml` expects the log line `[my-plugins/dsh-watcher] loaded`. Reinstall the web profile:

```sh
dsh plugin --profile web add dsh-watcher
```

A local checkout uses `dsh plugin --profile web add ./dsh-watcher` after `pnpm build`. Desktop profiles are not updated by that CLI; use the in-app installer.

## The price says 未知

The model is missing from `pricing/models.yaml`, or the row has no rate for a bucket that has tokens. That is not $0. Add the row, or put an override in Watcher settings. The override is only the changed rows in `localStorage` key `dsh-watcher:pricing-override:v1`.

## Remove it

```sh
dsh plugin --profile web remove dsh-watcher
```

Then reload the host. Settings stored under `dsh-watcher:` keys stay in the browser until cleared.
