--TS Consolidator by Rawmotion
--- @type Mq
local mq = require('mq')

local version = '0.5.0'
local me = mq.TLO.Me.Name()

local settingPath = 'Consolidate/settings.lua'
local toonPath = 'Consolidate/toons.lua'
local ignorePath = 'Consolidate/ignore.lua'
local itemsPath = 'Consolidate/tmp/allitems.lua'
local artisanPath = 'Consolidate/artisan.lua'
local matchesPath = 'Consolidate/tmp/matches.lua'
local givePath = 'Consolidate/tmp/give.lua'

--Load settings
local settings = {}
local toons = {}
local ignore = {}
local artList = {}
local isArtisan = false

local function loadSettings()
    local loadSets, setError = loadfile(mq.configDir..'/'..settingPath)
    if setError then
        settings.tiebreaker = 'Toonone'
        settings.artisan = 'nobody'
        mq.pickle(settingPath, settings)
    elseif loadSets then
        settings = loadSets()
    end

    local loadToons, toonerror = loadfile(mq.configDir..'/'..toonPath)
    if toonerror then
        local createToons = {'Toon1', 'Toon2', 'Toon3'}
        for _,v in pairs(createToons) do
            local toon = {
                name = v,
                give = true,
                receive = true,
                bankall = false
            }
            table.insert(toons, toon)
        end
        print('\at[TsC]\ao Creating Consolidate/toons.lua in your config folder.')
        print('\at[TsC]\ao Creating Consolidate/ignore.lua in your config folder.')
        print('\at[TsC]\ao Please edit these files and then run the script again.')
        
        ignore[1] = 'Loaf of Bread'
        ignore[2] = 'Water Flask'
        mq.pickle(toonPath, toons)
        mq.pickle(ignorePath, ignore)
        mq.exit()
    elseif loadToons then
        toons = loadToons()
        if not toons[1].name then
            local temptoons = {}
            for k,v in pairs(toons) do
                local toon = {
                    name = v,
                    give = true,
                    receive = true,
                    bankall = false
                }
                toons[k] = nil
                table.insert(temptoons, toon)
            end
            toons = temptoons
            mq.pickle(toonPath, toons)
            print('\at[TsC]\ao Reformatting Consolidate/toons.lua in your config folder.')
        end
    end
    
    local loadArt, artError = loadfile(mq.configDir..'/'..artisanPath)
    if artError then
    elseif loadArt then
        artList = loadArt()
        for _,v in pairs(toons) do
            if v.name == settings.artisan then
                isArtisan = true
            end
        end
    end

end
loadSettings()

print('\at[TsC]\ao Welcome to TS Consolidator v'..version)
print('\at[TsC]\ao Make sure all your toons are in the same zone.')
print('\at[TsC]\ao Make sure there is a banker nearby.')
print('\at[TsC]\ao When you\'re ready, type \ay/tsc go')

--------------------------------------------------------

local waitingscanning
local waitinggrabbing
local waitingtrading
local waitingbanking
local function stopwaitingscanning() waitingscanning = false end
local function stopwaitinggrabbing() waitinggrabbing = false end
local function stopwaitingtrading() waitingtrading = false end
local function stopwaitingbanking() waitingbanking = false end
mq.event('scanning', '#*#Done scanning#*#', stopwaitingscanning)
mq.event('grabing', '#*#Done grabbing#*#', stopwaitinggrabbing)
mq.event('trading', '#*#Done trading#*#', stopwaitingtrading)
mq.event('banking', '#*#Done banking#*#', stopwaitingbanking)

--Creates blank allitems.lua with subtables for each toon and each location
local allitems = {}
local function createAllitems()
    for _,v in pairs(toons) do
        allitems[v.name] = {}
    end
    mq.pickle(itemsPath, allitems)
end

local function scanEveryone(who)
    if who == 'all' then
        for _,v in pairs(toons) do
            waitingscanning = true
            if v.name == me then
                mq.cmd('/squelch /lua run Consolidate/toonscan')
            else
                mq.cmdf('/squelch /dex %s /lua run Consolidate/toonscan', v.name)
            end
            print('\at[TsC]\ao Telling \ar'..v.name..' \ao to start scanning routine.')
            while waitingscanning do
                mq.doevents()
                mq.delay(1500)
            end
            print('\at[TsC]\ar '..v.name..' \ao is finished scanning.')
        end
        print('\at[TsC]\ao All toons are done scanning.')
        mq.delay(2000)
    else
        waitingscanning = true
        if who == me then
            mq.cmd('/squelch /lua run Consolidate/toonscan')
        else
            mq.cmdf('/squelch /dex %s /lua run Consolidate/toonscan', who)
        end
        print('\at[TsC]\ao Telling \ar'..who..' \ao to start scanning routine.')
        while waitingscanning do
            mq.doevents()
            mq.delay(1500)
        end
        print('\at[TsC]\ar '..who..' \ao is finished scanning.')
    end
