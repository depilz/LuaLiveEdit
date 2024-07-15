local projectRoot = system.pathForFile("", system.ResourceDirectory)

local function getlocalsAtLevel(level, locals)
    local i = 1
    while true do
        local name, value = debug.getlocal(level, i)
        if not name then break end
        if locals[name] == nil then
            locals[name] = value
        end
        i = i + 1
    end
end

local function getLocals(level)
    local locals = {}
    local success, l
    repeat
        success, l = pcall(getlocalsAtLevel, level, locals)
        level = level + 1
    until not success

    return locals
end

local function getUpvalues(f)
    local i = 1
    local upvalues = {}
    while true do
        local name, value = debug.getupvalue(f, i)
        if not name then break end
        upvalues[name] = value
        i = i + 1
    end
    return upvalues
end

local function getEnv(f)
    -- lets save all the local values from the original function
    local locals = getLocals(6)
    local upvalues = getUpvalues(f)

    local env = {}
    -- let's set the globals
    for k, v in pairs(_G) do
        env[k] = v
    end
    
    -- let's set the locals
    for k, v in pairs(locals) do
        env[k] = v
    end

    -- let's set the upvalues
    for k, v in pairs(upvalues) do
        env[k] = v
    end

    return env
end


-- Global live edit function -------------------------------------------------------------------------------------------

function _G.liveEdit(f)
    local env = getEnv(f)

    local file = debug.getinfo(f, "S").source
        :gsub(projectRoot, "")
        :sub(2)

    local absPath = system.pathForFile(file)

    local function reload()
        -- let's find the liveEdit call in the file
        -- local absPath = system.pathForFile(file)

        local f = io.open(absPath, "r")
        local content = f:read("*all")
        f:close()

        local liveEditCall = content:match("liveEdit%(%s*function%s*%(%s*%)(.-)end%s*%)")
        if liveEditCall then
            local f = loadstring(liveEditCall)
            
            setfenv(f, env)

            local success, err = pcall(f)
            if not success then
                print("ERROR: " .. err)
            end
        end

    end

    local lfs = require("lfs")
    local lastModified = lfs.attributes(absPath).modification
    local function watch()
        local absPath = system.pathForFile(file)
        timer.performWithDelay(1000, function()
            local modified = lfs.attributes(absPath).modification
            if modified ~= lastModified then
                lastModified = modified
                reload()
            end
        end, 0)
    end

    watch()

    f()
end


-- Live edit target selection ------------------------------------------------------------------------------------------

local targets = {}
_G.setHook = function(obj)
    table.insert(targets, obj)
end

_G.removeHook = function(obj)
    for i, target in ipairs(targets) do
        if target == obj then
            table.remove(targets, i)
            break
        end
    end
end


local edit = require("edit")
local prevEdit = string.dump(edit)
timer.performWithDelay(500, function()
    if targets[1] then
        local edit = require("edit")

        -- convert function to string
        local str = string.dump(edit)
        if str ~= prevEdit then
            for i, target in ipairs(targets) do
                edit(target)
            end
        end
        prevEdit = str

        -- unrequire
        package.loaded.edit = nil
    end
end, 0)






-- Called when a mouse event has been received.
local level
local dy = 0
local target
local box
local text

local function distance( child, x2, y2 )
    local x1, y1 = child:localToContent(0, 0)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt( dx*dx + dy*dy )
end

local function isInside( x, y, bounds )
    return x >= bounds.xMin and x <= bounds.xMax and y >= bounds.yMin and y <= bounds.yMax
end

local function getAllChildrenAt(group, x, y, children, depth)
    children = children or {}
    depth = depth or 0

    for i = 1, group.numChildren do
        local child = group[i]
        if child.isVisible and child.alpha > 0 and isInside( x, y, child.contentBounds ) then
            if child ~= box and child ~= text and distance(child, x, y) < 80 then
                table.insert(children, {depth, child})
            end

            if (child.numChildren or 0) > 0 then
                children = getAllChildrenAt(child, x, y, children, depth + 1)
            end
        end
    end
    return children
end

local stage = display.getCurrentStage()
local function getTargetAt( x, y, level)
    local children = getAllChildrenAt(stage, x, y)
    table.sort(children, function(a, b) return a[1] < b[1] end)
    
    return children[level] and children[level][2]
end


