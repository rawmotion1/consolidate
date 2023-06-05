--- @type Mq
local mq = require('mq')

local utils = {}

--Where 1=all 2=bank 4=inventory
function utils.scan(who, where, ignore, items)
    mq.cmd('/invoke ${Window[FindItemWnd].DoOpen}')
    mq.delay(500)
    mq.cmd('/notify FindItemWnd FIW_Default leftmouseup')
    mq.delay(500)
    mq.cmdf('/notify FindItemWnd FIW_ItemLocationCombobox listselect %s', where)
    mq.delay(500)
    mq.cmd('/notify FindItemWnd FIW_ItemTypeCombobox listselect 41')
    mq.delay(500)
    if not mq.TLO.Window('FindItemWnd').Child('FIW_SearchDepotButton').Checked() then
        mq.cmd('/notify FindItemWnd FIW_SearchDepotButton leftmouseup')
        mq.delay(500)
    end
    mq.cmd('/notify FindItemWnd FIW_QueryButton leftmouseup')
    mq.delay(3000)

    local listSize = mq.TLO.Window('FindItemWnd').Child('FIW_ItemList').Items()

    for i=1, listSize do
        local name = mq.TLO.Window('FindItemWnd').Child('FIW_ItemList').List(i,2)()
        local location = mq.TLO.Window('FindItemWnd').Child('FIW_ItemList').List(i,4)()

        local skip = false
        local item
        for _,v in pairs(ignore) do
            if v == name then skip = true end
        end
        if string.match(location, "General") then item = mq.TLO.FindItem('='..name)
        elseif string.match(location, "Bank") then item = mq.TLO.FindItemBank('='..name)
        elseif string.match(location, "Personal") then item = mq.TLO.TradeskillDepot.FindItem('='..name)
        else skip = true
        end

        if skip == false then
            if item.NoDrop() or item.Container() ~= 0 or not item.Stackable() then
                skip = true
            end
        end

        if skip == false then
            local inv = mq.TLO.FindItemCount('='..name)() or 0
            local bnk = mq.TLO.FindItemBankCount('='..name)() or 0
            local dpt = mq.TLO.TradeskillDepot.FindItemCount('='..name)() or 0
            local total = inv + bnk + dpt
                if not items[who][name] then
                    items[who][name] = {}
                    items[who][name].totalQty = total
                    items[who][name]['locations'] = {}
                    table.insert(items[who][name]['locations'], location)
                else
                    table.insert(items[who][name]['locations'], location)
                end
            print('\at[TsC]\ao Found \ay'..name)
        else
            print('\at[TsC]\ar Skipping \ay'..name) 
        end
        mq.delay(20)
    end
    mq.cmd('/invoke ${Window[FindItemWnd].DoClose}')
end


function utils.restack(item)
    print('\at[TsC]\ao Restacking \ay'..item)
    while mq.TLO.Cursor() do
        mq.cmd('/autoinv')
        mq.delay(50)
    end
    while mq.TLO.Cursor() ~= item do
        mq.cmdf('/shift /itemnotify \"%s\" leftmouseup', item)
        mq.delay(50)
        if mq.TLO.Window('QuantityWnd').Open() then
            mq.cmd('/notify QuantityWnd QTYW_Accept_Button leftmouseup')
            mq.delay(50)
        end
    end
    while mq.TLO.Cursor() do
        mq.cmd('/autoinv')
        mq.delay(50)
    end
end


function utils.sortBags(who, items, ignore)
    local inv = {}
    local rescan
    print('\at[TsC]\ao Checking for items to restack...')

    --If an inventory stack is less than max stack size, add it to inv table
    for m,_ in pairs(items[who]) do
        for _,x in pairs(items[who][m]['locations']) do
            if string.match(x, "General") then
                local stacks = mq.TLO.FindItem('='..m).Stacks()
                if stacks > 1 then
                    local max = mq.TLO.FindItem('='..m).StackSize()
                    local qty
                    local dash = string.match(x, "-")
                    local bag = 0
                    local slot
                    if dash then
                        bag = tonumber(string.match(x, "%s%d+")) or 0
                        slot = tonumber(string.match(x, "%d+$"))
                        qty = mq.TLO.Me.Inventory(bag+22).Item(slot).Stack()
                    else
                        slot = tonumber(string.match(x, "%s%d+"))
                        qty = mq.TLO.Me.Inventory(slot+22).Stack()
                    end
                    
                    if not inv[m] then
                        if qty < max then
                            inv[m] = stacks
                        else
                            inv[m] = 0
                        end
                    else
                        if qty == max then
                            inv[m] = 0
                        end
                    end
                    
                end
            end
        end
    end

    --Checks inv table for places where the same item is in more than one spot
    for k,v in pairs(inv) do
        if v > 0 then
            for i=1, v-1 do
                utils.restack(k)
                rescan = true
            end
        end
    end
    print('\at[TsC]\ao Done with restacking.')

    if rescan == true then
        print('\at[TsC]\ao Items have moved. Rescanning bags...')
        for k,_ in pairs(items[who]) do
            for l,w in pairs(items[who][k]['locations']) do
                if string.match(w, "General") then
                    items[who][k]['locations'][l] = nil
                end
            end
        end
        utils.scan(who, 4, ignore, items)
    end
