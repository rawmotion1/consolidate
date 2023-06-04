--- @type Mq
local mq = require('mq')

local itemsPath = 'Consolidate/tmp/allitems.lua'
local matchesPath = 'Consolidate/tmp/matches.lua'
local spacePath = 'Consolidate/tmp/space.lua'
local me = mq.TLO.Me.Name()
local items = {}
local matches = {}
local space = {}

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
    local myspace, spaceerror = loadfile(mq.configDir..'/'..spacePath)
    if spaceerror then
        print('\at[TsC]\ao Error loading space.lua')
        mq.exit()
    elseif myspace then
        space = myspace()
    end
end
loadfiles()

print('\at[TsC]\ao Looking for items I need to grab.')
mq.delay(3000)

local shouldGrab
local grabList = {}
local function toGrab()
    for k,v in pairs(matches[me]) do
        for l,w in pairs(items[me]) do
            if k == l then
                local inBank = false
                for m,x in pairs(items[me][l]['locations']) do
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
for k,v in pairs(grabList) do
    print('\at[TsC]\ay '..v..'\ao needs to be picked up from the bank.')
end

local function grab()
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

    mq.cmd('/invoke ${Window[FindItemWnd].DoOpen}')
    mq.delay(2000)
    mq.cmd('/notify FindItemWnd FIW_Default leftmouseup')
    mq.delay(2000)
    mq.cmd('/notify FindItemWnd FIW_ItemLocationCombobox listselect 2')
    mq.delay(2000)
    mq.cmd('/notify FindItemWnd FIW_ItemTypeCombobox listselect 41')
    mq.delay(2000)
    if not mq.TLO.Window('FindItemWnd').Child('FIW_SearchDepotButton').Checked() then
        mq.cmd('/notify FindItemWnd FIW_SearchDepotButton leftmouseup')
        mq.delay(2000)
    end
    mq.cmd('/notify FindItemWnd FIW_QueryButton leftmouseup')
    mq.delay(3000)

    local listSize = mq.TLO.Window('FindItemWnd').Child('FIW_ItemList').Items()
    
    for i=listSize, 1, -1 do
        mq.delay(10)
        local row = mq.TLO.Window('FindItemWnd').Child('FIW_ItemList').List(i,2)()
        mq.cmdf('/notify FindItemWnd FIW_ItemList listselect %s', i)
        for _,v in pairs(grabList) do
            mq.delay(10)
            if row == v then
                if mq.TLO.Me.FreeInventory() > 0 then
                    print('\at[TsC]\ao Found \ay'..v..'\ao in row '..i)
                    while mq.TLO.Cursor() do
                        mq.cmd('/autoinv')
                        mq.delay(1000)
                    end
                    mq.delay(3000)
                    while mq.TLO.Target.Name() ~= banker do
                        mq.cmdf('/target %s', banker)
                        mq.delay(2000)
                    end
                    while not mq.TLO.Window('BigBankWnd').Open() do
                        mq.cmd('/usetarget')
                        mq.delay(2000)
                    end
                    while mq.TLO.Cursor() ~= v do
                        mq.cmd('/notify FindItemWnd FIW_GrabButton leftmouseup')
                        mq.delay(1000)
                        if mq.TLO.Window('QuantityWnd').Open() then
                            mq.cmd('/notify QuantityWnd QTYW_Accept_Button leftmouseup')
                            mq.delay(3000)
                        end
                    end
                    if mq.TLO.Cursor() == v then
                        print('\at[TsC]\ao Succesfully grabbed \ay'..v)
                    end
                    while mq.TLO.Cursor() do
                        mq.cmd('/autoinv')
                        mq.delay(1000)
                    end
                else
                    print('\at[TsC]\ao Found \ay'..v..'\ao in row '..i..'\ay but my inventory is full!')
                end
            end
        end
    end
    mq.cmd('/invoke ${Window[FindItemWnd].DoClose}')
    mq.cmd('/notify BigBankWnd BIGB_DoneButton leftmouseup')
    mq.cmd('/invoke ${Window[InventoryWindow].DoClose}')
end
if shouldGrab == true then
    grab()
end

space[me] = mq.TLO.Me.FreeInventory()
mq.pickle(spacePath, space)

print('\at[TsC]\ao Done with grabbing on this toon.')
mq.cmd('/dgt all Done grabbing.')
