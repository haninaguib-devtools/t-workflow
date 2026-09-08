# Migrations

This directory holds one append-only `V<n>__<slug>.md` file per breaking template
change. The convention — when a migration is needed, its shape, and how `t-update`
applies one — is documented in `docs/architecture/migrations.md`; this file is only a
landing pad so the directory exists in git before the first migration does.

The migrations themselves sit beside this file, `V1__…` onward, one per breaking
change; `docs/architecture/migrations.md` §How `t-update` applies them says which of
them a given sync runs.
