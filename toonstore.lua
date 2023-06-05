--- @type Mq
local mq = require('mq')
local utils = require('utils')
local itemsPath = 'Consolidate/tmp/allitems.lua'
local ignorePath = 'Consolidate/ignore.lua'
local me = mq.TLO.Me.Name()
local items = {}
local ignore = {}

local function loadfiles()
    local allitems, itemerror = loadfile(mq.configDir..'/'..itemsPath)
    if itemerror then
        print('Error loading allitems.lua')
        mq.exit()
    elseif allitems then
        items = allitems()
    end
    local ignoreList, ignoreerror = loadfile(mq.configDir..'/'..ignorePath)
    if ignoreerror then
        print('\at[TsC]\ao Error loading ignore.lua')
        mq.exit()
    elseif ignoreList then
        ignore = ignoreList()
    end
end
loadfiles()

print('\at[TsC]\ao Moving all inventory items to depot...')

utils.scan(me, 4, ignore, items)

local list = {}

local stuffToBank = false
for k,_ in pairs(items[me]) do
    table.insert(list, k)
    stuffToBank = true
end

if stuffToBank == true then
    utils.depot(list)
end