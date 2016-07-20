require "prototypes/style"

data:extend({
  	{
		type = "item",
		name = "circuit-logger",
		icon = "__CircuitLogger__/graphics/circuit-logger-icon.png",
		flags = {"goes-to-quickbar"},
		subgroup = "circuit-network",
		order = "b[combinators]-l[circuit-logger]",
		place_result = "circuit-logger",
		stack_size = 50
	},
	
	{
		type = "recipe",
		name = "circuit-logger",
		enabled = "false",
		ingredients =
		{
			{"small-lamp", 1},
			{"advanced-circuit", 5}
		},
		result = "circuit-logger"
	},
	
	{
    type = "technology",
    name = "circuit-logger",
    icon = "__CircuitLogger__/graphics/circuit-logger-tech.png",
    effects =
    {
      {
        type = "unlock-recipe",
        recipe = "circuit-logger"
      }
    },
    prerequisites = {"circuit-network", "advanced-electronics"},
    unit =
    {
      count = 100,
      ingredients =
      {
        {"science-pack-1", 1},
        {"science-pack-2", 1}
      },
      time = 15
    },
    order = "a-d-d-z",
  },

	{
		type = "lamp",
		name = "circuit-logger",
		icon = "__CircuitLogger__/graphics/circuit-logger-icon.png",
		flags = {"placeable-neutral", "player-creation"},
		minable = {hardness = 0.2, mining_time = 0.5, result = "circuit-logger"},
		max_health = 55,
		corpse = "small-remnants",
		collision_box = {{-0.15, -0.15}, {0.15, 0.15}},
		selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
		vehicle_impact_sound =  { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65 },
		energy_source =
		{
		  type = "electric",
		  usage_priority = "secondary-input"
		},
		energy_usage_per_tick = "1KW",
		light = {intensity = 0, size = 0},
		picture_off =
		{
		  filename = "__CircuitLogger__/graphics/circuit-logger-off.png",
		  priority = "high",
		  frame_count = 1,
		  axially_symmetrical = false,
		  direction_count = 1,
		  width = 61,
		  height = 50,
		  shift = {0.078125, 0.15625},
		},
		picture_on =
		{
		  filename = "__CircuitLogger__/graphics/circuit-logger-on.png",
		  priority = "high",
		  frame_count = 1,
		  axially_symmetrical = false,
		  direction_count = 1,
		  width = 61,
		  height = 50,
		  shift = {0.078125, 0.15625},
		},
		
	
    circuit_wire_connection_point =
    {
      shadow =
      {
        red = {0.828125, 0.328125},
        green = {0.828125, -0.078125},
      },
      wire =
      {
        red = {0.515625, -0.078125},
        green = {0.515625, -0.484375},
      }
    },

		circuit_wire_max_distance = 7.5
	},
    
})