end


function utils.grab(grabList, ts)
    local banker = mq.TLO.NearestSpawn('Banker').Name()
    mq.cmdf('/squelch /nav spawn %s', banker)
    mq.delay(100)
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

    mq.cmd('/invoke ${Window[FindItemWnd].DoOpen}')
    mq.delay(2000)
    mq.cmd('/notify FindItemWnd FIW_Default leftmouseup')
    mq.delay(2000)
    mq.cmd('/notify FindItemWnd FIW_ItemLocationCombobox listselect 2')
    mq.delay(2000)
    mq.cmd('/notify FindItemWnd FIW_ItemTypeCombobox listselect 41')
    mq.delay(2000)
    if ts == true and not mq.TLO.Window('FindItemWnd').Child('FIW_SearchDepotButton').Checked() then
        mq.cmd('/notify FindItemWnd FIW_SearchDepotButton leftmouseup')
        mq.delay(2000)
    end
    if ts == false and mq.TLO.Window('FindItemWnd').Child('FIW_SearchDepotButton').Checked() then
        mq.cmd('/notify FindItemWnd FIW_SearchDepotButton leftmouseup')
        mq.delay(2000)
    end
    mq.cmd('/notify FindItemWnd FIW_QueryButton leftmouseup')
    mq.delay(3000)

    local listSize = mq.TLO.Window('FindItemWnd').Child('FIW_ItemList').Items()

    for i=listSize, 1, -1 do
        local row = mq.TLO.Window('FindItemWnd').Child('FIW_ItemList').List(i,2)()
        mq.cmdf('/notify FindItemWnd FIW_ItemList listselect %s', i)
        for _,v in pairs(grabList) do
            if row == v then
                if mq.TLO.Me.FreeInventory() > 0 then
                    print('\at[TsC]\ao Found \ay'..v..'\ao in row '..i)
                    while mq.TLO.Cursor() do
                        mq.cmd('/autoinv')
                        mq.delay(100)
                    end
                    while mq.TLO.Target.Name() ~= banker do
                        mq.cmdf('/target %s', banker)
                        mq.delay(100)
                    end
                    while not mq.TLO.Window('BigBankWnd').Open() do
                        mq.cmd('/usetarget')
                        mq.delay(100)
                    end
                    while mq.TLO.Cursor() ~= v do
                        mq.cmd('/shift /notify FindItemWnd FIW_GrabButton leftmouseup')
                        mq.delay(100)
                        if mq.TLO.Window('QuantityWnd').Open() then
                            mq.cmd('/notify QuantityWnd QTYW_Accept_Button leftmouseup')
                            mq.delay(100)
                        end
                    end
                    mq.delay(100)
                    if mq.TLO.Cursor() == v then
                        print('\at[TsC]\ao Succesfully grabbed \ay'..v)
                    end
                    mq.delay(100)
                    while mq.TLO.Cursor() do
                        mq.cmd('/autoinv')
                        mq.delay(100)
                    end
                else
                    print('\at[TsC]\ao Found \ay'..v..'\ao in row '..i..'\ay but my inventory is full!')
                end
            end
        end
    end
    mq.cmd('/squelch /invoke ${Window[FindItemWnd].DoClose}')
    mq.cmd('/squelch /notify BigBankWnd BIGB_DoneButton leftmouseup')
    mq.cmd('/squelch /invoke ${Window[InventoryWindow].DoClose}')
end


function utils.trade(name, item)
    if mq.TLO.FindItemCount('='..item)() > 0 then
        if mq.TLO.Spawn(name).Distance() >= 15 then
            mq.cmdf('/squelch /nav spawn %s', name)
            mq.delay(100)
        end
        while mq.TLO.Navigation.Active() do
            if mq.TLO.Spawn(name).Distance() < 15 then
                mq.cmd('/squelch /nav stop')
                break
            end
        end

        mq.delay(500)

        repeat
            while mq.TLO.Cursor() ~= item do
                mq.cmdf('/itemnotify "%s" leftmouseup', item)
                mq.delay(500)
                if mq.TLO.Window('QuantityWnd').Open() then
                    mq.cmd('/notify QuantityWnd QTYW_Accept_Button leftmouseup')
                    mq.delay(100)
                end
            end
            
            while mq.TLO.Target.Name() ~= name do
                mq.cmdf('/target %s', name)
                mq.delay(500)
            end
            
            while not mq.TLO.Window('TradeWnd').Open() do
                mq.cmd('/usetarget')
                mq.delay(1000)
            end
            repeat
                mq.cmd('/yes')
                mq.delay(100)
            until not mq.TLO.Window('TradeWnd').Open()
        until mq.TLO.FindItemCount('='..item)() == 0
    end
