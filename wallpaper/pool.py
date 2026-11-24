"""Publish four immutable daily city albums. No image search in the request path."""
import argparse
from datetime import date, datetime, timedelta, timezone
import fcntl
from hashlib import sha256
import json
from pathlib import Path
import random
import shutil
import tempfile
from PIL import Image

CITIES = ("qingdao", "jinan", "shanghai", "beijing")
SIZES = {"portrait": (1242, 2688), "landscape": (1440, 810)}
ROOT = Path(__file__).resolve().parent
TZ = timezone(timedelta(hours=8))

def service_day(now=None):
    return ((now or datetime.now(TZ)).astimezone(TZ) - timedelta(hours=4)).date()

def write_json(path, obj):
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

def read(path):
    return json.loads(path.read_text(encoding="utf-8"))

def select(rows, previous, seed):
    rows = sorted(rows, key=lambda r:r["id"])
    random.Random(seed).shuffle(rows)
    seen = list(previous)
    chosen = []
    for row in rows:
        if any(row["id"] == s["id"] or bin(int(row["hash"],16) ^ int(s["hash"],16)).count("1") <= 6 for s in seen):
            continue
        chosen.append(row)
        seen.append(row)
        if len(chosen) == 5: return chosen
    raise ValueError("Fewer than five distinct new scenes: refusing to publish")

def publish(library, dest, day):
    dest.mkdir(exist_ok=True, parents=True)
    with (dest/".lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        target = dest/day.isoformat()
        if target.is_dir(): return target
        # Dates are immutable; never insert an album in between two existing days.
        dates = sorted(p for p in dest.iterdir() if p.is_dir() and len(p.name)==10 and p.name[4]=='-')
        if dates and dates[-1].name > day.isoformat(): raise ValueError("out-of-order date")
        stage = Path(tempfile.mkdtemp(prefix=".new-",dir=dest))
        try:
            for city in CITIES:
                previous = read(dates[-1]/city/"index.json")["images"] if dates else []
                entries = select(read(library/city/"catalog.json"), previous, city+day.isoformat())
                out = stage/city
                out.mkdir()
                for r in entries:
                    for variant, size in SIZES.items():
                        name = r["id"]+"-"+variant+".jpg"
                        src = library/city/name
                        if sha256(src.read_bytes()).hexdigest()!=r[variant+"SHA256"]: raise ValueError(f"damaged {src}")
                        with Image.open(src) as im:
                            if im.size != size or im.format != "JPEG": raise ValueError(f"wrong dimensions: {src}")
                            im.verify()
                        # Published files must not share writable inodes with the source library.
                        shutil.copyfile(src, out/name)
                write_json(out/"index.json",dict(city=city,day=day.isoformat(),images=entries))
            stage.chmod(0o755)
            stage.rename(target)
            for old in dates:
                if date.fromisoformat(old.name)<day-timedelta(days=2): shutil.rmtree(old)
        finally:
            if stage.exists(): shutil.rmtree(stage)
        return target

if __name__ == "__main__":
    a=argparse.ArgumentParser()
    a.add_argument("--library",type=Path,default=ROOT/"library")
    a.add_argument("--output",type=Path,required=True)
    a.add_argument("--day",type=date.fromisoformat,default=service_day())
    args=a.parse_args()
    print(publish(args.library,args.output,args.day))
