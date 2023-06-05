--- @type Mq
local mq = require('mq')

local utils = require('utils')
local ignorePath = 'Consolidate/ignore.lua'
local givePath = 'Consolidate/tmp/give.lua'
local me = mq.TLO.Me.Name()
local pIgnorePath = 'Consolidate/ignore_'..me..'.lua'
local give = {}
local ignore = {}
local items = {}
items[me] = {}


local function loadfiles()
    local mygive, giveerror = loadfile(mq.configDir..'/'..givePath)
    if giveerror then
        print('\at[TsC]\ao Error loading give.lua')
        mq.exit()
    elseif mygive then
        give = mygive()
    end
    local pignoreList, pignoreerror = loadfile(mq.configDir..'/'..pIgnorePath)
    if pignoreerror then
        local ignoreList, ignoreerror = loadfile(mq.configDir..'/'..ignorePath)
        if ignoreerror then
            print('\at[TsC]\ao Error loading ignore.lua')
            mq.exit()
        elseif ignoreList then
            ignore = ignoreList()
        end
    elseif pignoreList then
        ignore = pignoreList()
    end
end
loadfiles()

print('\at[TsC]\ao Scanning items...')

--Scan this toon's inventory
local scope
if give['scope'] == 'all' then
    scope = 1
elseif give['scope'] == 'inventory' then
    scope = 4
end
utils.scan(me, scope, ignore, items)
mq.delay(1000)



if scope == 1 then
    print('\at[TsC]\ao Looking for items I need to grab.')
    mq.delay(3000)

    local shouldGrab
    local grabList = {}
    local function toGrab()
        for l,_ in pairs(items[me]) do
            local inBank = false
            for _,x in pairs(items[me][l]['locations']) do
                if string.match(x,"Bank") or string.match(x,"Personal") then
                    inBank = true
                end
            end
            if inBank == true then
                table.insert(grabList, l)
                shouldGrab = true
            end
        end
    end
    toGrab()

    for _,v in pairs(grabList) do
        print('\at[TsC]\ay '..v..'\ao needs to be picked up from the bank.')
    end

    if shouldGrab == true then
        utils.grab(grabList, true)
    end
end
mq.delay(1000)

local receiver = give['receiver']
for k,_ in pairs(items[me]) do
    local space
    mq.cmdf('/dquery %s -q Me.FreeInventory', receiver)
    mq.delay(500)
    space = tonumber(mq.TLO.DanNet.Q())
    print('\at[TsC]\ar '..receiver..' \ao has \ag '..space..' \ao free slots left.')
    if space > 0 then
        print('\at[TsC]\ao Giving \ay'..k..' \aoto \ar'..receiver)
        utils.trade(receiver, k)
    else
        mq.delay(2000)
        print('\at[TsC]\ao Uh oh, it appears \ar'..receiver..' \ay is out of inventory space!')
        break
    end
end

print('\at[TsC]\ao Done.')
mq.cmd('/dgt all Done giving.')