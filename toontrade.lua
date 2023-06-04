--- @type Mq
local mq = require('mq')

local matchesPath = 'Consolidate/tmp/matches.lua'
local toonPath = 'Consolidate/toons.lua'
local spacePath = 'Consolidate/tmp/space.lua'
local matches = {}
local toons = {}
local space = {}

local me = mq.TLO.Me.Name()

local function loadfiles()
    local todo, error = loadfile(mq.configDir..'/'..matchesPath)
    if error then
        print('\at[TsC]\ao Error loading matches.lua')
        mq.exit()
    elseif todo then
        matches = todo()
    end
    local characters, err = loadfile(mq.configDir..'/'..toonPath)
    if err then
        print('\at[TsC]\ao Error loading toons.lua')
        mq.exit()
    elseif characters then
        toons = characters()
    end
    local myspace, spaceerror = loadfile(mq.configDir..'/'..spacePath)
    if spaceerror then
        print('\at[TsC]\ao Error loading space.lua')
        mq.exit()
    elseif myspace then
        space = myspace()
    end
end
loadfiles()


local function trade(name, item)
    if mq.TLO.FindItemCount('='..item)() > 0 then
        if mq.TLO.Spawn(name).Distance() >= 15 then
            mq.cmdf('/squelch /nav spawn %s', name)
        end
        while mq.TLO.Navigation.Active() do
            if mq.TLO.Spawn(name).Distance() < 15 then
                mq.cmd('/squelch /nav stop')
                break
            end
        end

        mq.delay(2000)

        repeat
            while mq.TLO.Cursor() ~= item do
                mq.cmdf('/itemnotify "%s" leftmouseup', item)
                mq.delay(1000)
                if mq.TLO.Window('QuantityWnd').Open() then
                    mq.cmd('/notify QuantityWnd QTYW_Accept_Button leftmouseup')
                    mq.delay(1000)
                end
            end
            
            while mq.TLO.Target.Name() ~= name do
                mq.cmdf('/target %s', name)
                mq.delay(2000)
            end
            
            while not mq.TLO.Window('TradeWnd').Open() do
                mq.cmd('/usetarget')
                mq.delay(2000)
            end
            repeat
                mq.cmd('/yes')
                mq.delay(2000)
            until not mq.TLO.Window('TradeWnd').Open()
            space[name] = space[name] - 1
        until mq.TLO.FindItemCount('='..item)() == 0
    end
end

for _,toon in pairs(toons) do
    for item,v in pairs(matches[me]) do
        if toon.name ~= me and toon.name == v.receiver then
            print('\at[TsC]\ao Giving \ay'..item..' \aoto \ar'..v.receiver)
            if space[toon.name] > 0 then
                trade(v.receiver, item)
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