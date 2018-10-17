require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.arot = 0
  self.brot = 0
  self.crot = math.acos(-1/math.sqrt(5)) / 2
  
  self.rotdelta = math.pi / 60

  self.phi = 1.618
  
  local b = 1 / self.phi
  local c = 2 - self.phi
  
  local mult = 3
  
  self.polys = {
    {{ c,  0,  1},   {-c,  0,  1},   {-b,  b,  b},   { 0,  1,  c},   { b,  b,  b}},
    {{-c,  0,  1},   { c,  0,  1},   { b, -b,  b},   { 0, -1,  c},   {-b, -b,  b}},
    {{ c,  0, -1},   {-c,  0, -1},   {-b, -b, -b},   { 0, -1, -c},   { b, -b, -b}},
    {{-c,  0, -1},   { c,  0, -1},   { b,  b, -b},   { 0,  1, -c},   {-b,  b, -b}},
    {{ 0,  1, -c},   { 0,  1,  c},   { b,  b,  b},   { 1,  c,  0},   { b,  b, -b}},
    {{ 0,  1,  c},   { 0,  1, -c},   {-b,  b, -b},   {-1,  c,  0},   {-b,  b,  b}},
    {{ 0, -1, -c},   { 0, -1,  c},   {-b, -b,  b},   {-1, -c,  0},   {-b, -b, -b}},
    {{ 0, -1,  c},   { 0, -1, -c},   { b, -b, -b},   { 1, -c,  0},   { b, -b,  b}},
    {{ 1,  c,  0},   { 1, -c,  0},   { b, -b,  b},   { c,  0,  1},   { b,  b,  b}},
    {{ 1, -c,  0},   { 1,  c,  0},   { b,  b, -b},   { c,  0, -1},   { b, -b, -b}},
    {{-1,  c,  0},   {-1, -c,  0},   {-b, -b, -b},   {-c,  0, -1},   {-b,  b, -b}},
    {{-1, -c,  0},   {-1,  c,  0},   {-b,  b,  b},   {-c,  0,  1},   {-b, -b,  b}}
  }
  
  -- Good old rotate and transform.
  for i,poly in ipairs(self.polys) do
    for j,point in ipairs(poly) do
    
      point = rotate(point, self.arot, self.brot, self.crot)
      
      point[1] = point[1] * mult
      point[2] = point[2] * mult
      point[3] = point[3] * mult
      --self.zstore[i * #self.polys + j] = point[3]
      --point[3] = nil
    end
  end
end

function update()
  localAnimator.clearDrawables()
  local doRender = animationConfig.animationParameter("dodec") or false
  
  local polyPosition = activeItemAnimation.ownerPosition()
  local color = {200,128,255,16}
  local colorLine = {128,80,144,128}
  local colorLineBack = {72,48,92,32}
  
  if doRender then
    
    for i,poly in ipairs(self.polys) do
      for j,point in ipairs(poly) do
        point = rotate(point, 0, self.rotdelta, 0)
      end
    end
  
    for _,poly in ipairs(self.polys) do
      
      localAnimator.addDrawable({poly = poly, color = color, position = polyPosition, fullbright = true})
      
      for i = 1, #poly do 
        j = i % #poly + 1
        if checkZ(poly[i], poly[j]) then 
          localAnimator.addDrawable({line = {poly[i], poly[j]}, width = 1, color = colorLine, position = polyPosition, fullbright = true})
        else
          localAnimator.addDrawable({line = {poly[i], poly[j]}, width = 1, color = colorLineBack, position = polyPosition, fullbright = true}, "Player-1")
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
  return a[3] >= -self.phi and b[3] >= -self.phi
end