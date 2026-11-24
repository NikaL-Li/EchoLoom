"""Copy five reviewed local scenes to the app; also preserve the full image credits."""
from pathlib import Path
import shutil
from pool import ROOT, read, write_json, SIZES

def bundle():
    src=ROOT/"library/qingdao"
    out=ROOT.parent/"ios/Native/Sources/Resources/CityPhotos"
    out.mkdir(exist_ok=True,parents=True)
    rows={r["id"]:r for r in read(src/"catalog.json")}
    # Seaside at blue hour, old town, the pier, coastal rocks, the harbor.
    chosen=[rows[i] for i in ["px37106092","125426422","px16154628","px17375003","px13356963"]]
    for r in chosen:
        for kind in SIZES:
            name=r["id"]+"-"+kind+".jpg";shutil.copyfile(src/name,out/name)
    write_json(out/"qingdao-offline.json",chosen)
if __name__=="__main__":bundle()
