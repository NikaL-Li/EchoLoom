"""Turn verified city originals into reusable pairs; never upscale or relabel a search thumbnail."""
from hashlib import sha256
from PIL import Image, ImageOps
from pool import CITIES, ROOT, SIZES, read, write_json
from pathlib import Path
import argparse

def prepare(source, library):
    for city in CITIES:
        out=library/city
        out.mkdir(exist_ok=True, parents=True)
        rows=[]
        for meta in sorted((source/city).glob("*/meta.json")):
            r=read(meta)
            with Image.open(meta.parent/"source.jpg") as orig:
                im=ImageOps.exif_transpose(orig).convert("RGB")
            r["sourceSize"]=list(im.size)
            gray=im.convert("L").resize((9,8),Image.Resampling.LANCZOS)
            r["hash"]=format(sum((gray.getpixel((x,y))>gray.getpixel((x+1,y)))<<(8*y+x) for x in range(8) for y in range(8)),"016x")
            for key,size in SIZES.items():
                if im.width<size[0] or im.height<size[1]: raise ValueError(f"undersized {meta}")
                fn=out/(r["id"]+"-"+key+".jpg")
                center=tuple(r.get("focus",[0.5,0.5]))
                ImageOps.fit(im,size,Image.Resampling.LANCZOS,centering=center).save(fn,quality=88,optimize=True,progressive=True)
                r[key+"SHA256"]=sha256(fn.read_bytes()).hexdigest()
            rows.append(r)
        write_json(out/"catalog.json",rows)
        print(city,len(rows),flush=True)

if __name__=="__main__":
    a=argparse.ArgumentParser()
    a.add_argument("originals",type=Path)
    a.add_argument("--library",type=Path,default=ROOT/"library")
    v=a.parse_args();prepare(v.originals,v.library)