end


function utils.bank(bankList)
    local banker = mq.TLO.NearestSpawn('Banker').Name()
    mq.cmdf('/squelch /nav spawn %s', banker)
    mq.delay(100)
    while mq.TLO.Navigation.Active() do
        if mq.TLO.Spawn(banker).Distance() < 15 then
            mq.cmd('/squelch /nav stop')
            break
        end
    end
    while mq.TLO.Target.Name() ~= banker do
        mq.cmdf('/target %s', banker)
        mq.delay(500)
    end
    while not mq.TLO.Window('BigBankWnd').Open() do
        mq.cmd('/usetarget')
        mq.delay(500)
    end

    for _,v in pairs(bankList) do
        print('\at[TsC]\ao Putting \ay'..v..' \aoin the bank.')
        while mq.TLO.Cursor() do
            mq.cmd('/autoinv')
            mq.delay(50)
        end
        if mq.TLO.FindItemCount('='..v)() > 0 then
            repeat
                while mq.TLO.Cursor() ~= v do
                    mq.cmdf('/shift /itemnotify "%s" leftmouseup', v)
                    mq.delay(500)
                    if mq.TLO.Window('QuantityWnd').Open() then
                        mq.cmd('/notify QuantityWnd QTYW_Accept_Button leftmouseup')
                        mq.delay(50)
                    end
                end
                while mq.TLO.Cursor() do
                    mq.cmd('/notify BigBankWnd BIGB_AutoButton leftmouseup')
                    mq.delay(50)
                end
            until mq.TLO.FindItemCount('='..v)() == 0
        end
    end
    print('\at[TsC]\ao Done putting items in the bank.')
end


function utils.depot(depotList)
    local banker = mq.TLO.NearestSpawn('Banker').Name()
    mq.cmdf('/squelch /nav spawn %s', banker)
    mq.delay(100)
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

    for _,v in pairs(depotList) do
        print('\at[TsC]\ao Putting \ay'..v..' \aoin your depot.')
        while mq.TLO.Cursor() do
            mq.cmd('/autoinv')
            mq.delay(1000)
        end
        if mq.TLO.FindItemCount('='..v)() > 0 then
            repeat
                while mq.TLO.Cursor() ~= v do
                    mq.cmdf('/shift /itemnotify "%s" leftmouseup', v)
                    mq.delay(1000)
                    if mq.TLO.Window('QuantityWnd').Open() then
                        mq.cmd('/notify QuantityWnd QTYW_Accept_Button leftmouseup')
                        mq.delay(1000)
                    end
                end
                while mq.TLO.Cursor() == v do
                    if mq.TLO.EverQuest.MouseX() > mq.TLO.Window('TradeskillDepotWnd').X() and mq.TLO.EverQuest.MouseX() < (mq.TLO.Window('TradeskillDepotWnd').X() + mq.TLO.Window('TradeskillDepotWnd').Width()) then
                        mq.cmd('/click left')
                        if mq.TLO.Window('ConfirmationDialogBox')() then
                            mq.cmd('/no')
                        end
                        mq.delay(1000)
                    else
                        print('\at[TsC]\ay Please hold your cursor over the TS depot window.')
                        mq.delay(2000)
                    end
                end
            until mq.TLO.FindItemCount('='..v)() == 0
        end
    end
    print('\at[TsC]\ao Done putting items in the depot.')
end


function utils.bankToDepot(bankToDepotList)
    print('\at[TsC]\ao Looking for items to move from bank to depot.')
    
    utils.grab(bankToDepotList, false)

    local banker = mq.TLO.NearestSpawn('Banker').Name()
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
    for _,v in pairs(bankToDepotList) do
        print('\at[TsC]\ao Putting \ay'..v..' \aoin your depot.')
        while mq.TLO.Cursor() do
            mq.cmd('/autoinv')
            mq.delay(1000)
        end
        if mq.TLO.FindItemCount('='..v)() > 0 then
            repeat
                while mq.TLO.Cursor() ~= v do
                    mq.cmdf('/shift /itemnotify "%s" leftmouseup', v)
                    mq.delay(1000)
                    if mq.TLO.Window('QuantityWnd').Open() then
                        mq.cmd('/notify QuantityWnd QTYW_Accept_Button leftmouseup')
                        mq.delay(1000)
                    end
                end
                while mq.TLO.Cursor() == v do
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
            until mq.TLO.FindItemCount('='..v)() == 0
        end
    end
    print('\at[TsC]\ao Done moving items from bank to depot.')
end

return utils