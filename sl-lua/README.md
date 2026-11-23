# The game plugins moved

The in-game Lua plugins that used to live here have their own repos, with their history:

- `sl-admin` (SotaLore Admin, exports for site admins): https://github.com/sotalore/sladmin
- `sl-skills` (SotaLore Skills, for players): https://github.com/sotalore/slskills

Each repo's `EXPORT-FORMAT.md` is the contract this app reads. What the app tells the plugins is in
`docs/FROM-THE-APP.md`. Example files are in `spec/fixtures/plugin-examples/`. How the repos work together is
in https://github.com/sotalore/hq.
