# Horror Adventure game

## Current character and phone project — October 17, 2026

Open **`MovementPhone-2026-10-17.rbxl`** in Roblox Studio for the current project exported from place `77673228224887` (Untitled Experience). This is a separate place from the historical school snapshots below.

The snapshot includes the modified R6 character, directional movement and sprint blending, custom idle/fall/landing animations, synchronized footsteps, the F-key iPhone tool, screen lighting, phone sound effects, and the reduced-awareness overlay. It also preserves the Workspace reference rig, locally saved animation sequences, backups, GUI instances, and saved place configuration.

Readable scripts and export documentation are in [`studio-export/`](studio-export/README.md). Roblox-hosted assets remain asset-ID references; live DataStores, cloud-only settings, and other experience places are outside this export. This is a snapshot, not automatic synchronization.

## Historical school project

Roblox Studio place snapshot from **Horror Adventure game**, place ID `138299763738587`.

## Open the game

1. Clone or download this repository.
2. Open Roblox Studio.
3. Choose **File > Open from File** and select `HorrorAdventure-Optimized.rbxl` for the simplified version.

## Simplified school

`HorrorAdventure-Optimized.rbxl` contains the Studio building cleanup completed October 16, 2026. `HorrorAdventure.rbxl` retains the original supplied snapshot for recovery.

- School parts after cleanup: **11,612 → 9,358**, removing **2,254 parts (19.4%)**. The subsequent four-pane classroom window update adds 84 parts, for a current total of **9,442**.
- Removed duplicates, hairline surface seams, buried parts, and unused imported loader scripts.
- Simplified locker vents, curtain folds, bookshelf details, and roof-post density. Continuous roof collision guards remain.
- Trimmed overlapping cross-hall ceilings, roof trim, stair thresholds, and roof-access walls without changing their combined structural coverage.
- Exterior repair: separated eight facade-band faces from floor slabs by 0.2 studs, trimmed 16 protruding end-wall edges, removed eight overlapping slab shoulders, and removed two redundant roof fascia pieces. The nine navigation checks passed again after this repair. `tools/CleanExteriorFaces.luau` records this additional one-time Edit-mode pass.
- Disabled collision on 1,302 decorative parts.
- All 21 ordinary classrooms with exterior openings now have four equal-width, evenly spaced glass panes. Pane count, width, and spacing were checked in every updated room. Existing wall openings, curtains, and specialist-room windows remain in place. `tools/FourClassroomWindows.luau` records the one-time change.
- Final school scans: zero exact geometry duplicates and zero overlapping coplanar structural pairs in the wall/floor/ceiling/roof-cap/threshold check. Intentional assembly joins and all possible mesh intersections are outside that check.
- All nine baseline pathfinding checks passed again: east corridors and central classrooms on all four floors, plus north stair access to the roof. A character also walked the tested ground-floor corridor segment in Play mode.
- This measures geometry and navigation, not an FPS improvement. Studio Output contained plugin/core UI and asset warnings; all routes and rooms have not been manually walked.

The one-time maintenance passes are in `tools/`. They are not runtime scripts. Run `SimplifySchool.luau` followed by `FinishStructuralJoins.luau` only against the original school layout in Studio Edit mode, in the same Studio session. The first pass rejects an already simplified school. Existing historical content outside the active school was preserved.

`HorrorAdventure.rbxl` is the full native place snapshot supplied as `GameH.rbxl` on October 15, 2026. It preserves the map, saved instances, scripts, lighting, terrain, and other content included by Studio in that file. This is a snapshot; later Studio edits are not automatically synced to GitHub. Download a new copy from Studio and replace this file to update it.

Roblox-hosted meshes, textures, audio, and other assets remain references to Roblox asset IDs and require the appropriate access. Live player DataStores, experience configuration outside the place, and other places in the experience are not included in a place file.

## Snapshot verification

- Size: 208,094 bytes
- Binary format version: 0
- Serialized instances: 71,582 across 88 classes
- SHA-256: `2116b59624735e85e5bfca01213ddc551492a4bdae99999d52a8f421d49ef686`
- Checked the native header, chunk boundaries, and final end marker. Gameplay was not tested as part of this transfer.
