-- SETUP ---------------------------------------------------------------------------------------------------------------

display.setDefault("background", 1)

------------------------------------------------------------------------------------------------------------------------
-- RUN GAME --
------------------------------------------------------------------------------------------------------------------------

require("LiveEdit")

local circle = display.newCircle(100, 100, 10)
circle:setFillColor(1, 0, 0)
transition.loop(circle, {
    time       = 1000,
    x          = 200,
    iterations = 0,
    transition = easing.inOutSine,
})


liveEdit(function()
    -- save this file to see the changes
    circle.y = math.random(100, 300)
    circle:setFillColor(math.random(), math.random(), math.random())
end)