end

--After everyone has scanned, reload allitems.lua with everyone's items
local function reloadAllItems()
    local inventories, itemerror = loadfile(mq.configDir..'/'..itemsPath)
    if itemerror then
        print('\at[TsC]\ao Error loading allitems.lua')
        mq.exit()
    elseif inventories then
        allitems = inventories()
    end
end

local matches = {}
--Compare everyone's items
local function defineMatches()
    print('\at[TsC]\ao Comparing results across toons...')
    matches = {}
    mq.delay(1000)
    for _,myToon in pairs(toons) do
        for myItem,myProp in pairs(allitems[myToon.name]) do
            
            local isArtItem = false
            if isArtisan == true then
                for _,artItem in pairs(artList) do
                    if myItem == artItem then
                        isArtItem = true
                    end
                end
            end

            if isArtItem == true then
                if myToon.name ~= settings.artisan then
                    if not matches[myToon.name] then matches[myToon.name] = {} end
                    if not matches[myToon.name][myItem] then matches[myToon.name][myItem] = {} end
                    matches[myToon.name][myItem].receiver = settings.artisan
                    matches[myToon.name][myItem].receiverCount = 10000
                    print('\at[TsC]\ag [Artisan] \ar'..myToon.name..'\'s \ag'..myProp.totalQty..' \ay'..myItem..' \aowill go to \ar'..settings.artisan..' \aowho is the \ag Artisan')
                end
            else

                for _,otherToon in pairs(toons) do
                    if otherToon.name ~= myToon.name then
                        for otherItem,otherProp in pairs(allitems[otherToon.name]) do
                            if myItem == otherItem then
                                if not matches[myToon.name] then matches[myToon.name] = {} end
                                if myProp.totalQty < otherProp.totalQty then
                                    if not matches[otherToon.name] then matches[otherToon.name] = {} end
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
                                elseif myProp.totalQty == otherProp.totalQty and myToon.name ~= toons[1].name then
                                    if not matches[myToon.name][myItem] then
                                        matches[myToon.name][myItem] = {}
                                        local tiebreaker = settings.tiebreaker
                                        if tiebreaker == 'Toonone' then
                                            tiebreaker = toons[1].name
                                        end
                                        if not matches[tiebreaker] then matches[tiebreaker] = {} end
                                        matches[myToon.name][myItem].receiver = tiebreaker
                                        matches[myToon.name][myItem].receiverCount = 0
                                        print('\at[TsC]\ag [Tie] \ar'..myToon.name..'\'s \ag'..myProp.totalQty..' \ay'..myItem..' \aowill go to \ar'..tiebreaker..' \aobecause there was a tie.')
                                    end
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

--Tell each toon to grab items from the bank that they need to give to someone else, one at a time
local function everyoneGrab()
    for l,_ in pairs (matches) do
        waitinggrabbing = true
        if l == me then
            mq.cmd('/squelch /lua run Consolidate/toongrab')
        else
            mq.cmdf('/squelch /dex %s /lua run Consolidate/toongrab', l)
        end
        print('\at[TsC]\ao Telling \ar'..l..' \ao to start grabbing routine.')
        while waitinggrabbing do
            mq.doevents()
            mq.delay(1500)
        end
        mq.unevent('grabbing')
        print('\at[TsC]\ar '..l..' \ao is finished grabbing.')
    end
    print('\at[TsC]\ao All toons are done grabbing.')
    mq.delay(2000)
end


--Tell each toon to start trading, one at a time.
local function trade()
    for l,_ in pairs(matches) do
        waitingtrading = true
        if l == me then
            mq.cmd('/squelch /lua run Consolidate/toontrade')
        else
            mq.cmdf('/squelch /dex %s /lua run Consolidate/toontrade', l)
        end
        print('\at[TsC]\ao Telling \ar'..l..' \ao to start trading routine.')
        while waitingtrading do
            mq.doevents()
            mq.delay(1500)
        end
        print('\at[TsC]\ar '..l..' \ao is finished trading.')
    end
    print('\at[TsC]\ao All toons are done trading.')
    mq.delay(2000)
end

local function clearItems()
    for k,_ in pairs(matches) do
        allitems[k] = {}
    end
    mq.pickle(itemsPath, allitems)
