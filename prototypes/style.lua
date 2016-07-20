data.raw["gui-style"].default["wide_textbox_style_circuit_logger"] =
    {
      type = "textfield_style",
      parent = "textfield_style",      
   	  minimal_width = 300,
      maximal_width = 300,  
	}
  
data.raw["gui-style"].default["number_textbox_style_circuit_logger"] =
    {
      type = "textfield_style",
      parent = "textfield_style",      
   	  minimal_width = 50,
      maximal_width = 50,  
	}
  
  
data.raw["gui-style"].default["circuit-logger-button-main"] =
{
	type = "button_style",
	parent = "button_style",
	width = 47,
	height = 47,
  top_padding = 6,
  right_padding = 0,
  bottom_padding = 0,
  left_padding = 0,
	default_graphical_set =
	{
		type = "monolith",
		monolith_image =
		{
			filename = "__CircuitLogger__/graphics/gui.png",
			priority = "extra-high-no-scale",
			width = 50,
			height = 50,
			x = 0,
			y = 0,
		}
	},
	hovered_graphical_set =
	{
		type = "monolith",
		monolith_image =
		{
			filename = "__CircuitLogger__/graphics/gui.png",
			priority = "extra-high-no-scale",
			width = 50,
			height = 50,
			x = 50,
			y = 0,
		}
	},
	clicked_graphical_set =
	{
		type = "monolith",
		monolith_image =
		{
			filename = "__CircuitLogger__/graphics/gui.png",
			width = 50,
			height = 50,
			x = 50,
			y = 0,
		}
	},
	left_click_sound =
	{
		filename = "__core__/sound/gui-click.ogg",
		volume = 1
	},
}

data.raw["gui-style"].default["circuit-logger-button-main-on"] =
{
	type = "button_style",
	parent = "circuit-logger-button-main",
	width = 47,
	height = 47,
  top_padding = 6,
  right_padding = 0,
  bottom_padding = 0,
  left_padding = 0,
	default_graphical_set =
	{
		type = "monolith",
		monolith_image =
		{
			filename = "__CircuitLogger__/graphics/gui.png",
			priority = "extra-high-no-scale",
			width = 50,
			height = 50,
			x = 100,
			y = 0,
		}
	},
	hovered_graphical_set =
	{
		type = "monolith",
		monolith_image =
		{
			filename = "__CircuitLogger__/graphics/gui.png",
			priority = "extra-high-no-scale",
			width = 50,
			height = 50,
			x = 50,
			y = 0,
		}
	},
	clicked_graphical_set =
	{
		type = "monolith",
		monolith_image =
		{
			filename = "__CircuitLogger__/graphics/gui.png",
			width = 50,
			height = 50,
			x = 50,
			y = 0,
		}
	},
	left_click_sound =
	{
		filename = "__core__/sound/gui-click.ogg",
		volume = 1
	},
}
