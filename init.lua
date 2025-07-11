



local automarket = {}


function automarket:enable(config)
  local automarketUI = require("ui")
  automarketUI:initialize()
end

function automarket:disable()
end


return automarket