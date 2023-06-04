--- @type Mq
local mq = require('mq')
local mainroutine = {}


function mainroutine.go()
    local toonPath = 'Consolidate/toons.lua'
    local itemsPath = 'Consolidate/tmp/allitems.lua'
    local matchesPath = 'Consolidate/tmp/matches.lua'
    local spacePath = 'Consolidate/tmp/space.lua'
    local me = mq.TLO.Me.Name()

    --Load settings
    local toons = {}
    local function loadSettings()
        local loadToons, toonerror = loadfile(mq.configDir..'/'..toonPath)
        if toonerror then
            print('\at[TsC]\ao Error loading toons.lua')
            mq.exit()
        elseif loadToons then
            toons = loadToons()
        end
    end
    loadSettings()

    --Creates blank allitems.lua with subtables for each toon and each location
    local allitems = {}
    local function createAllitems()
        for _,v in pairs(toons) do
            allitems[v.name] = {}
        end
        mq.pickle(itemsPath, allitems)
    end
    createAllitems()

    --Creates space.lua for later
    local space = {}
    local function createSpace()
        for _,v in pairs(toons) do
            space[v.name] = 0
        end
        mq.pickle(spacePath, space)
    end
    createSpace()

    --Tell each toon to scan their inventory, one at a time, and add their TS items to allitems.lua
    local waiting
    local function stop()
        waiting = false
    end
    mq.event('scanning', '#*#Done scanning#*#', stop)
    local function scanEveryone()
        for _,v in pairs(toons) do
            waiting = true
            if v.name == me then
                mq.cmd('/squelch /lua run Consolidate/toonscan')
            else
                mq.cmdf('/squelch /dex %s /lua run Consolidate/toonscan', v.name)
            end
            print('\at[TsC]\ao Telling \ar'..v.name..' \ao to start scanning routine.')
            while waiting do
                mq.doevents()
                mq.delay(1500)
            end
            print('\at[TsC]\ar '..v.name..' \ao is finished scanning.')
        end
        print('\at[TsC]\ao All toons are done scanning.')
        mq.delay(2000)
    end
    scanEveryone()


    --After everyone has scanned, reload allitems.lua with everyone's items
    local function reloadAllItems()
        local inventories, error = loadfile(mq.configDir..'/'..itemsPath)
        if error then
            print('\at[TsC]\ao Error loading allitems.lua')
            mq.exit()
        elseif inventories then
            allitems = inventories()
        end
    end
    reloadAllItems()


    --Compare everyone's items
    local function defineMatches()
        print('\at[TsC]\ao Comparing results across toons...')
        mq.delay(2000)
        local matches = {}
        for _,v in pairs(toons) do
            matches[v.name] = {}
        end
        for _,myToon in pairs(toons) do
            for myItem,myProp in pairs(allitems[myToon.name]) do
                for _,otherToon in pairs(toons) do
                    if otherToon.name ~= myToon.name then
                        for otherItem,otherProp in pairs(allitems[otherToon.name]) do
                            if myItem == otherItem then
                                if myProp.totalQty < otherProp.totalQty then
                                    if not matches[myToon.name][myItem] then
                                        matches[myToon.name][myItem] = {}
                                        matches[myToon.name][myItem].receiver = otherToon.name
                                        matches[myToon.name][myItem].receiverCount = otherProp.totalQty
                                        print('\at[TsC]\ag [Match] \ar'..myToon.name..'\'s \ag'..myProp.totalQty..' \ay'..myItem..' \aowill go to \ar'..otherToon.name..' \aowho has \ag'..otherProp.totalQty)
                                    elseif matches[myToon.name][myItem].receiverCount < otherProp.totalQty then
                                        matches[myToon.name][myItem].receiver = otherToon.name
                                        matches[myToon.name][myItem].receiverCount = otherProp.totalQty
                                        print('\at[TsC]\ag [Update] \ar'..myToon.name..'\'s \ag'..myProp.totalQty..' \ay'..myItem..' \aowill actually go to \ar'..otherToon.name..' \aowho has \ag'..otherProp.totalQty)
                                    end
                                elseif myProp.totalQty == otherProp.totalQty then
                                    if not matches[myToon.name][myItem] then
                                        matches[myToon.name][myItem] = {}
                                        matches[myToon.name][myItem].receiver = toons[1].name
                                        matches[myToon.name][myItem].receiverCount = 0
                                        print('\at[TsC]\ag [Tie] \ar'..myToon.name..'\'s \ag'..myProp.totalQty..' \ay'..myItem..' \aowill go to \ar'..toons[1].name..' \aobecause there was a tie.')
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        mq.pickle(matchesPath, matches)
    end
    defineMatches()


    --Tell each toon to grab items from the bank that they need to give to someone else, one at a time
    local function everyoneGrab()
        local waiting
        local function stop()
            waiting = false
        end
        mq.event('grabing', '#*#Done grabbing#*#', stop)
        for _,v in pairs(toons) do
            waiting = true
            if v.name == me then
                mq.cmd('/squelch /lua run Consolidate/toongrab')
            else
                mq.cmdf('/squelch /dex %s /lua run Consolidate/toongrab', v.name)
            end
            print('\at[TsC]\ao Telling \ar'..v.name..' \ao to start grabbing routine.')
            while waiting do
                mq.doevents()
                mq.delay(1500)
            end
            print('\at[TsC]\ar '..v.name..' \ao is finished grabbing.')
        end
        print('\at[TsC]\ao All toons are done grabbing.')
        mq.delay(2000)
    end
    everyoneGrab()


    --Tell each toon to start trading, one at a time.
    local function trade()
        local waiting
        local function stop()
            waiting = false
        end
        mq.event('trading', '#*#Done trading#*#', stop)
        for _,v in pairs(toons) do
            waiting = true
            if v.name == me then
                mq.cmd('/squelch /lua run Consolidate/toontrade')
            else
                mq.cmdf('/squelch /dex %s /lua run Consolidate/toontrade', v.name)
            end
            print('\at[TsC]\ao Telling \ar'..v.name..' \ao to start trading routine.')
            while waiting do
                mq.doevents()
                mq.delay(1500)
            end
            print('\at[TsC]\ar '..v.name..' \ao is finished trading.')
        end
        print('\at[TsC]\ao All toons are done trading.')
        mq.delay(2000)
    end
    trade()



    --Clear allitems
    createAllitems()

    --Rescan
    scanEveryone()


    --Tell each toon to bank items from their bags if they also exist in their bank
    local function everyoneBank()
        local waiting
        local function stop()
            waiting = false
        end
        mq.event('banking', '#*#Done banking#*#', stop)
        for _,v in pairs(toons) do
            waiting = true
            if v.name == me then
                mq.cmd('/squelch /lua run Consolidate/toonbank')
            else
                mq.cmdf('/squelch /dex %s /lua run Consolidate/toonbank', v.name)
            end
            print('\at[TsC]\ao Telling \ar'..v.name..' \ao to start banking routine.')
            while waiting do
                mq.doevents()
                mq.delay(1500)
            end
            print('\at[TsC]\ar '..v.name..' \ao is finished banking.')
        end
        print('\at[TsC]\ao All toons are done banking.')
    end
    everyoneBank()


    print('\at[TsC]\ao EVERYTHING DONE')
end

return mainroutine