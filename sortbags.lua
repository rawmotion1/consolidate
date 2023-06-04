--- @type Mq
local mq = require('mq')

local sort = {}

local me = mq.TLO.Me.Name()

local rescan

local function move(name, bag, slot)
    print('\at[TsC]\ao Restacking \ay'..name)
    while mq.TLO.Cursor() do
        mq.cmd('/autoinv')
        mq.delay(1000)
    end
    while mq.TLO.Cursor() ~= name do
        if bag == 0 then
            mq.cmdf('/shift /itemnotify %s leftmouseup', slot+22)
        else
            mq.cmdf('/shift /itemnotify in pack%s %s leftmouseup', bag, slot)
        end
        mq.delay(1000)
        if mq.TLO.Window('QuantityWnd').Open() then
            mq.cmd('/notify QuantityWnd QTYW_Accept_Button leftmouseup')
            mq.delay(1000)
        end
    end
    while mq.TLO.Cursor() do
        mq.cmd('/autoinv')
        mq.delay(1000)
    end
end

local spots = {}
function sort.sortBags(items)
    print('\at[TsC]\ao Checking for items to restack...')
    for m,y in pairs(items[me]) do
       
        for n,x in pairs(items[me][m]['locations']) do
            if string.match(x, "General") then
                local dash = string.match(x, "-")
                local bag = 0
                local slot
                local qty
                if dash then
                    bag = tonumber(string.match(x, "%s%d+")) or 0
                    slot = tonumber(string.match(x, "%d+$"))
                    qty = mq.TLO.Me.Inventory(bag+22).Item(slot).Stack()
                else
                    slot = tonumber(string.match(x, "%s%d+"))
                    qty = mq.TLO.Me.Inventory(slot+22).Stack()
                end
                if qty < mq.TLO.FindItem('='..m).StackSize() then
                    local item = {
                        name = m,
                        bag = bag,
                        slot = slot,
                        qty = qty
                    }
                    table.insert(spots, item)
                end
            end
        end
    end

    for k,v in pairs(spots) do
        for l,w in pairs(spots) do
            if k ~= l then
                if v.name == w.name then
                    if v.qty > w.qty then
                        move(w.name, w.bag, w.slot)
                        rescan = true
                    elseif w.qty >= v.qty then    
                        move(v.name, v.bag, v.slot)
                        rescan = true
                    end
                end
            end
        end
    end
    print('\at[TsC]\ao Done with restacking.')
end

function sort.rescan()
    return rescan
end

return sort



