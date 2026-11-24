import concurrent.futures
from datetime import date, datetime, timezone
from hashlib import sha256
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from PIL import Image
from pool import CITIES, ROOT, SIZES, publish, read, select, service_day

class DailyAlbums(unittest.TestCase):
    def test_service_boundary(self):
        self.assertEqual(service_day(datetime(2026,11,24,19,59,tzinfo=timezone.utc)), date(2026,11,24))
        self.assertEqual(service_day(datetime(2026,11,24,20,0,tzinfo=timezone.utc)), date(2026,11,25))

    def test_real_albums(self):
        with tempfile.TemporaryDirectory() as t:
            dest=Path(t)
            previous={}
            for n in range(1,9):
                day=date(2026,11,n)
                with concurrent.futures.ThreadPoolExecutor(2) as ex:
                    paths=list(ex.map(lambda _: publish(ROOT/"library",dest,day),range(2)))
                self.assertEqual(paths[0],paths[1])
                for city in CITIES:
                    directory=paths[0]/city
                    m=read(directory/"index.json")
                    self.assertEqual((m["city"],m["day"]),(city,day.isoformat()))
                    ids={r["id"] for r in m["images"]}
                    self.assertEqual(len(ids),5)
                    self.assertFalse(ids & previous.get(city,set()))
                    self.assertEqual(len(list(directory.glob("*.jpg"))),10)
                    for r in m["images"]:
                        for key,size in SIZES.items():
                            path=directory/(r["id"]+"-"+key+".jpg")
                            self.assertEqual(sha256(path.read_bytes()).hexdigest(),r[key+"SHA256"])
                            with Image.open(path) as im: self.assertEqual(im.size,size)
                    previous[city]=ids
            self.assertEqual(len([p for p in dest.iterdir() if p.is_dir()]),3)

    def test_partial_generation_remains_private(self):
        with tempfile.TemporaryDirectory() as t:
            dest=Path(t); day=date(2026,11,1)
            def fail(rows,yesterday,seed):
                if seed.startswith("jinan"):raise ValueError("bad second city")
                return select(rows,yesterday,seed)
            with patch("pool.select",side_effect=fail),self.assertRaises(ValueError):
                publish(ROOT/"library",dest,day)
            self.assertFalse((dest/day.isoformat()).exists())
            self.assertFalse(list(dest.glob(".new-*")))

    def test_duplicate_image_under_new_id(self):
        rows=[dict(id=str(i),hash="aaff00ee00bb0011") for i in range(12)]
        with self.assertRaises(ValueError):select(rows,[],"test")

if __name__=="__main__":unittest.main()
