# Solar2D - LiveEdit

Enhance your development process with LiveEdit, a dynamic tool that allows for real-time editing of variables and objects in Solar2D projects. This capability streamlines the development and debugging process by enabling on-the-fly adjustments.

## Installation

1. **Download:** Obtain the `LiveEdit.lua` file from this repository.
2. **Add to Project:** Incorporate the file into your Solar2D project.
3. **Include in Code:** Import `LiveEdit.lua` in your `main.lua` or in other Lua files where debugging is required.

    ```lua
    require("LiveEdit")
    ```

## Usage

Insert the following line at the desired points in your code to live stream the variables and manipulate them in real-time.

```lua
liveEdit(fn)
```

- `fn` (function): A callback function that allows you to manipulate variables live as the application runs.

### How it Works

When you activate LiveEdit, you can modify the attributes of existing variables on-the-fly. However, remember that the scope of variables is predetermined once the file is loaded; you cannot introduce new variables within the liveEdit context.

Important: Changes made via LiveEdit accumulate, so continuous adjustments like transitions must be managed carefully to avoid unintended behavior (e.g., make sure to stop a transition before initiating another).

### Example Usage

```lua
local circle = display.newCircle(100, 100, 10)
circle:setFillColor(1, 0, 0)
transition.loop(circle, {
    time       = 1000,
    x          = 200,
    iterations = 0,
    transition = easing.inOutSine,
})


liveEdit(function()
    circle.y = math.random(100, 300) -- change the position
    circle:setFillColor(math.random(), math.random(), math.random()) -- change the color
end)
```

## Ownership and License

**Creator**: Depilz  
**Company**: Studycat Limited  
This tool is distributed as open-source under the MIT License, allowing for modification and redistribution. We encourage enhancements and would love to see how you adapt it for your needs.
