--- @type Mq
local mq = require('mq')
local utils = require('utils')
local itemsPath = 'Consolidate/tmp/allitems.lua'
local matchesPath = 'Consolidate/tmp/matches.lua'
local me = mq.TLO.Me.Name()
local items = {}
local matches = {}

local function loadfiles()
    local allitems, itemerror = loadfile(mq.configDir..'/'..itemsPath)
    if itemerror then
        print('\at[TsC]\ao Error loading allitems.lua')
        mq.exit()
    elseif allitems then
        items = allitems()
    end
    local todo, actionerror = loadfile(mq.configDir..'/'..matchesPath)
    if actionerror then
        print('\at[TsC]\ao Error loading matches.lua')
        mq.exit()
    elseif todo then
        matches = todo()
    end
end
loadfiles()

print('\at[TsC]\ao Looking for items I need to grab.')
mq.delay(3000)

local shouldGrab
local grabList = {}
local function toGrab()
    for k,_ in pairs(matches[me]) do
        for l,_ in pairs(items[me]) do
            if k == l then
                local inBank = false
                for _,x in pairs(items[me][l]['locations']) do
                    if string.match(x,"Bank") or string.match(x,"Personal") then
                        inBank = true
                    end
                end
                if inBank == true then
                    table.insert(grabList, k)
                    shouldGrab = true
                end
            end
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

print('\at[TsC]\ao Done with grabbing on this toon.')
mq.cmd('/dgt all Done grabbing.')
