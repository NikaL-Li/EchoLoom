"""Validate every bundled WAV. --generate uses the app's MiMo fetch for missing files."""
from pathlib import Path
import argparse
import hashlib
import io
import json
import re
import subprocess
import tempfile
import wave

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--generate", action="store_true")
args = parser.parse_args()
if args.generate:
    with tempfile.TemporaryDirectory(prefix="ylct-bundle-generation-") as temporary:
        executable = str(Path(temporary) / "generate")
        sdk = subprocess.check_output(["xcrun", "--sdk", "macosx", "--show-sdk-path"], text=True).strip()
        subprocess.run(["xcrun", "swiftc", "-target", "arm64-apple-macosx14.0", "-sdk", sdk,
                        "-module-cache-path", str(Path(temporary) / "modules"),
                        "Sources/ServiceOrigin.swift", "Sources/CustomPhrases.swift", "Tests/GenerateBundledReplies.swift", "-o", executable],
                       cwd=ROOT, check=True)
        subprocess.run([executable], cwd=ROOT, check=True)
source = (ROOT / "Sources/CustomPhrases.swift").read_text()
catalog = source.split("enum BundledReplyAudio {", 1)[1].split("static func resourceName", 1)[0]
entries = re.findall(r'"([^"]+)": "(preset_[^"]+)"', catalog)
directory = ROOT / "Sources/Resources/Presets"
records = []
for text, base in entries:
    for suffix, voice in [("f", "冰糖"), ("m", "苏打")]:
        path = directory / f"{base}_{suffix}.wav"
        if not path.exists():
            raise RuntimeError(f"Missing {path.name}; run with --generate before shipping")
        data = path.read_bytes()
        if not 44 < len(data) < 15_000_000 or data[:4] != b"RIFF" or data[8:12] != b"WAVE":
            raise RuntimeError(f"{path.name}: invalid WAV")
        with wave.open(io.BytesIO(data), "rb") as audio:
            if audio.getnframes() <= 0 or audio.getframerate() <= 0:
                raise RuntimeError(f"{path.name}: empty audio")
            duration = audio.getnframes() / audio.getframerate()
        records.append({"text": text, "voice": voice, "file": path.name, "seconds": round(duration, 3),
                        "sha256": hashlib.sha256(data).hexdigest()})
        print("VERIFIED", path.name, f"{duration:.2f}s", flush=True)
(ROOT / "Tests/BundledReplyManifest.json").write_text(json.dumps(records, ensure_ascii=False, indent=2) + "\n")
print(f"Verified {len(entries)} replies / {len(records)} static audio files.")
