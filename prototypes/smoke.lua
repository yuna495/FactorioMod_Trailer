local trivial_smoke = require("__base__/prototypes/entity/smoke-animations.lua").trivial_smoke

data:extend({
  trivial_smoke{
    name = "trailer-warrig-smoke",
    color = {r = 0.01, g = 0.01, b = 0.01, a = 1},
    duration = 180,
    spread_duration = 180,
    fade_away_duration = 180,
    start_scale = 0.1,
    end_scale = 1.0
  }
})
