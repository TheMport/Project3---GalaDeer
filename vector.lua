local Vector = {}
Vector.__index = Vector

function Vector.new(x, y)
  return setmetatable({x = x or 0, y = y or 0}, Vector)
end

setmetatable(Vector, {
  __call = function(_, x, y) return Vector.new(x, y) end
})

return Vector
