--- @type Mq
local mq = require('mq')

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

print('\at[TsC]\ao Looking for items to bank...')

local shouldBank
local bankList = {}


local function toBank()
    for item,_ in pairs(items[me]) do
        local bank = false
        local inventory = false
        for k,v in pairs(items[me][item]['locations']) do
            if string.match(v, "Bank") then
                bank = true
            end
            if string.match(v, "General") then
                inventory = true
            end
        end
        if bank == true and inventory == true then
            local entry = {
                name = item,
                bank = bank,
            }
            table.insert(bankList, entry)
            shouldBank = true
        end
    end
end
toBank()

local function bank()
    local banker = mq.TLO.NearestSpawn('Banker').Name()
    mq.cmdf('/squelch /nav spawn %s', banker)
    while mq.TLO.Navigation.Active() do
        if mq.TLO.Spawn(banker).Distance() < 15 then
            mq.cmd('/squelch /nav stop')
            break
        end
    end
    while mq.TLO.Target.Name() ~= banker do
        mq.cmdf('/target %s', banker)
        mq.delay(2000)
    end
    while not mq.TLO.Window('BigBankWnd').Open() do
        mq.cmd('/usetarget')
        mq.delay(2000)
    end

    for k,v in pairs(bankList) do
        if v.bank == true then
            print('\at[TsC]\ao Putting \ay'..v.name..' \aoin the bank.')
            if mq.TLO.FindItemCount('='..v.name)() > 0 then
                repeat
                    while mq.TLO.Cursor() ~= v.name do
                        mq.cmdf('/itemnotify "%s" leftmouseup', v.name)
                        mq.delay(1000)
                        if mq.TLO.Window('QuantityWnd').Open() then
                            mq.cmd('/notify QuantityWnd QTYW_Accept_Button leftmouseup')
                            mq.delay(1000)
                        end
                    end
                    while mq.TLO.Cursor() do
                        mq.cmd('/notify BigBankWnd BIGB_AutoButton leftmouseup')
                        mq.delay(1000)
                    end
                until mq.TLO.FindItemCount('='..v.name)() == 0
            end
        end
    end
    print('\at[TsC]\ao Done putting items in the bank.')
end

if shouldBank == true then
    bank()
end

local shouldDepot
local depotList = {}

local function toDepot()
    for item,_ in pairs(items[me]) do
        local depot = false
        local inventory = false
        for k,v in pairs(items[me][item]['locations']) do
            if string.match(v, "Personal") then
                depot = true
            end
            if string.match(v, "General") then
                inventory = true
            end
        end
        if depot == true and inventory == true then
            local entry = {
                name = item,
                depot = depot,
            }
            table.insert(depotList, entry)
            shouldDepot = true
        end
    end
end
toDepot()

local function depot()
    local banker = mq.TLO.NearestSpawn('Banker').Name()
    mq.cmdf('/squelch /nav spawn %s', banker)
    while mq.TLO.Navigation.Active() do
        if mq.TLO.Spawn(banker).Distance() < 15 then
            mq.cmd('/squelch /nav stop')
            break
        end
    end
    while mq.TLO.Target.Name() ~= banker do
        mq.cmdf('/target %s', banker)
        mq.delay(2000)
    end
    while not mq.TLO.Window('BigBankWnd').Open() do
        mq.cmd('/usetarget')
        mq.delay(2000)
    end
    while not mq.TLO.Window('TradeskillDepotWnd').Open() do
        mq.cmd('/notify BigBankWnd BIGB_TradeskillDepot leftmouseup')
        mq.delay(2000)
    end
    print('\at[TsC]\ay Please hold your cursor over the TS depot window.')
    mq.delay(5000)
    for k,v in pairs(depotList) do
        if v.depot == true then
            print('\at[TsC]\ao Putting \ay'..v.name..' \aoin your depot.')
            if mq.TLO.FindItemCount('='..v.name)() > 0 then
                repeat
                    while mq.TLO.Cursor() ~= v.name do
                        mq.cmdf('/itemnotify "%s" leftmouseup', v.name)
                        mq.delay(1000)
                        if mq.TLO.Window('QuantityWnd').Open() then
                            mq.cmd('/notify QuantityWnd QTYW_Accept_Button leftmouseup')
                            mq.delay(1000)
                        end
                    end
                    while mq.TLO.Cursor() == v.name do
                        if mq.TLO.EverQuest.MouseX() > mq.TLO.Window('TradeskillDepotWnd').X() and mq.TLO.EverQuest.MouseX() < (mq.TLO.Window('TradeskillDepotWnd').X() + mq.TLO.Window('TradeskillDepotWnd').Width()) then
                            mq.cmd('/click left')
                            if mq.TLO.Window('ConfirmationDialogBox')() then
                                mq.cmd('/no')
                            end
                            mq.delay(1000)
                        else
                            print('\at[TsC]\ay Please hold your cursor over the TS depot window.')
                            mq.delay(3000)
                        end
                    end
                until mq.TLO.FindItemCount('='..v.name)() == 0
            end
        end
    end
    print('\at[TsC]\ao Done putting items in the depot.')
