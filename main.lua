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

local text = display.newText({
    text     = 
[[Shift scroll over the target you want to select and move it around.
You can also edit it in the edit.lua file.

Live edit the moving purple circle in the liveEdit function in main.lua]],
    x        = display.contentCenterX,
    y        = 50,
    fontSize = 14,
    align    = "center",
    font     = native.systemFont,
})
text:setFillColor(0)

for i = 1, 10 do
    local circle = display.newCircle(math.random(100, 300), math.random(100, 300), 10)
    circle:setFillColor(0, 1, 0)
end

liveEdit(function()
    -- save this file to see the changes
    circle.y = math.random(100, 300)
    circle:setFillColor(math.random(), math.random(), math.random())
end)

