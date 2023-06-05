--- @type Mq
local mq = require('mq')
local utils = require('utils')
local itemsPath = 'Consolidate/tmp/allitems.lua'
local me = mq.TLO.Me.Name()
local items = {}

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

print('\at[TsC]\ao Looking for items to move to bank/depot...')

local shouldBank
local shouldDepot
local shouldMove
local bankList = {}
local depotList = {}
local bankToDepotList = {}
local function toMove()
    for item,_ in pairs(items[me]) do
        local bank = false
        local inventory = false
        local depot = false
        for _,v in pairs(items[me][item]['locations']) do
            if string.match(v, "Bank") then
                bank = true
            end
            if string.match(v, "General") then
                inventory = true
            end
            if string.match(v, "Personal") then
                depot = true
            end
        end
        if inventory == true and bank == true and depot == false then
            table.insert(bankList, item)
            shouldBank = true
        elseif inventory == true --[[and bank == false]] and depot == true then
            table.insert(depotList, item)
            shouldDepot = true
        elseif inventory == false and bank == true and depot == true then
            table.insert(bankToDepotList, item)
            shouldMove = true
        end
    end
end
toMove()

if shouldBank == true then
    utils.bank(bankList)
end

if shouldDepot == true then
    utils.depot(depotList)
end

if shouldMove == true then
    utils.bankToDepot(bankToDepotList)
end

mq.cmd('/invoke ${Window[FindItemWnd].DoClose}')
mq.cmd('/notify BigBankWnd BIGB_DoneButton leftmouseup')
mq.cmd('/invoke ${Window[InventoryWindow].DoClose}')

print('\at[TsC]\ao Done with banking on this toon.')
mq.cmd('/dgt all Done banking.')