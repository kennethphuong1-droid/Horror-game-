local r = {} for _, child in script:GetChildren() do r[child.Name] = require(child) end return r