local function getTypeOf(obj)
    if obj.skeleton then
        return "spine"
    elseif obj.setFrame then
        return "sprite"
    elseif obj.text then
        return "text"
    elseif obj.numChildren then
        return "displayGroup"
    elseif obj.path then
        if obj.path.radius and obj.path.height then
            return "roundedRect"
        elseif obj.path.radius then
            return "circle"
        elseif obj.append then
            return "line"
        elseif obj.path.x1 then
            return "rect"
        else
            return "polygon"
        end
    else
        return "displayObject"
    end
end

local function getTargetName(target)
    return target.__name__
        or target.name
        or target.id
        or target.alias
        or "Unknown"
end

local prevX, prevY
local function touch(e)
    if not target.parent then return end

    if e.phase == "began" or not prevX then
        prevX, prevY = e.x, e.y
        stage:setFocus(e.target)

    elseif e.phase == "moved" then
        local dx, dy = e.x - prevX, e.y - prevY
        box.x, box.y = box.x + dx, box.y + dy
        
        local sx0, sy0 = target.parent:contentToLocal(prevX, prevY)
        local sx1, sy1 = target.parent:contentToLocal(e.x, e.y)
        local dx, dy = sx1 - sx0, sy1 - sy0
        target.x, target.y = target.x + dx, target.y + dy
        
        prevX, prevY = e.x, e.y
    else
        stage:setFocus(nil)
        prevX, prevY = nil, nil
        print("x", target.x, "y", target.y)
    end

    return true
end


local function updateBox(target)
    display.remove(box)
    display.remove(text)

    if target then
        local bounds = target.contentBounds
        box = display.newRect( (bounds.xMin + bounds.xMax)/2, (bounds.yMin + bounds.yMax)/2, bounds.xMax - bounds.xMin, bounds.yMax - bounds.yMin )
        box:setFillColor(1, .15)

        local type = getTypeOf(target)

        text = display.newText({
            text     = type .. ": " .. getTargetName(target),
            x        = box.x,
            y        = box.y - box.height/2 - 10,
            fontSize = 12,
            font     = native.systemFont,
        })

        if type == "spine" then 
            -- animation
            box:setStrokeColor(1, 0, 1)
            text:setFillColor(1, 0, 1)

        elseif type == "text" or type == "sprite" then 
            -- special objects
            box:setStrokeColor(0, 1, 0)
            text:setFillColor(0, 1, 0)

        elseif type == "displayGroup" then
            -- group
            box:setStrokeColor(0, 0, 1)
            text:setFillColor(0, 0, 1)

        else 
            -- all other objects
            box:setStrokeColor(0)
            text:setFillColor(0)

        end

        box.strokeWidth = 2
        box:addEventListener("touch", touch)
    end

end

local function printSelected(target)
    if target then
        print(("- Selected %s: %s"):format(getTypeOf(target), getTargetName(target)))
    else
        print("- No target selected")
    end
end

local function updateTarget(x, y, level)
    local newTarget = getTargetAt(x, y, level)

    if newTarget ~= target then
        target = newTarget
        updateBox(target)
        printSelected(target)
    end
end

local function removeTarget()
    if not target then return end
    removeHook(target)
end

local function setTarget(target)
    box.isHitTestable = true
    setHook(target)
end

Runtime:addEventListener( "lateUpdate", function()
    if target then
        local bounds = target.contentBounds
        box.x, box.y = (bounds.xMin + bounds.xMax)/2, (bounds.yMin + bounds.yMax)/2
        box.width, box.height = bounds.xMax - bounds.xMin, bounds.yMax - bounds.yMin

        text.x, text.y = box.x, box.y - box.height/2 - 10
    end
end)


local function onKeyEvent( event )
    if event.keyName == "leftShift" or event.keyName == "rightShift" then
        if event.phase == "down" then
            removeTarget()
            level = 1 -- start at level 3
        elseif event.phase == "up" then
            if target then
                setTarget(target)
            end
            level = nil
        end
    end
end
Runtime:addEventListener( "key", onKeyEvent )

local function onMouseEvent( event )
    if level and event.type == "scroll" then
        dy = dy + event.scrollY
        if dy > 4 then
            level = level + 1
            dy = 0
        elseif dy < -4 then
            level = math.max(1, level - 1)
            dy = 0
        end

        if dy == 0 then
            updateTarget(event.x, event.y, level)
        end
    end
    return true
end
Runtime:addEventListener( "mouse", onMouseEvent )
