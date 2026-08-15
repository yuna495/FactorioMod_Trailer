local TECHNOLOGY_ICON = "__Trailer__/graphics/technology/technology.png"

local function red_green_unit(count)
  return {
    count = count,
    ingredients = {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1}
    },
    time = 30
  }
end

local function unlock(recipe)
  return {
    type = "unlock-recipe",
    recipe = recipe
  }
end

data:extend({
  {
    type = "technology",
    name = "trailer-head",
    localised_name = {"technology-name.trailer-head"},
    localised_description = {"technology-description.trailer-head"},
    icon = TECHNOLOGY_ICON,
    icon_size = 128,
    prerequisites = {"automobilism"},
    effects = {
      unlock("trailer-head")
    },
    unit = red_green_unit(100),
    order = "e-c-a[trailer-head]"
  },
  {
    type = "technology",
    name = "double-trailer-head",
    localised_name = {"technology-name.double-trailer-head"},
    localised_description = {"technology-description.double-trailer-head"},
    icon = TECHNOLOGY_ICON,
    icon_size = 128,
    prerequisites = {"trailer-head"},
    effects = {
      unlock("double-trailer-head")
    },
    unit = red_green_unit(200),
    order = "e-c-b[double-trailer-head]"
  },
  {
    type = "technology",
    name = "triple-trailer-head",
    localised_name = {"technology-name.triple-trailer-head"},
    localised_description = {"technology-description.triple-trailer-head"},
    icon = TECHNOLOGY_ICON,
    icon_size = 128,
    prerequisites = {"double-trailer-head"},
    effects = {
      unlock("triple-trailer-head")
    },
    unit = red_green_unit(300),
    order = "e-c-c[triple-trailer-head]"
  },
  {
    type = "technology",
    name = "trailer-rail-war-rig",
    localised_name = {"technology-name.trailer-rail-war-rig"},
    localised_description = {"technology-description.trailer-rail-war-rig"},
    icon = TECHNOLOGY_ICON,
    icon_size = 128,
    prerequisites = {"automated-rail-transportation", "fluid-wagon"},
    effects = {
      unlock("trailer-rail-locomotive"),
      unlock("trailer-rail-cargo-wagon"),
      unlock("trailer-rail-fluid-wagon"),
      unlock("trailer-road-rails")
    },
    unit = red_green_unit(250),
    order = "c-g-c[trailer-rail-war-rig]"
  }
})
