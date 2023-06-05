--- @type Mq
local mq = require('mq')
--Each toon will run this file
local utils = require('utils')
local itemsPath = 'Consolidate/tmp/allitems.lua'
local ignorePath = 'Consolidate/ignore.lua'
local me = mq.TLO.Me.Name()
local items = {}
local ignore = {}

local function loadfiles()
    local allitems, itemerror = loadfile(mq.configDir..'/'..itemsPath)
    if itemerror then
        print('\at[TsC]\ao Error loading allitems.lua')
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

mq.cmd('/squelch /invoke ${Window[FindItemWnd].DoClose}')
mq.cmd('/squelch /notify BigBankWnd BIGB_DoneButton leftmouseup')
mq.cmd('/squelch /invoke ${Window[InventoryWindow].DoClose}')

print('\at[TsC]\ao Scanning items...')

--Scan this toon's inventory, bank, and depot
utils.scan(me, 1, ignore, items)

--As result of inventory scan, consolidate stackable items in inventory, then rescan
utils.sortBags(me, items, ignore)

mq.pickle(itemsPath, items)

print('\at[TsC]\ao Done with scanning on this toon.')
mq.cmd('/dgt all Done scanning.')
