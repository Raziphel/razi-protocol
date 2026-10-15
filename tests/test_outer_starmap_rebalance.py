"""Geometry and campaign contracts for Razi's 2.1.87 outer starmap."""
import math
import re
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]

def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

def geometry():
    layout=read("prototypes/system/galaxy_layout.lua")
    anchors={}
    for name,parent,radius,turn in re.findall(
        r'\{"(?:planet|space-location)","([^"]+)","([^"]+)",([\d.]+),([\d.]+)\}',
        layout):
        anchors[name]=(parent,float(radius),float(turn))
    for name,parent,radius,turn in re.findall(
        r'\{name="([^"]+)",star="([^"]+)",radius=([\d.]+),turn=([\d.]+)\}',
        layout):
        anchors[name]=(parent,float(radius),float(turn))
    points={"star":(0,0)}
    def point(name):
        if name not in points:
            parent,r,t=anchors[name]
            x,y=point(parent)
            points[name]=(x+r*math.sin(math.tau*t),y-r*math.cos(math.tau*t))
        return points[name]
    return anchors,point

def clearance(center,a,b):
    vx,vy=b[0]-a[0],b[1]-a[1]
    t=max(0,min(1,(-((a[0]-center[0])*vx+(a[1]-center[1])*vy) /
      (vx*vx+vy*vy))))
    return math.dist(center,(a[0]+vx*t,a[1]+vy*t))

def intersects(a,b,c,d):
    def area(p,q,r):
        return (q[0]-p[0])*(r[1]-p[1])-(q[1]-p[1])*(r[0]-p[0])
    return area(a,b,c)*area(a,b,d)<-1e-7 and area(c,d,a)*area(c,d,b)<-1e-7

class OuterMap(unittest.TestCase):
    def test_four_worlds_have_real_system_parents_and_clear_routes(self):
        anchors,point=geometry()
        worlds={
            "athos":("solaris","vulcanus",15),
            "ferrum":("beetlejuice","sye-beetlejuice",20),
            "obsidiax":("umbra","vesta",39),
            "shchierbin":("vibrant","paracelsin",39)
        }
        reconciliation=read("prototypes/system/route_reconcile.lua")
        approved=read("prototypes/system/route_authority.lua")
        all_routes=[]
        for source in (reconciliation,approved):
            for a,b,km,profile in re.findall(
                r'\{"([^"]+)","([^"]+)",(\d+),"([\w_]+)"\}',source):
                if a in anchors and b in anchors:
                    all_routes.append((a,b))
        for name,(star,hub,min_clear) in worlds.items():
            with self.subTest(world=name):
                self.assertEqual(anchors[name][0],star)
                self.assertIn(f'{{"{name}","{hub}",',approved)
                self.assertGreater(clearance(point(star),point(name),point(hub)),
                                   min_clear-.1)
                for a,b in all_routes:
                    if len({name,hub,a,b})!=4: continue
                    self.assertFalse(intersects(point(name),point(hub),
                                                point(a),point(b)),
                                     f"{name}-{hub} intersects {a}-{b}")

    def test_short_map_labels_and_no_red_streaks(self):
        names=read("locale/en/names.cfg")
        section=names.split("[space-location-name]",1)[1].split("\n[",1)[0]
        for name in ("umbra","sye-umbra","razi-umbra-belt-inner",
                     "razi-umbra-belt-outer"):
            match=re.search(rf"(?m)^{re.escape(name)}=(.+)$",section)
            self.assertIsNotNone(match,name)
            self.assertLess(len(match.group(1)),46,name)
        self.assertIn("[space-location-description]",names)
        layout=read("prototypes/system/galaxy_layout.lua")
        self.assertIn('for _,name in ipairs({"carna","velora"})',layout)
        self.assertIn("remove_baked_source_trails()",layout)
        self.assertIn('layer.planetslib_orbit_name=="carna"',layout)
        self.assertIn('layer.planetslib_orbit_name=="velora"',layout)
        highlights=read("prototypes/system/route_highlights.lua")
        self.assertIn('{"carna","gleba","velora"}',highlights)

    def test_system_ownership_and_native_science_keep_their_order(self):
        atlas=read("scripts/galactic_catalog.lua")
        authority=read("prototypes/system/route_authority.lua")
        community=read("prototypes/system/community_expansions.lua")
        optional=read("prototypes/system/optional_planets.lua")
        journal=read("scripts/razi_journal_expansion.lua")
        bridge=read("prototypes/technology/regional_research_bridges.lua")
        self.assertIn('"frozeta","ferrum","planet-ferrum"',atlas)
        self.assertIn('"carna","arcanyx","obsidiax"',atlas)
        self.assertIn('{"ferrum","sye-beetlejuice",22500',authority)
        self.assertIn('{"obsidiax","vesta",19000',authority)
        self.assertIn('gate="beetlejuice-discovery", hub="sye-beetlejuice"',community)
        self.assertIn('"obsidiax", "obsidiax", "umbra", "vesta", "umbra-discovery"',optional)
        self.assertIn('world="ferrum",requires={"beetlejuice-gate"}',journal)
        self.assertIn('world="obsidiax",requires={"umbra-gate"}',journal)
        self.assertNotIn('worlds={"cerys","obsidiax"}',bridge)
        self.assertIn("migrating_ferrum",read("prototypes/system/route_reconcile.lua"))
        self.assertIn("profiles.preserve_custom(target,route)",authority)

if __name__=="__main__":
    unittest.main()
