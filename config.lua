local aspectRatio = display.pixelHeight / display.pixelWidth

_G.application = {
	content = {
		width = math.floor( 480 / aspectRatio ),
		height = 480,
		scale  = "zoomEven",
		fps    = 60,

		imageSuffix =
		{
				["@2x"] = 1.5, -- A good scale for iPhone 4 and iPad
				["@4x"] = 2,   -- A good scale for Retina
		}

	},
}
