--TS Consolidator by Rawmotion
--v0.2.7
--- @type Mq
local mq = require('mq')
local main = require('mainroutine')
local toonPath = 'Consolidate/toons.lua'
local ignorePath = 'Consolidate/ignore.lua'

--Load settings
local toons = {}
local function loadSettings()
    local loadToons, toonerror = loadfile(mq.configDir..'/'..toonPath)
    if toonerror then
        local createToons = {'Toon1', 'Toon2', 'Toon3'}
        for k,v in pairs(createToons) do
            local toon = {
                name = v,
                give = true,
                receive = true,
                bankall = false
            }
            table.insert(toons, toon)
        end
        print('\at[TsC]\ao Creating Consolidate/toons.lua in your config folder.')
        print('\at[TsC]\ao Creating Consolidate/ignore.lua in your config folder.')
        print('\at[TsC]\ao Please edit these files and then run the script again.')
        local ignore = {}
        ignore[1] = 'Loaf of Bread'
        ignore[2] = 'Water Flask'
        mq.pickle(toonPath, toons)
        mq.pickle(ignorePath, ignore)
        mq.exit()
    elseif loadToons then
        toons = loadToons()
        if not toons[1].name then
            local temptoons = {}
            for k,v in pairs(toons) do
                local toon = {
                    name = v,
                    give = true,
                    receive = true,
                    bankall = false
                }
                toons[k] = nil
                table.insert(temptoons, toon)
            end
            toons = temptoons
            mq.pickle(toonPath, toons)
            print('\at[TsC]\ao Reformatting Consolidate/toons.lua in your config folder.')
        end
    end
end
loadSettings()

print('\at[TsC]\ao Welcome!')
print('\at[TsC]\ao Make sure all your toons are in the same zone.')
print('\at[TsC]\ao Make sure there is a banker nearby.')
print('\at[TsC]\ao When you\'re ready, type \ay/tsc go')

local function binds(a, b)
    if a == 'go' then
        main.go()
    end
end

mq.bind('/tsc', binds)

local terminate = false
while not terminate do
    mq.delay(1000)
end