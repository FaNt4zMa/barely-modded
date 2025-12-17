## [2.4.2] - 2025-12-14

### Added

- More Blocks (Fixed)
  - Originally created by Kxffie
  - Added Resin Bricks, Pale Oak wood and trapdoor, plus new stairs variants including Tuff
  - Fixed recipes for Cobbled Deepslate Stairs, Purpur Stairs, and Stripped Oak Wood
  - Distributed under the original MIT license

### Changed

- Updated mods to their latest version
  - AfkPlus
  - Better Ghast Harness
  - Call Your Horse
  - Colorful Lanterns
  - Copper Fire
  - End Fire
  - filament
  - Geophilic
  - ItemSwapper
  - Simple Voice Chat
  - Veinminer Enchantment
  - ViaVersion

- Updated Fabric Loader to 0.18.2
- Renamed ReciperRemover datapack to zzz_ReciperRemover to ensure load order

### Disabled

- More Blocks

### Fixed

- Simple Update Checker should now reflect proper pack version
- Moved polymer config `auto-host.json` to YOSBR folder to avoid overriding
- RecipeRemover datapack proper load order



## [2.4.1] - 2025-12-10

### Changed

- Updated mods to their latest version
  - Rail Recipe Rebalance



## [2.4.0] - 2025-12-10

### Added

