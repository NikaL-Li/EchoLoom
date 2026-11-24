"""Register validated WAV resources without regenerating either Xcode project."""
from pathlib import Path
import hashlib
import json
import plistlib
import re
import subprocess

root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / "Tests/BundledReplyManifest.json").read_text())
for item in manifest:
    data = (root / "Sources/Resources/Presets" / item["file"]).read_bytes()
    assert hashlib.sha256(data).hexdigest() == item["sha256"], item["file"]

for project_name in ["译声.xcodeproj", "UITesting.xcodeproj"]:
    path = root / project_name / "project.pbxproj"
    original = path.read_text()
    project = plistlib.loads(subprocess.check_output(["plutil", "-convert", "xml1", "-o", "-", str(path)]))
    objects = project["objects"]
    group_id = next(k for k, v in objects.items() if v.get("isa") == "PBXGroup" and v.get("path") == "Presets")
    target = next(v for v in objects.values() if v.get("isa") == "PBXNativeTarget" and v.get("name") == "译声")
    phase_id = next(k for k in target["buildPhases"] if objects[k]["isa"] == "PBXResourcesBuildPhase")
    additions = []
    for item in manifest:
        name = item["file"]
        existing = next((k for k in objects[group_id]["children"] if objects[k].get("path") == name), None)
        if existing:
            assert any(objects[k].get("fileRef") == existing for k in objects[phase_id]["files"]), name
            continue
        file_id = hashlib.sha256(("ylct-static-file:" + name).encode()).hexdigest()[:24].upper()
        build_id = hashlib.sha256(("ylct-static-build:" + name).encode()).hexdigest()[:24].upper()
        assert file_id not in objects and build_id not in objects
        objects[file_id] = dict(isa="PBXFileReference", lastKnownFileType="audio.wav", path=name, sourceTree="<group>")
        objects[build_id] = dict(isa="PBXBuildFile", fileRef=file_id)
        objects[group_id]["children"].append(file_id)
        objects[phase_id]["files"].append(build_id)
        additions.append((name, file_id, build_id))
    if not additions:
        print(project_name, "already contains every bundled reply")
        continue
    if original.lstrip().startswith("<?xml"):
        updated = plistlib.dumps(project).decode()
    else:
        updated = original
        definitions = "".join(f'\t\t{f} /* {n} */ = {{isa = PBXFileReference; lastKnownFileType = audio.wav; path = {n}; sourceTree = "<group>"; }};\n' for n, f, b in additions)
        builds = "".join(f"\t\t{b} /* {n} in Resources */ = {{isa = PBXBuildFile; fileRef = {f} /* {n} */; }};\n" for n, f, b in additions)
        updated = updated.replace("/* End PBXFileReference section */", definitions + "/* End PBXFileReference section */")
        updated = updated.replace("/* End PBXBuildFile section */", builds + "/* End PBXBuildFile section */")
        for key, field, rows in [
            (group_id, "children", "".join(f"\t\t\t\t{f} /* {n} */,\n" for n, f, b in additions)),
            (phase_id, "files", "".join(f"\t\t\t\t{b} /* {n} in Resources */,\n" for n, f, b in additions)),
        ]:
            pattern = rf"(^\t\t{key} /\*[^\n]*\*/ = \{{\n.*?^\t\t\t{field} = \(\n)"
            updated, count = re.subn(pattern, lambda match: match.group(1) + rows, updated, count=1, flags=re.M | re.S)
            assert count == 1, (project_name, key)
    temporary = path.with_suffix(".pending")
    temporary.write_text(updated)
    subprocess.run(["plutil", "-lint", str(temporary)], check=True, capture_output=True)
    temporary.replace(path)
    print(project_name, "registered", len(additions), "new audio resources")
