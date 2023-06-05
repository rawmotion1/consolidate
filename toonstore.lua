--- @type Mq
local mq = require('mq')
local utils = require('utils')
local itemsPath = 'Consolidate/tmp/allitems.lua'
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
end
loadfiles()

print('\at[TsC]\ao Moving all inventory items to depot...')

utils.scan(me, 4, ignore, items)
        
local list = {}
        
for k,_ in pairs(items[me]) do
    table.insert(list, k)
end

utils.depot(list)