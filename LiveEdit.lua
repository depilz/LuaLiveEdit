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
