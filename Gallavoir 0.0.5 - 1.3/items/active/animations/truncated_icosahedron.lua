require "/scripts/vec2.lua"
require "/scripts/util.lua"

-- VERY truncated.

function init()
  self.rot = {0, 0, math.acos(-math.sqrt(5) / 3) / 2}
  
  self.rotdelta = {0, 0, (math.pi / 60) * 1}
  
  self.deltat = 0
  
  self.phi = 1.618
  
  local a = self.phi * 3
  local b = self.phi ^ 3
  local c = self.phi + 2
  local d = self.phi * 2
  local e = self.phi
  
  local mult = self.phi/3
  
  self.polys = {--[[
    {{ 1,  0, -a}, { 2, -e, -b}, { c, -1, -d}, { c,  1, -d}, { 2,  e, -b}},]]
    {{ 1,  0,  a}, { 2,  e,  b}, { c,  1,  d}, { c, -1,  d}, { 2, -e,  b}}, --
    {{-1,  0,  a}, {-2, -e,  b}, {-c, -1,  d}, {-c,  1,  d}, {-2,  e,  b}}, --[[
    {{-1,  0, -a}, {-2,  e, -b}, {-c,  1, -d}, {-c, -1, -d}, {-2, -e, -b}},
    {{ a,  1,  0}, { b,  2,  e}, { d,  c,  1}, { d,  c, -1}, { b,  2, -e}},
    {{ 0,  a,  1}, { e,  b,  2}, { 1,  d,  c}, {-1,  d,  c}, {-e,  b,  2}},
    {{-a,  1,  0}, {-b,  2, -e}, {-d,  c, -1}, {-d,  c,  1}, {-b,  2,  e}},
    {{ 0,  a, -1}, {-e,  b, -2}, {-1,  d, -c}, { 1,  d, -c}, { e,  b, -2}},
    {{-a, -1,  0}, {-b, -2,  e}, {-d, -c,  1}, {-d, -c, -1}, {-b, -2, -e}},
    {{ 0, -a, -1}, { e, -b, -2}, { 1, -d, -c}, {-1, -d, -c}, {-e, -b, -2}},
    {{ a, -1,  0}, { b, -2, -e}, { d, -c, -1}, { d, -c,  1}, { b, -2,  e}},]]
    {{ 0, -a,  1}, {-e, -b,  2}, {-1, -d,  c}, { 1, -d,  c}, { e, -b,  2}}, --[[
    {{ b,  2, -e}, { a,  1,  0}, { a, -1,  0}, { b, -2, -e}, { c, -1, -d}, { c,  1, -d}},
    {{ b, -2,  e}, { a, -1,  0}, { a,  1,  0}, { b,  2,  e}, { c,  1,  d}, { c, -1,  d}},
    {{-b,  2,  e}, {-a,  1,  0}, {-a, -1,  0}, {-b, -2,  e}, {-c, -1,  d}, {-c,  1,  d}},
    {{-b, -2, -e}, {-a, -1,  0}, {-a,  1,  0}, {-b,  2, -e}, {-c,  1, -d}, {-c, -1, -d}},
    {{ 2,  e, -b}, { 1,  0, -a}, {-1,  0, -a}, {-2,  e, -b}, {-1,  d, -c}, { 1,  d, -c}},
    {{-2, -e, -b}, {-1,  0, -a}, { 1,  0, -a}, { 2, -e, -b}, { 1, -d, -c}, {-1, -d, -c}},]]
    {{ 2, -e,  b}, { 1,  0,  a}, {-1,  0,  a}, {-2, -e,  b}, {-1, -d,  c}, { 1, -d,  c}}, --right invisible
    {{-2,  e,  b}, {-1,  0,  a}, { 1,  0,  a}, { 2,  e,  b}, { 1,  d,  c}, {-1,  d,  c}}, --[[
    {{ e,  b, -2}, { 0,  a, -1}, { 0,  a,  1}, { e,  b,  2}, { d,  c,  1}, { d,  c, -1}},
    {{-e,  b,  2}, { 0,  a,  1}, { 0,  a, -1}, {-e,  b, -2}, {-d,  c, -1}, {-d,  c,  1}},
    {{-e, -b, -2}, { 0, -a, -1}, { 0, -a,  1}, {-e, -b,  2}, {-d, -c,  1}, {-d, -c, -1}},
    {{ e, -b,  2}, { 0, -a,  1}, { 0, -a, -1}, { e, -b, -2}, { d, -c, -1}, { d, -c,  1}},
    {{ 1,  d, -c}, { e,  b, -2}, { d,  c, -1}, { b,  2, -e}, { c,  1, -d}, { 2,  e, -b}},
    {{ b,  2,  e}, { c,  1,  d}, { 2,  e,  b}, { 1,  d,  c}, { e,  b,  2}, { d,  c,  1}},
    {{-c,  1,  d}, {-2,  e,  b}, {-1,  d,  c}, {-e,  b,  2}, {-d,  c,  1}, {-b,  2,  e}},
    {{-b,  2, -e}, {-d,  c, -1}, {-e,  b, -2}, {-1,  d, -c}, {-2,  e, -b}, {-c,  1, -d}},]]
    {{-b, -2,  e}, {-d, -c,  1}, {-e, -b,  2}, {-1, -d,  c}, {-2, -e,  b}, {-c, -1,  d}}, --[[
    {{-1, -d, -c}, {-e, -b, -2}, {-d, -c, -1}, {-b, -2, -e}, {-c, -1, -d}, {-2, -e, -b}},
    {{ b, -2, -e}, { d, -c, -1}, { e, -b, -2}, { 1, -d, -c}, { 2, -e, -b}, { c, -1, -d}},]]
    {{ 1, -d,  c}, { e, -b,  2}, { d, -c,  1}, { b, -2,  e}, { c, -1,  d}, { 2, -e,  b}}  --
  }
  
  -- Good old rotate and transform.
  for i,poly in ipairs(self.polys) do
    for j,point in ipairs(poly) do
    
      point = rotate(point, self.rot[1], self.rot[2], self.rot[3])
      point = rotate(point, math.pi / 2, 0, 0)
      
      point[1] = point[1] * mult
      point[2] = point[2] * mult
      point[3] = point[3] * mult
    end
  end
