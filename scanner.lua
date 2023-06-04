--- @type Mq
local mq = require('mq')

local scanner = {}
local me = mq.TLO.Me.Name()

function scanner.scan(where, ignore, items)
    mq.cmd('/invoke ${Window[FindItemWnd].DoOpen}')
    mq.delay(1000)
    mq.cmd('/notify FindItemWnd FIW_Default leftmouseup')
    mq.delay(1000)
    mq.cmdf('/notify FindItemWnd FIW_ItemLocationCombobox listselect %s', where)
    mq.delay(1000)
    mq.cmd('/notify FindItemWnd FIW_ItemTypeCombobox listselect 41')
    mq.delay(1000)
    if not mq.TLO.Window('FindItemWnd').Child('FIW_SearchDepotButton').Checked() then
        mq.cmd('/notify FindItemWnd FIW_SearchDepotButton leftmouseup')
        mq.delay(1000)
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
                if not items[me][name] then
                    items[me][name] = {}
                    items[me][name].totalQty = total
                    items[me][name]['locations'] = {}
                    table.insert(items[me][name]['locations'], location)
                else
                    table.insert(items[me][name]['locations'], location)
                end
            print('\at[TsC]\ao Found \ay'..name)
        else
            print('\at[TsC]\ar Skipping \ay'..name) 
        end
        mq.delay(50)
    end
    
    mq.cmd('/invoke ${Window[FindItemWnd].DoClose}')
end

return scanner