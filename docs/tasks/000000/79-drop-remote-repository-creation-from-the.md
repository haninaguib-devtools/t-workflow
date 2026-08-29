# 79 — Drop remote repository creation from the installer
Issue: #79

## Asked
The installer currently offers to create the GitHub repository and push the first
commit as part of bootstrap (`--remote`/`--no-remote`/`--private`/`--public`, an
interactive prompt defaulting to yes, and the `gh repo create … --push` block in
`installer/bootstrap.sh`). That eager push closes the genesis exception
(CONSTITUTION.md §3) before the two placeholder fills the installer itself names as
still missing — CONSTITUTION.md §4 and AGENTS.md §Checks — so filling them in then
requires full pipeline ceremony for what is morally part of genesis. The remote path
also carries most of the installer's failure surface and performs an outward-facing
act on the person's GitHub account. Remove remote creation entirely: the installer
produces a local project only, and creating the remote is always the printed
follow-up the person runs after making the fills — `gh repo create … --push`, then
`./.t-workflow/scripts/github-bootstrap.sh` — exactly the sequence the current
no-remote exit message already prints.

## Done when
- `installer/install.sh` accepts no `--remote`, `--no-remote`, `--private`, or
  `--public` options, asks no remote or visibility questions, and mentions none of
  them in `--help`: `grep -E -- '--(no-)?remote|--private|--public'
  installer/install.sh` finds nothing.
- `installer/bootstrap.sh` never invokes `gh`: `grep -Fn 'gh ' installer/bootstrap.sh`
  returns nothing. `TWORKFLOW_REMOTE` and `TWORKFLOW_VISIBILITY` are gone from both
  scripts, and the exit message is the single local-only story: make the two fills,
  amend the first commit, then run the two printed commands to create the remote and
  apply its settings.
- An unattended run needs only `--name` (the no-/dev/tty path no longer demands a
  remote decision).
- `installer/test.sh` passes with the flags removed.
- `README.md` and `site/reference/installer.html` describe the local-only behavior;
  `grep -rn -- '--no-remote' README.md site/` returns nothing.
- Checks 2 and 3 pass.

## Explicitly not
- `.t-workflow/scripts/github-bootstrap.sh` is unchanged — it stays the settings step
  run after the person creates the remote.
- The genesis exception itself (CONSTITUTION.md §3 wording, its first-push end-point)
  is unchanged; only who performs the push changes.
- `installer/templates/README.md` changes only if it references the retired flags —
  its provenance handling is untouched.

## Decisions made along the way
- `installer/templates/README.md`: the plan reads the Non-goal as guarding provenance
  handling, so its two remote-conditional prose spots ("if a remote was created —
  pushed it…", "If the installer did not create a remote repository…") are updated to
  the unconditional local-only story; the `gh repo create` follow-up block stays —
  those are gh's own flags, not the installer's (agent, 2026-08-29, per the plan on
  #79; flagged for review).
- The printed follow-up keeps `--private` literally — the safe default the installer
  previously applied; visibility is the person's call at `gh repo create` time
  (agent, 2026-08-29).

## Deviations / notes
- The done-when criterion "`grep -Fn 'gh ' installer/bootstrap.sh` returns nothing" is
  unsatisfiable as literally written, because it contradicts another criterion in the
  same issue: the exit message must print `gh repo create … --push` as the follow-up
  command, and that printed text matches the grep (so does the word "through " in the
  genesis commit message — `-F 'gh '` matches any word ending in "gh"). The intent —
  bootstrap.sh never *invokes* gh — is satisfied: every `gh` occurrence sits inside
  printed text (the exit-message heredoc and the commit-message string), none at
  command position. Verified by inspection and by an awk scan excluding heredocs and
  comments. Flagged for the human at review/ship rather than gaming the wording to
  dodge a defective grep (agent, 2026-08-29).