end

if shouldDepot == true then
    depot()
end

local shouldMove
local bankToDepotList = {}
local function toMove()
    for item,_ in pairs(items[me]) do
        local indepot = false
        local inbank = false
        for k,v in pairs(items[me][item]['locations']) do
            if string.match(v, "Personal") then
                indepot = true
            end
            if string.match(v, "Bank") then
                inbank = true
            end
        end
        if indepot == true and inbank == true then
            local entry = {
                name = item,
                depot = indepot,
                bank = inbank
            }
            table.insert(bankToDepotList, entry)
            shouldMove = true
        end
    end
end
toMove()

local function move()
    print('\at[TsC]\ao Looking for items to move from bank to depot.')
    local banker = mq.TLO.NearestSpawn('Banker').Name()
    mq.cmdf('/squelch /nav spawn %s', banker)
    while mq.TLO.Navigation.Active() do
        if mq.TLO.Spawn(banker).Distance() < 15 then
            mq.cmd('/squelch /nav stop')
            break
        end
    end
    while mq.TLO.Target.Name() ~= banker do
        mq.cmdf('/target %s', banker)
        mq.delay(2000)
    end
    while not mq.TLO.Window('BigBankWnd').Open() do
        mq.cmd('/usetarget')
        mq.delay(2000)
    end
    while not mq.TLO.Window('TradeskillDepotWnd').Open() do
        mq.cmd('/notify BigBankWnd BIGB_TradeskillDepot leftmouseup')
        mq.delay(2000)
    end


    mq.cmd('/invoke ${Window[FindItemWnd].DoOpen}')
    mq.delay(2000)
    mq.cmd('/notify FindItemWnd FIW_Default leftmouseup')
    mq.delay(2000)
    mq.cmd('/notify FindItemWnd FIW_ItemLocationCombobox listselect 2')
    mq.delay(2000)
    mq.cmd('/notify FindItemWnd FIW_ItemTypeCombobox listselect 41')
    mq.delay(2000)
    if mq.TLO.Window('FindItemWnd').Child('FIW_SearchDepotButton').Checked() then
        mq.cmd('/notify FindItemWnd FIW_SearchDepotButton leftmouseup')
        mq.delay(2000)
    end
    mq.cmd('/notify FindItemWnd FIW_QueryButton leftmouseup')
    mq.delay(3000)

    local listSize = mq.TLO.Window('FindItemWnd').Child('FIW_ItemList').Items()
    print('\at[TsC]\ao Grabbing items from bank to put into depot...')
    for i=listSize, 1, -1 do
        mq.delay(10)
        local row = mq.TLO.Window('FindItemWnd').Child('FIW_ItemList').List(i,2)()
        mq.cmdf('/notify FindItemWnd FIW_ItemList listselect %s', i)
        for _,v in pairs(bankToDepotList) do
            mq.delay(10)
            if row == v.name then
                mq.delay(3000)
                mq.cmd('/notify FindItemWnd FIW_GrabButton leftmouseup')
                mq.delay(3000)
                if mq.TLO.Window('QuantityWnd').Open() then
                    mq.cmd('/notify QuantityWnd QTYW_Accept_Button leftmouseup')
                    mq.delay(3000)
                end
                while mq.TLO.Cursor() do
                    mq.cmd('/autoinv')
                    mq.delay(1000)
                end
            end
        end
    end


    print('\at[TsC]\ay Please hold your cursor over the TS depot window.')
    mq.delay(5000)
    for k,v in pairs(bankToDepotList) do
        if v.depot == true and v.bank == true then
            print('\at[TsC]\ao Putting \ay'..v.name..' \aoin your depot.')
            if mq.TLO.FindItemCount('='..v.name)() > 0 then
                repeat
                    while mq.TLO.Cursor() ~= v.name do
                        mq.cmdf('/itemnotify "%s" leftmouseup', v.name)
                        mq.delay(1000)
                        if mq.TLO.Window('QuantityWnd').Open() then
                            mq.cmd('/notify QuantityWnd QTYW_Accept_Button leftmouseup')
                            mq.delay(1000)
                        end
                    end
                    while mq.TLO.Cursor() == v.name do
                        if mq.TLO.EverQuest.MouseX() > mq.TLO.Window('TradeskillDepotWnd').X() and mq.TLO.EverQuest.MouseX() < (mq.TLO.Window('TradeskillDepotWnd').X() + mq.TLO.Window('TradeskillDepotWnd').Width()) then
                            mq.cmd('/click left')
                            if mq.TLO.Window('ConfirmationDialogBox')() then
                                mq.cmd('/no')
                            end
                            mq.delay(1000)
                        else
                            print('\at[TsC]\ay Please hold your cursor over the TS depot window.')
                            mq.delay(3000)
                        end
                    end
                until mq.TLO.FindItemCount('='..v.name)() == 0
            end
        end
    end
    print('\at[TsC]\ao Done moving items from bank to depot.')
end

if shouldMove == true then
    move()
end
print('\at[TsC]\ao Done with banking on this toon.')
mq.cmd('/dgt all Done banking.')