- DefaultGamerules (Custom Datapack)
  - Applies 3 gamerules on every world load (gamerule mods don't affect existing worlds)
  - 50% sleep percentage - only half the players need to sleep
  - Creeper explosions drop all blocks - no more missing blocks
  - Enables animal respawning (required for Respawning Animals mod)
  - Left as an unpacked folder in `/datapacks` for easy editing and customization
- End Fire
- Night Lights
- NoConsoleSpam
- Polymer Patch for Night Lights
- Respawning Animals
- Rail Recipe Rebalance (Fixed)
  - Originally created by Palm1
  - Repackaged with a corrected `pack.mcmeta` to restore recipe loading
  - Distributed under the original MIT license
- Vocal Villagers (Resource Pack)
- Gentler Weather Sounds (Resource Pack)

### Changed

- Updated mods to their latest version
  - Banner Text
  - Better Craftables
  - Better Unpackables
  - Copper Cutting
  - Haul
  - Phantom Spawning

- Updated datapacks to their latest version
  - Blossoming Pots
  - Lively Lily Pads
  - Rope Ladders
  - Shapeless Portals

- Updated custom RecipeRemover datapack
  - Added a version number
  - Also removes broken functions or recipes from projects where the author can’t be reached, eliminating console errors
  - Added verbose output confirming successful load

### Removed

- Default No Chat Reports config
  - The bundled NCR config in `/config/yosbr/config/NoChatReports/NCR-Common.json` has been removed
  - If you previously used this pack, **delete your existing NCR config** so the client can correctly detect that the server has NCR installed

### Fixed

- Eliminated console spam from broken recipes, functions, and invalid `.DS_Store` files

## [2.3.0] - 2025-12-08

### Added

- Clucking Ducks (Datapack)
- Earth Animals (Datapack)
- Frog Concept Variants (Datapack)
- ItemSwapper
- Magnetic Enchantment
- Nice Wandering Trader Announcements
- Simple Golden+ (Datapack)
- Smelting Enchantment
- Tameable Ravagers
- Wandering Trader Maps
- Wooly Animals (Datapack)

### Changed

- Updated mods to their latest version
  - Better Ghast Harness
  - CraterLib
  - Shulker Box Tooltip
  - Simple Discord Link
  - ViaVersion
  - VillagerConfig
  - YetAnotherConfigLib

- Updated RecipeRemover datapack

- New RightClickHarvest config to rewards XP on harvest
  - For existing worlds/server, please modify manually or simply delete your current `rightclickharvest.json5` config file and relaunch the server

### Disabled

- Roughly Enough Items
- Polydex2REI-Forked

### Fixed

- Temporarily disabled REI to fix Polymer spamming the console with "failed to encode polymer item stack" on client join
- Added `fabric_loader_dependencies` so mods can stop complaining ModMenu isn't installed

### Notes

- **This update is the last planned fully-synced release of the client and server packs.** The client pack is considered complete for now, though it may still receive occasional additions or tweaks. Going forward, most new content will be focused on the server pack, which will continue to evolve separately.



## [2.2.0] - 2025-12-04

### Added

- Backpack Club
- FabricExporter
- Hat Club
- No Feather Trample
- Shields Knock Back
- spark

### Changed

---
#### BREAKING CHANGE

- The **Hats Off!** datapack has been replaced with **Hat Club** for its better models and expanded customization options.
- This change may render existing hats from the previous system unusable. I’m deeply sorry for the inconvenience it may cause.

---

- Updated mods to their latest version
  - Architectury API
  - AudioPlayer
  - filament
  - Puzzles Lib
  - VillagerConfig

### Removed

- Hats Off! Datapack



## [2.1.1] - 2025-11-30

### Changed

- Rolled back filament version to fix console spam

- Updated mods to their 1.21.10 release
  - Pyrotechnic Elytra

- Updated datapacks to their 1.21.10 release
  - Blossoming Pots
  - Lively Lily Pads
  - Rope Ladders
  - Shapeless Portals

### Removed

- Mod Menu
  - Was auto installed by accident, not useful on server



## [2.1.0] - 2025-11-29

### Added

- Colorful Campfires
- Colorful Copper Lanterns
- Phantom Spawning
- Polydex2REI-Forked
- Roughly Enough Items

### Changed

- Updated mods to their latest version
  - Call Your Happy Ghast
  - Client Sort
  - filament
  - Get It Together, Drops!
  - KleeSlabs
  - MapFrontiers
  - ViaVersion

### Removed

- Copper Campfire
  - I hadn't noticed it replaced the soul campfire. Also, PolyDeco already provides one

### Re-Enabled

- Get It Together, Drops!



## [2.0.0] - 2025-11-24

### Added

- Colorful Lanterns default config: enables placing on wall by default, making them consistent with PolyDeco's lanterns

### Changed

- Updated most mods to their 1.21.10 version

### Disabled

- Get It Together, Drops!



## [1.9.0] - 2025-11-24

### Added

- Armor Poser
- Audaki Cart Engine (Faster Minecarts)
- Banner Text
- Colorful Lamp
- Colorful Lanterns
- Copper Campfire
- Copper Fire
- Death Count
- Happy Ghast Scaffolding
- KleeSlabs
- Lingering Arrows
- Name Formatting Station Datapack
- SkinRestorer
- Visual Armor Trims (Resource Pack)

### Changed

- Updated mods to their latest version
  - Blossoming Pots
  - Call Your Happy Ghast
  - Client Sort
  - Deimos
  - Fabric API
  - ViaVersion

- Updated Fabric Loader to 0.18.1

### Important Notes

- **This is the final release targeting Minecraft 1.21.8. Starting with v2.0, all releases will target Minecraft 1.21.10. During this transition, certain incompatible mods or datapacks may be temporarily disabled while updates are coordinated with their developers. Some content may not return, so the 1.21.10 version may include fewer features. Thank you for your patience and understanding.**



## [1.8.0] - 2025-11-13

### Added

- Filament
- PolyDecorations
- Polydex
- Portfolio
- Snowy Biomes: Enhanced
- Toms Server Additions: Decorations & Furniture
- Visual Jukebox

### Changed

- Updated mods to their latest version
  - Forge Config API Port
  
- Updated datapacks to their latest version 
  - RecipeRemover
  - VanillaTweaks Kill Empty Boats
  - VanillaTweaks Nether Portal Coords



## [1.7.0] - 2025-11-10

### Added

- Amethyst Cutting
- Copper Cutting
- Craftable Horse Armor
- Better Ghast Harness
- Better Wandering Traders
- PerPlayerWanderingTraders
- Status
- Timber Enchantment
- Veinminer Enchantment
- VillagerConfig

### Changed

---
#### BREAKING CHANGE

- Veinminer Enchantment was replaced with a new standalone datapack that no longer relies on Silk, Kotlin, or other dependencies. 
- Previously enchanted tools will no longer function, please re-enchant them.
---

- Updated mods to their latest version
  - Cobweb
  - Shulker Box Tooltip
  - ViaVersion

- Updated Fabric Loader to 0.18.0

### Removed

- Craftable Horse Armor
- Fabric Language Kotlin
- Faster Happy Ghast
- Silk
- Veinminer
- Veinminer Enchantment



## [1.6.1] - 2025-11-02

### Changed

- Updated mods to their latest version
  - Call Your Horse
  - Client Sort
  - Fabric Language Kotlin
  - Puzzles Lib
  - ViaVersion



## [1.6.0] - 2025-10-22

### Added

- Peek
- View Distance Fix

### Changed

- Updated mods to their latest version
  - Call Your Horse
  - Sit!



## [1.5.0] - 2025-10-21

### Added
*In preparation for a 1.21.10 release*

- Datapack Injector
- NoisiumForked

### Changed

- Updated mods to their latest version
  - Collective
  - ViaVersion

### Removed
*Some of these do not fit the pack's philosophy*

- Data Loader
- Debugify
- Inventory Totem
- MidnightLib
- Noisium
- Spawn Animations



## 🧭 Development Update
- **Please read the client pack [update note](https://modrinth.com/modpack/fantazs-barely-modded/version/1.4.1) for important context on upcoming changes**

---

## [1.4.1] - 2025-10-19

### Changed

- Updated mods to their latest version
  - Client Sort
  - Collective
  - Fabric API
  - Simple Voice Chat
  - ViaVersion



## [1.4.0] - 2025-10-16

### Added

- Polymer
  - Default config enables AutoHost module
  - Useful for datapack/mods that requires a resource pack
  - Additional configuration may be needed if running behind a reverse proxy, refer to [Polymer's wiki](https://polymer.pb4.eu/latest/user/resource-pack-hosting/)
- Image2map
  - Default config allows all players (non-OP) to create map image and enables using local files
- 777
- Hit The Dummy
- Blaze Attack Animation
- Faster Happy Ghast
- Hats Off! Datapack
- Rope Ladders (Datapack)
- Lively Lily Pads (Datapack)
- Blossoming Pots (Datapack)

### Changed

- Updated mods to their latest version
  - Call Your Horse
  - No Enderman Grief
  - ViaVersion
  
### Removed

- ThreadTweak

### Known Issue

- Crash with Fabric 1.21.9+ clients. This is caused by ViaVersion and FabricAPI having missing or mismatch blockstates. Can't fix, use the proper client pack or fully vanilla client to avoid



## [1.3.3] - 2025-10-13

### Added

- MidnightLib
- Spawn Animations default config: set the activation mode to "vanilla", to mitigate crash on 1.21.9+ clients
- Advanced Shulkerboxes default config: makes sneak not required to place
- Just Mob Heads default config: enables standard heads and only drop on player kill

### Changed

- Updated mods to their latest version
  - AfkPlus
  - Armor Statues Datapack
  - Balm
  - Client Sort
  - MapFrontiers
  - No Chat Reports
  - Simple Voice Chat
  - Spawn Animations
  - Veinminer Enchantment
  - ViaVersion

- Adjusted AfkPlus default config for cleaner chat messages and ease of use
- Adjusted TabTPS default config for cleaner tab look and less demanding update rate



## [1.3.2] - 2025-10-08

### Changed

- Updated mods to their latest version
  - Client Sort
  - Collective
  - Geophilic
  - Shulker Box Tooltip
  
### Added

- ViaFabric & ViaVersion
  - Allows players past 1.21.8 to connect



## [1.3.1] - 2025-10-03

### Changed

- Updated mods to their latest version
  - Collective
  
### Notes

- Forgot to add a client side mod; this update was mainly done to keep versions number consistent between Client and Server pack



## [1.3.0] - 2025-10-02

### Changed

- Updated mods to their latest version
  - Balm
  - Fabric API
  - Haul
  - Lithium
  - Spawn Animations

- Moved all default configs to YOSBR folder to avoid overwriting user preferences on update

### Added

- YOSBR
- Get It Together, Drops!
- Pyrotechnic Elytra
- Cobweb
- Bookshelf Inspector
- Banner Flags
- Racks (Datapack)
- Simple Update Checker



## [1.2.0] - 2025-09-29

### Changed

- Updated mods to their latest version
  - MapFrontiers
  
### Added

- Better Unpackables (replaces Sam's Unpacked Ice)
- Better Craftables (replaces other removed mods/datapacks)
- Call Your Horse
- Call Your Happy Ghast
- Custom made RecipeRemover datapack

### Removed

- Sam's Unpacked Ice (outdated)
- VanillaTweaks Sandstone Dyeing datapack
- VanillaTweaks Universal Dyeing datapack
- Blasting Raw Metal Blocks

### Fixed

- Removed duplicate recipes


## [1.1.1] - 2025-09-24

### Changed

- Updated mods to their latest version
  - Client Sort
  - I'm Fast
  - JamLib
  - RightClickHarvest
  - Simple Voice Chat
  
### Fixed

- Replaced the Neoforge version of BlueMap Frontier with the Fabric one (whoops)



## [1.1.0] - 2025-09-18

### Changed

- Updated mods to their latest version
  - Balm
  - Client Sort
  - Deimos
  - Fabric Language Kotlin

### Added

- ThreadTweak
- I'm Fast
- Simple Voice Chat Enhanced Groups
- Cycle Paintings
- Invisible Frames
- Textile Backup
  - Config: Max 25 backups, max 24hrs age, max 50GiB.



## [1.0.1] - 2025-09-10

### Changed

- Updated mods to latest versions



## [1.0.0] - 2025-09-08

### Added

- Initial release



## [0.0.0] - YYYY-MM-DD

### Added

### Changed

### Removed

### Fixed