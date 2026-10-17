"""Validate the saved Studio snapshot and readable source export; write checksums."""
from pathlib import Path
import hashlib
import json
import struct

ROOT = Path(__file__).resolve().parents[1]
SNAPSHOT = ROOT / "MovementPhone-2026-10-17.rbxl"


def digest(data):
    return hashlib.sha256(data).hexdigest()


def verify():
    data = SNAPSHOT.read_bytes()
    assert data[:14] == b"<roblox!\x89\xff\r\n\x1a\n", "Invalid Roblox binary signature"
    version, classes, instances = struct.unpack_from("<HII", data, 14)
    assert version == 0, f"Unexpected native format version {version}"
    offset = 32
    chunks = []
    while offset < len(data):
        assert offset + 16 <= len(data), "Truncated chunk header"
        tag, compressed, uncompressed, reserved = struct.unpack_from("<4sIII", data, offset)
        size = compressed or uncompressed
        end = offset + 16 + size
        assert end <= len(data), "Truncated native chunk"
        chunks.append(tag.rstrip(b"\x00").decode("ascii"))
        if tag == b"END\x00":
            assert not compressed and data[offset + 16:end] == b"</roblox>", "Invalid end chunk"
            assert end == len(data), "Unexpected bytes after end chunk"
            break
        offset = end
    assert chunks[-1] == "END", "Missing native end chunk"
    rows = json.loads((ROOT / "studio-export/scripts.json").read_text(encoding="utf-8"))
    files = []
    for row in rows:
        path = (ROOT / row["file"]).resolve()
        assert path.is_relative_to(ROOT), "Source path outside the repository"
        content = path.read_bytes()
        # The patch writer may add one final newline; other source bytes are preserved.
        assert len(content) in (row["bytes"], row["bytes"] + 1), f"Source length mismatch: {row['path']}"
        files.append({"path": row["file"], "studioPath": row["path"], "bytes": len(content), "sha256": digest(content)})
    metadata = json.loads((ROOT / "studio-export/studio-metadata.json").read_text(encoding="utf-8"))
    result = {
        "exportDate": "2026-10-17", "placeId": metadata["placeId"], "universeId": metadata["gameId"],
        "snapshot": {"path": SNAPSHOT.name, "bytes": len(data), "sha256": digest(data), "formatVersion": version,
                     "serializedClasses": classes, "serializedInstances": instances, "chunkCount": len(chunks)},
        "scriptCount": len(files), "savedAnimationSequenceCount": len(metadata["savedAnimationSequences"]),
        "assetReferenceCount": len(metadata["assetReferences"]), "sources": files,
    }
    (ROOT / "studio-export/manifest.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({key: value for key, value in result.items() if key != "sources"}, indent=2))


if __name__ == "__main__":
    verify()
