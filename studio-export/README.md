# Current Studio project export

Exported October 17, 2026 from **Untitled Experience**, place ID `77673228224887`, universe ID `10771319202`.

## Restore the full project

Open `../MovementPhone-2026-10-17.rbxl` using Roblox Studio's **File > Open from File**. The native place file is the restore source: it preserves saveable instances, geometry, rig joints, properties, attributes, UI, lighting, script children, animation keyframe sequences, and embedded place data. Scripts alone do not reconstruct the character or tool.

The repository's older `HorrorAdventure*.rbxl` snapshots describe a different place and remain available separately.

## Readable files

- `src/`: all 48 Script, LocalScript, and ModuleScript sources found in Studio, including reference/backup scripts and imported scripts. Each script has its own directory; `init.client.luau`, `init.server.luau`, and `init.luau` distinguish the classes. This is a source mirror, not a configured Rojo project.
- `scripts.json`: original Studio paths, classes, source lengths, and corresponding exported filenames. Duplicate paths use a numeric suffix.
- `studio-metadata.json`: service inventory, instance-class counts, script attributes and execution settings, a catalog of 12 locally saved animation sequences, and 113 asset-bearing instance references. Inventory includes Studio-managed runtime/editor instances that Studio does not serialize into a place file.
- `manifest.json`: snapshot and source SHA-256 checksums, native file verification, and file counts.
- `../tools/verify_studio_export.py`: validates the native file structure and the source mirror and refreshes `manifest.json`.

The 29 `DirectionalLocomotion/CompatiblePoses` child modules include sampled animation poses adapted to the custom rig. Full locally saved KeyframeSequence data remains in the native snapshot, including Workspace animation saves and corrected animation copies in ServerStorage. Animation assets referenced only by ID are still hosted by Roblox.

## Current controls and behavior

- Double-tap W to sprint; Ctrl cycles shoulder-lock views.
- F equips/stows the phone; the default Backpack UI and numeric hotbar bindings are disabled.
- Phone equip/stow uses a validated server request. Screen lights and separate equip/shutdown cues follow the equipped state.
- With the phone out, peripheral shading and mild color reduction narrow awareness while leaving the character clear.
- Drops of 12 studs or more trigger the custom falling/landing behavior and a pale teal landing flash. Falling arms rise over 2.5 seconds; the character faces its horizontal travel direction in free fall.

## Boundaries

Roblox-hosted meshes, textures, audio, and animation assets retain their IDs and access requirements. This transfer does not export live player DataStores, credentials, cloud-only experience configuration, or other places. Saved scripts are mirrored as found, including unused imported loaders; this transfer is not a code or asset security review. Existing Studio plugins and editor UI are not part of the playable project.

Changes made later in Studio require a fresh export to update GitHub.
