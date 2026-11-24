"""Create the public source archive or build an unsigned device IPA from this checkout."""
import argparse
import hashlib
import json
from pathlib import Path
import plistlib
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
NATIVE = ROOT / "ios/Native"
META = plistlib.loads((NATIVE / "Sources/Info.plist").read_bytes())
VERSION = META["CFBundleShortVersionString"]
BASE = "译声-" + VERSION

def public_files():
    names = ["README.md", "CHANGELOG.md", "AUTHORS.md", "CONTRIBUTING.md", "NOTICES.md", "RELEASE-3.0.md", ".gitignore", "backend/server.py", "backend/LICENSE",
             "backend/README.md", "backend/test_native.py", "scripts/release.py",
             "ios/Native/README.md", "ios/Native/project.yml"]
    paths = [ROOT/n for n in names]
    for folder, suffixes in [
        ("ios/Native/Sources", {".swift",".plist",".storyboard",".json",".jpg",".png",".wav"}),
        ("ios/Native/Tests",{".swift",".json",".py",".md"}),
        ("wallpaper",{".py",".jpg",".json",".md",".conf",".service",".timer"})]:
        for p in (ROOT/folder).rglob("*"):
            if p.is_file() and p.suffix in suffixes and p.name != "ROUND13-ACCEPTANCE.md":
                paths.append(p)
    for project in (NATIVE/"译声.xcodeproj", NATIVE/"UITesting.xcodeproj"):
        paths += [project/"project.pbxproj", *project.glob("xcshareddata/xcschemes/*.xcscheme")]
    for p in sorted(paths):
        if p.is_symlink() or ROOT not in p.resolve().parents:
            raise ValueError(f"Not a release file: {p.name}")
        yield p

def release(kind,out):
    out.mkdir(parents=True,exist_ok=True)
    name = BASE + ("-源码.zip" if kind=="source" else "-未签名.ipa")
    final=out/name
    with tempfile.TemporaryDirectory(dir=out) as tmp:
        tmp=Path(tmp); archive=tmp/name
        if kind=="source":
            with zipfile.ZipFile(archive,"w",zipfile.ZIP_DEFLATED) as z:
                for p in public_files():
                    z.write(p, BASE+"/"+p.relative_to(ROOT).as_posix())
        else:
            subprocess.run(["xcodebuild","-project","译声.xcodeproj","-scheme","译声","-configuration","Release",
                            "-destination","generic/platform=iOS","-derivedDataPath",str(tmp/"build"),
                            "CODE_SIGNING_ALLOWED=NO","build"],cwd=NATIVE,check=True)
            app=tmp/"build/Build/Products/Release-iphoneos/译声.app"
            with zipfile.ZipFile(archive,"w",zipfile.ZIP_DEFLATED) as z:
                for p in sorted(app.rglob("*")):
                    if p.is_file():z.write(p,"Payload/译声.app/"+p.relative_to(app).as_posix())
            with zipfile.ZipFile(archive) as z:
                prefix="Payload/译声.app/"
                meta=plistlib.loads(z.read(prefix+"Info.plist"))
                assert meta["CFBundleIdentifier"]=="com.ylct.universal" and meta["CFBundleSupportedPlatforms"]==["iPhoneOS"]
                for key in ["CFBundleVersion","CFBundleShortVersionString","UILaunchStoryboardName"]:
                    assert meta[key]==META[key]
                assert (z.getinfo(prefix+meta["CFBundleExecutable"]).external_attr >> 16) & 0o111
                assert meta["CFBundleIcons"]["CFBundlePrimaryIcon"]["CFBundleIconName"]=="AppIcon"
                assert any(n.startswith(prefix+"CommunicationLaunch.storyboardc/") for n in z.namelist())
                for i in range(1,5): assert len(z.read(prefix+f"ys-caption-step-{i}.png"))>4000
                for row in json.loads((NATIVE/"Tests/BundledReplyManifest.json").read_text()):
                    assert hashlib.sha256(z.read(prefix+row["file"])).hexdigest()==row["sha256"]
                for row in json.loads(z.read(prefix+"qingdao-offline.json")):
                    for crop in ["portrait","landscape"]:
                        assert hashlib.sha256(z.read(prefix+row["id"]+"-"+crop+".jpg")).hexdigest()==row[crop+"SHA256"]
        with zipfile.ZipFile(archive) as z: assert z.testzip() is None
        archive.replace(final)
    print(final)

if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("kind",choices=["source","ipa"])
    parser.add_argument("output",type=Path)
    args=parser.parse_args()
    release(args.kind,args.output.resolve())