end

function update()
  localAnimator.clearDrawables()
  local renderer = animationConfig.animationParameter("dodec") or false
  local doRender
  
  if type(renderer) == "table" then
    doRender = renderer.doRender
  else
    doRender = renderer or false
  end
  
  local polyPosition = activeItemAnimation.ownerPosition()
  local color = {128,128,255,16}
  local colorLine = {128,255,255,64}
  local colorLineBack = {64,128,128,48}
  
  
  if doRender then
    self.deltat = (self.deltat + 1) % 120
    
    local polygons = copy(self.polys)
    
    for i,poly in ipairs(polygons) do
      for j,point in ipairs(poly) do
        point = rotate(point, self.rotdelta[1] * self.deltat, self.rotdelta[2] * self.deltat, self.rotdelta[3] * self.deltat)
        if type(renderer) == "table" then point = rotate(point, renderer.rot[1], renderer.rot[2], renderer.rot[3]) end
      end
    end
    
    if type(renderer) == "table" then
      polyPosition = vec2.add(polyPosition, activeItemAnimation.handPosition(renderer.trans))
    end
    
    for id, poly in ipairs(polygons) do      
      localAnimator.addDrawable({poly = poly, color = color, position = polyPosition, fullbright = true})
      
      for i = 1, #poly do 
        j = i % #poly + 1
        if checkZ(poly[i], poly[j]) then 
          localAnimator.addDrawable({line = {poly[i], poly[j]}, width = 0.75, color = colorLine, position = polyPosition, fullbright = true})
        else
          localAnimator.addDrawable({line = {poly[i], poly[j]}, width = 0.75, color = colorLineBack, position = polyPosition, fullbright = true}, "Player-1")
        end
      end
    end
  end
end

function rotate(point, a, b, c)
  local x, y, z
  -- rot a
  x = point[1]
  y = point[2]
  point[1] = x * math.cos(a) - y * math.sin(a)
  point[2] = y * math.cos(a) + x * math.sin(a)
  -- rot b
  x = point[1]
  z = point[3]
  point[1] = x * math.cos(b) - z * math.sin(b)
  point[3] = z * math.cos(b) + x * math.sin(b)
  -- rot c
  y = point[2]
  z = point[3]
  point[2] = y * math.cos(c) - z * math.sin(c)
  point[3] = z * math.cos(c) + y * math.sin(c)
  
  return point
end

function checkZ(a, b)
  return a[3] >= -self.phi/2 and b[3] >= -self.phi/2
end


function util.toList(t)
end