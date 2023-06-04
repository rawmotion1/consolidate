--- @type Mq
local mq = require('mq')
--Each toon will run this file

local itemsPath = 'Consolidate/tmp/allitems.lua'
local ignorePath = 'Consolidate/ignore.lua'
local me = mq.TLO.Me.Name()
local items = {}
local ignore = {}

local function loadfiles()
    local allitems, error = loadfile(mq.configDir..'/'..itemsPath)
    if error then
        print('\at[TsC]\ao Error loading allitems.lua')
        mq.exit()
    elseif allitems then
        items = allitems()
    end
    
    local ignoreList, err = loadfile(mq.configDir..'/'..ignorePath)
    if err then
        print('\at[TsC]\ao Error loading ignore.lua')
        mq.exit()
    elseif ignoreList then
        ignore = ignoreList()
    end
end
loadfiles()


print('\at[TsC]\ao Scanning items...')


--Scan this toon's inventory, bank, and depot
--Where 1=all 2=bank 4=inventory
local scanner = require('scanner')
scanner.scan(1, ignore, items)

--As result of inventory scan, consolidate stackable items in inventory, then rescan
local sort = require('sortbags')
sort.sortBags(items)


--If inventory items were consolidated, clear general table and rescan inventory
local rescan = sort.rescan()
if rescan == true then
    print('\at[TsC]\ao Items have moved. Rescanning bags...')
    for k,v in pairs(items[me]) do
        for l,w in pairs(items[me][k]['locations']) do
            if string.match(w, "General") then
                items[me][k]['locations'][l] = nil
            end
        end
    end
    scanner.scan(4, ignore, items)
end

mq.pickle(itemsPath, items)

print('\at[TsC]\ao Done with scanning on this toon.')
mq.cmd('/dgt all Done scanning.')
