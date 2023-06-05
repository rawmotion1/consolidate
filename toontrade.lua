--- @type Mq
local mq = require('mq')
local utils = require('utils')
local matchesPath = 'Consolidate/tmp/matches.lua'
local toonPath = 'Consolidate/toons.lua'
local me = mq.TLO.Me.Name()
local matches = {}
local toons = {}


local function loadfiles()
    local todo, actionerror = loadfile(mq.configDir..'/'..matchesPath)
    if actionerror then
        print('\at[TsC]\ao Error loading matches.lua')
        mq.exit()
    elseif todo then
        matches = todo()
    end
    local characters, toonerror = loadfile(mq.configDir..'/'..toonPath)
    if toonerror then
        print('\at[TsC]\ao Error loading toons.lua')
        mq.exit()
    elseif characters then
        toons = characters()
    end
end
loadfiles()

for _,toon in pairs(toons) do
    for item,v in pairs(matches[me]) do
        if toon.name ~= me and toon.name == v.receiver then
            local space
            mq.cmdf('/dquery %s -q Me.FreeInventory', v.receiver)
            mq.delay(500)
            space = tonumber(mq.TLO.DanNet.Q())
            print('\at[TsC]\ar '..v.receiver..' \ao has \ar'..space..' \ao slots left')
            if space > 0 then
                print('\at[TsC]\ao Giving \ay'..item..' \aoto \ar'..v.receiver)
                utils.trade(v.receiver, item)
            else
                mq.delay(2000)
                print('\at[TsC]\ao Uh oh, it appears \ar'..toon.name..' \ay is out of inventory space!')
            end
        end
    end
end
mq.delay(2000)
print('\at[TsC]\ao Done with trading on this toon.')
mq.cmd('/dgt all Done trading.')