end

local function rescan()
    for k,_ in pairs(matches) do
        waitingscanning = true
        if k == me then
            mq.cmd('/squelch /lua run Consolidate/toonscan')
        else
            mq.cmdf('/squelch /dex %s /lua run Consolidate/toonscan', k)
        end
        print('\at[TsC]\ao Telling \ar'..k..' \ao to start scanning routine.')
        while waitingscanning do
            mq.doevents()
            mq.delay(1500)
        end
        print('\at[TsC]\ar '..k..' \ao is finished scanning.')
    end
    print('\at[TsC]\ao All toons are done scanning.')
    mq.delay(2000)
end

--Tell each toon to bank items from their bags if they also exist in their bank
local function everyoneBank(who)
    if who == 'all' then
        for _,v in pairs (toons) do
            waitingbanking = true
            if v.name == me then
                mq.cmd('/squelch /lua run Consolidate/toonbank')
            else
                mq.cmdf('/squelch /dex %s /lua run Consolidate/toonbank', v.name)
            end
            print('\at[TsC]\ao Telling \ar'..v.name..' \ao to start banking routine.')
            while waitingbanking do
                mq.doevents()
                mq.delay(1500)
            end
            print('\at[TsC]\ar '..v.name..' \ao is finished banking.') 
        end
        print('\at[TsC]\ao All toons are done banking.')
    else
        waitingbanking = true
        if who == me then
            mq.cmd('/squelch /lua run Consolidate/toonbank')
        else
            mq.cmdf('/squelch /dex %s /lua run Consolidate/toonbank', who)
        end
        print('\at[TsC]\ao Telling \ar'..who..' \ao to start banking routine.')
        while waitingbanking do
            mq.doevents()
            mq.delay(1500)
        end
        print('\at[TsC]\ar '..who..' \ao is finished banking.') 
    end
end

local function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

local function validNames(g, r)
    local givergood = false
    local targetgood = false
    for _,v in pairs(toons) do
        if v.name == g then
            givergood = true
        end
        if r and v.name == r then
            targetgood = true
        end
    end
    if r == 'depot' then targetgood = true end
    if givergood == false then
        print('\at[TsC]\ao \ar'..g..' \ao is not a member of toons.lua')
        return false
    elseif r and targetgood == false then
        print('\at[TsC]\ao \ar'..r..' \ao is not a member of toons.lua')
        return false
    elseif r and r ~= 'depot' then
        print('\at[TsC]\ao Telling \ar'..g..' \ao to give all mats to \ar'..r)
        return true
    elseif r == 'bank' then
        print('\at[TsC]\ao Telling \ar'..g..' \ao to store items in depot')
        return true
    else
        print('\at[TsC]\ao Telling \ar'..g..' \ao to start self-consolidation')
        return true
    end
end

local function go()
    createAllitems()
    scanEveryone('all')
    reloadAllItems()
    defineMatches()
    everyoneGrab()
    trade()
    clearItems()
    rescan()
    everyoneBank('all')
    print('\at[TsC]\ao EVERYTHING DONE')
end

local function selfGo(name)
    name = firstToUpper(name)
    if validNames(name) == true then
        createAllitems()
        scanEveryone(name)
        reloadAllItems()
        everyoneBank(name)
    end
end

local function give(giver, target, scope)
    giver = firstToUpper(giver)
    target = firstToUpper(target)
    if validNames(giver, target) then
        local givers = {}
        givers.giver = giver
        givers.receiver = target
        if scope == 'all' then
            givers.scope = scope
        else
            givers.scope = 'inventory'
        end
        mq.pickle(givePath, givers)
        mq.delay(1000)
        if giver == me then
            mq.cmd('/squelch /lua run Consolidate/toongive')
        else
            mq.cmdf('/squelch /dex %s /lua run Consolidate/toongive', giver)
        end
    end
end

local function selfBank(name)
    name = firstToUpper(name)
    if validNames(name, 'depot') == true then
        createAllitems()
        if name == me then
            mq.cmd('/squelch /lua run Consolidate/toonstore')
        else
            mq.cmdf('/squelch /dex %s /lua run Consolidate/toonstore', name)
        end
    end
end

local function binds(a, b, c)
    if a == 'go' and b == nil then
        go()
    elseif a and b == 'depot' then
        selfBank(a)
    elseif a and b and c == nil then
        give(a, b)
    elseif a and b and c == 'all' then
        give(a, b, c)
    elseif a and b == nil then
        selfGo(a)
    end
end

mq.bind('/tsc', binds)

local terminate = false
while not terminate do
    mq.delay(1000)
end