# Changelog

All notable changes to **msk_whitelist** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [2.1.0] - 2026-09-09

Runs on QBCore and Qbox. Until this release the resource was ESX only, and it
said so in its manifest.

### Requires

- **msk_core 4.0.0 or newer.** The player object, `MSK.Offline.GetPlayerTable`
  and `MSK.RegisterCommand` are all used in their 4.0.0 form. Update msk_core
  along with this script.

### Added

- **`Config.Commands.ausreise.startMoney`.** The balance `clear_money` sets is
  configured here now. It used to be read from
  `ESX.GetConfig().StartingAccountMoney`, which QBCore and Qbox do not have, and
  the account names differ too. `cash` and `bank` work on every framework, the
  rest is passed through and skipped when the framework has no such account: ESX
  knows `black_money`, QBCore and Qbox know `crypto`.

  **Add this block to your `config.lua`.** Without it `clear_money` does nothing
  instead of failing, so an old config file still starts.

### Changed

- **`es_extended` is no longer a dependency.** It was listed in `dependencies`
  and imported through `@es_extended/imports.lua`, so the resource refused to
  start on a server without ESX. Framework calls run through msk_core now.

- **The character table is resolved instead of hardcoded.** It is `users` keyed
  by `identifier` on ESX and `players` keyed by `citizenid` on QBCore and Qbox.
  `MSK.Offline.GetPlayerTable()` answers that, and all four queries use it.

- **`/einreise` and `/ausreise` run through `MSK.RegisterCommand`** instead of
  `ESX.RegisterCommand`. Same behaviour, same argument validation, but it works
  on every framework and resolves the ace groups itself.

- **The login and logout handlers listen to msk_core's events**
  (`msk_core:playerLoaded`, `msk_core:playerLogout`) instead of `esx:*`. They are
  bound with `AddEventHandler`, not `RegisterNetEvent`, because they are
  server-local: as net events any client could fire them with an arbitrary
  player id and skew the admin counter.

- **The appearance after admin mode is restored through whichever resource is
  running**: `illenium-appearance`, `qb-clothing` or the ESX pairing of
  `esx_skin` and `skinchanger`. When none of them runs, the step is skipped
  rather than failing, because nothing changed the appearance in that case
  either.

- `clear_inventory` and `clear_weapons` both go through `ClearInventory()`. On
  `ox_inventory` weapons are items, so both switches end up doing the same thing
  on a modern setup.

### Fixed

- **`/rein` crashed when `Config.Locations.admin_outside` is `'last_position'`.**
  It stored the position with `xTarget.getCoords(true)`, an ESX method that the
  msk_core 4.0.0 player object does not have.

- **`/raus` teleported into nowhere** when no position had been stored, for
  example after a resource restart. It falls back to the configured location
  now instead of sending a `nil` to the client.

- **Both admin commands ran into a `nil` player.** They are plain
  `RegisterCommand`, so they can be typed in the server console, where there is
  no player to read a group from.

- **The logout and drop handlers indexed a player that was already gone**, which
  ended the handler before it could update the admin counter, so the counter
  drifted upward over a session. `playerDropped` is also a FiveM event now, not
  a framework one, and it takes only the reason.

- **The `isNew` column was added to the wrong table on QBCore and Qbox.** The
  `ALTER TABLE` was hardcoded to `users`, so it silently failed there and every
  player counted as not new from then on.

### Changed files

```text
fxmanifest.lua
config.lua
client/main.lua
server/main.lua
server/functions.lua
CHANGELOG.md (new)
```

---

The versions below predate this file. They are the entries from the in-game
version checker, kept here so the history is in one place.

## [2.0.2]

- Fixed error: `attempt to call a nil value (method 'match')`

## [2.0.1]

- Fixed error with commands

## [2.0.0]

- Completely reworked the code

## [1.6.2]

- Updated callbacks for msk_core
- Performance improvements

## [1.6.1]

- Some bugfixes
- Performance improvements
- Added a timeout for the bell
- Added new ban methods

## [1.6]

- Bugfixes
- Improved performance
- Added new admin protections
- Added changelogs to the version checker
- New method for nametags, much better performance

## [1.0]

- Release
