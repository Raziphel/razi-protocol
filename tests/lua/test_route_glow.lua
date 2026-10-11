-- Route art should reuse the original texture for glow and sharp spine.
package.path="./?.lua;./?/init.lua;"..package.path
local highlights=require("prototypes.system.route_highlights")
local guide={filename="source-guide.png",size={245,541},shift={-100,800}}
for _,mode in ipairs({"subtle","clear"}) do
  local layers=highlights.layers_for_guide(guide,{r=.3,g=.7,b=.9},mode)
  assert(#layers==2,"Each guide needs just two layers")
  assert(layers[1].filename==guide.filename and
    layers[2].filename==guide.filename,"No new art source allowed")
  assert(layers[1].scale>layers[2].scale,"Glow must be wider")
  assert(layers[1].tint.a<layers[2].tint.a,"Glow should be fainter")
  assert(layers[1].shift==guide.shift and layers[2].shift==guide.shift,
    "Guide centre moved")
end
print("Starmap route light tests passed")
