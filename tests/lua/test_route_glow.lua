-- Route art should reuse the original texture for bloom, halo, and spine.
package.path="./?.lua;./?/init.lua;"..package.path
local highlights=require("prototypes.system.route_highlights")
local guide={filename="source-guide.png",size={245,541},
  shift={-100,800},kind="middle"}
for _,mode in ipairs({"subtle","clear"}) do
  local layers=highlights.layers_for_guide(guide,{r=.3,g=.7,b=.9},mode)
  assert(#layers==3,"Each guide needs bloom, halo, and spine")
  for _,layer in ipairs(layers) do
    assert(layer.filename==guide.filename,"No new art source allowed")
    assert(layer.shift==guide.shift,"Guide centre moved")
  end
  assert(layers[1].scale>layers[2].scale and
    layers[2].scale>layers[3].scale,"Glow must fall toward the centre")
  assert(layers[1].tint.a<layers[2].tint.a and
    layers[2].tint.a<layers[3].tint.a,"Halo must be softer than spine")
  assert(layers[3].scale==4,"Route spine must match original geometry")
end
local plain=highlights.layers_for_guide(guide,{r=.3,g=.7,b=.9},"subtle")
guide.kind="belt"
local belt=highlights.layers_for_guide(guide,{r=.3,g=.7,b=.9},"subtle")
assert(belt[3].tint.a>plain[3].tint.a,
  "Actual asteroid crossings need a stronger warning")
guide.kind="first"
local first=highlights.layers_for_guide(guide,{r=.3,g=.7,b=.9},"subtle")
assert(first[3].tint.a<plain[3].tint.a,
  "Early system routes must remain visually quieter")
print("Starmap route light tests passed")
