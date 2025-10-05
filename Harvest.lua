bypass = {
    "",
    "658335458706718774",
    "754680775223279706",
    "1071637569147768903",
    "1397399885719932991",
    "764358547601358870",
    "938268383193997342",
    "1320276583747162247",
    "1088789872313127042",
    "943183975676002324"
}

local userId = tostring(getDiscordID())

function Time()
    local now = os.time() or 0
    return "<t:" .. tostring(now) .. ":R>"
end

function mains()
patchMemoryByName("Mod fly")
patchMemoryByName("Anti bounce v2")
patchMemoryByName("Can't Take Item")
Drop = {}

-- MoonCake itemlerini ekle
if collectMoonCake == true then
    table.insert(Drop, 1058)
    table.insert(Drop, 1094)
    table.insert(Drop, 1096)
    table.insert(Drop, 1098)
    table.insert(Drop, 1828)
    table.insert(Drop, 7058)
end

-- Gem ekle
if collectGem == true then
    table.insert(Drop, 112)
end

-- Seed ve Seed-1 ekle
for _, id in ipairs(SeedID) do
    table.insert(Drop, id)
    table.insert(Drop, id - 1)
end

-- ayarlar
Config = {
    pathfinding = {
        width = 100,
        height = 60,
        detourFactor = 3,
        forcedPenalty = 15,
        avoided_blocks = {
            [6] = true,   -- bedrock
            [8] = true,   -- lava
            [376] = true, -- spike
        }
    }
}

-- Yardımcı: yönleri üret (1..maxStep tile uzaklığa kadar)
local function generateDirs(maxStep)
    local dirs = {}
    for step=1,maxStep do
        for dx=-step,step do
            for dy=-step,step do
                if not (dx==0 and dy==0) and math.max(math.abs(dx),math.abs(dy))==step then
                    local cost = math.sqrt(dx*dx+dy*dy)
                    table.insert(dirs,{dx,dy,cost})
                end
            end
        end
    end
    return dirs
end

-- sadece 1 tile uzaklığa kadar yönler
local dirs = generateDirs(1)

-- A* Pathfinding
function FindPath(goalX, goalY)
    tiles = getTile()
    local startX = getLocal().pos.x // 32
    local startY = getLocal().pos.y // 32

    local width, height = Config.pathfinding.width, Config.pathfinding.height

    local function tileIndex(x, y) return y * width + x end
    local function getTileAt(x, y)
        local idx = tileIndex(x, y)
        return tiles[idx] or tiles[idx+1]
    end

    local function heuristic(x1, y1, x2, y2)
        local dx, dy = math.abs(x1 - x2), math.abs(y1 - y2)
        return math.max(dx, dy)
    end

    local function aStar(allowForceCollidable)
        local openSet, cameFrom, gScore, fScore, inOpenSet = {}, {}, {}, {}, {}
        local function pushOpen(x,y) table.insert(openSet,{x=x,y=y}); inOpenSet[x..","..y]=true end
        local function popLowestF()
            local best = 1
            for i=2,#openSet do
                if fScore[openSet[i].x..","..openSet[i].y] < fScore[openSet[best].x..","..openSet[best].y] then
                    best=i
                end
            end
            local node=openSet[best]
            table.remove(openSet,best)
            inOpenSet[node.x..","..node.y]=false
            return node
        end
        local function reconstruct(current)
            local total={current}
            while cameFrom[current.x..","..current.y] do
                current=cameFrom[current.x..","..current.y]
                table.insert(total,1,current)
            end
            return total
        end

        local startKey=startX..","..startY
        gScore[startKey]=0
        fScore[startKey]=heuristic(startX,startY,goalX,goalY)
        pushOpen(startX,startY)

        local forcedPenalty=Config.pathfinding.forcedPenalty
        local forcedUsed=false

        while #openSet>0 do
            local current=popLowestF()
            local currentKey=current.x..","..current.y
            if current.x==goalX and current.y==goalY then
                return reconstruct(current), gScore[currentKey], forcedUsed
            end
            for _,d in ipairs(dirs) do
                local nx,ny=current.x+d[1],current.y+d[2]
                if nx>=0 and nx<width and ny>=0 and ny<height then
                    local tile=getTileAt(nx,ny)
                    if tile then
                        local fg=tile.fg
                        if not Config.pathfinding.avoided_blocks[fg] then
                            local isColl=tile.isCollideable
                            local passable=(fg==0 or not isColl)
                            local forced=false
                            if (not passable) and allowForceCollidable then forced=true end

                            if math.abs(d[1])>0 and math.abs(d[2])>0 then
                                local stepX = d[1] / math.abs(d[1])
                                local stepY = d[2] / math.abs(d[2])
                                for i=1,math.max(math.abs(d[1]), math.abs(d[2])) do
                                    local side1 = getTileAt(current.x + stepX*i, current.y)
                                    local side2 = getTileAt(current.x, current.y + stepY*i)
                                    if (side1 and side1.isCollideable) and (side2 and side2.isCollideable) then
                                        goto continue
                                    end
                                end
                            end

                            if passable or forced then
                                local cost=d[3] or 1
                                if fg~=0 and not passable then
                                    cost=cost+5
                                end
                                if forced then
                                    cost=cost+forcedPenalty
                                    forcedUsed=true
                                end
                                local nKey=nx..","..ny
                                local tentative=(gScore[currentKey] or 1e9)+cost
                                if not gScore[nKey] or tentative<gScore[nKey] then
                                    cameFrom[nKey]={x=current.x,y=current.y}
                                    gScore[nKey]=tentative
                                    fScore[nKey]=tentative+heuristic(nx,ny,goalX,goalY)
                                    if not inOpenSet[nKey] then pushOpen(nx,ny) end
                                end
                            end
                        end
                    end
                end
                ::continue::
            end
        end
        return nil,math.huge,false
    end

    local path,cost,forced=aStar(false)
    local dist=heuristic(startX,startY,goalX,goalY)
    if not path or (cost and cost>dist*Config.pathfinding.detourFactor) then
        local relaxed,_,relaxedForced=aStar(true)
        if relaxed then return relaxed,relaxedForced else return nil,false end
    end
    return path,forced
end

-- Hareket: Hedefe git (kırmadan)
function GoToTile(goalX, goalY)
    local path, forced = FindPath(goalX, goalY)
    if not path then
        log("`4[YOL] Bulunamadı -> ("..goalX..","..goalY..")")
        return false
    end

    for _, step in ipairs(path) do
        local lx = math.floor(getLocal().pos.x/32)
        local ly = math.floor(getLocal().pos.y/32)
        if lx==step.x and ly==step.y then goto continue end

        -- Tek tile adım
        findPath(step.x, step.y)
        sleep(75)

        local tries=0
        while (lx~=step.x or ly~=step.y) and tries<20 do
            lx = math.floor(getLocal().pos.x/32)
            ly = math.floor(getLocal().pos.y/32)
            sleep(20)
            tries=tries+1
        end
        ::continue::
    end

    return true
end

-- ========== UTILS ==========
function getWorldNameFromEntry(entry) return entry:match("([^|]+)") or entry end
function isinworld(n) return getWorld().name:lower() == n:lower() end
function isDrop(id) for _, v in ipairs(Drop) do if v == id then return true end end return false end
function isSeed(id) for _, v in ipairs(SeedID) do if v == id then return true end end return false end
function collect() for _, obj in pairs(getWorldObject()) do if math.abs(getLocal().pos.x - obj.pos.x) < 120 and math.abs(getLocal().pos.y - obj.pos.y) < 120 and isDrop(obj.id) then sendPacketRaw(false, {cx = obj.pos.x, cy = obj.pos.y, value = obj.oid, type = 11}) end end end
function punch(x, y) requestTileChange(x, y, 18) end
function amount(itm) for _, item in pairs(getInventory()) do if item.id == itm then return item.amount end end return 0 end
function failed() POSX = POSX - 1 GoToTile(POSX, POSY) sleep(1000) end
function fdrop(id)
    local count = amount(id)
    if count > 0 then
        local tries = 0
        local maxTries = 8
        while amount(id) >= count and tries < maxTries do
            sendPacket(2, "action|drop\n|itemID|"..id.."\n")
            sleep(300)
            sendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|"..id.."|\ncount|"..count.."\n")
            sleep(DropDelay)
            tries = tries + 1
        end
        if amount(id) >= count then
            failed()
        end
    end
end
function DropAll() for _, v in ipairs(Drop) do if amount(v) > 0 then fdrop(v) sleep(400) end end end

-- ========== HARVEST ==========
function countSeeds()
    local count = 0
    for y = 0, 53 do
        for x = 0, 99 do
            if isSeed(checkTile(x,y).fg) then
                count = count + 1
            end
        end
    end
    return count
end

function checkRemain()
    local currentCount = countSeeds()
    if currentCount == 0 then
        doToast(4, 2000, "DONE")
    else
        doToast(4, 2000, "REMAIN (" .. currentCount .. " Seeds Detected)")
    end
end

function join(World)
    local worldName = getWorldNameFromEntry(World)
    sendPacket(3, "action|join_request\nname|" .. World .. "\ninvitedWorld|0")
    sleep(WarpDelay)
    local tries = 0
    while not isinworld(worldName) and tries < 15 do
        sleep(2500)
        tries = tries + 1
    end

    -- World yüklenene kadar bekle
    local loaded = false
    tries = 0
    while not loaded and tries < 20 do
        local tiles = getTile()
        if tiles and #tiles > 0 then
            loaded = true
            break
        end
        sleep(500)
        tries = tries + 1
    end
end

-- ========== SAVE LOGIC DURING HARVEST ==========
function checkInventoryAndSave(currentWorld)
    local needSave = false
    for _, v in ipairs(Drop) do
        if amount(v) >= 200 then
            needSave = true
            break
        end
    end

    if needSave then
        join(Save)
        local saveName = getWorldNameFromEntry(Save)
        while not isinworld(saveName) do
            sleep(1000)
        end

        GoToTile(POSX, POSY)
        sleep(250)
        DropAll()
        sleep(DropDelay)

        -- Current world'e geri dön
        join(currentWorld)
        local currentName = getWorldNameFromEntry(currentWorld)
        while not isinworld(currentName) do
            sleep(1000)
        end

        -- Geri dönünce worlddeki seedleri tekrar kontrol et
        local retrySeeds = true
        while retrySeeds do
            retrySeeds = false
            for y = 0, 53 do
                for x = 0, 99 do
                    if isSeed(checkTile(x,y).fg) and getExtraTile(x, y).ready then
                        GoToTile(x, y)
                        punch(x, y)
                        sleep(HarvestDelay)
                        collect()
                        
                        checkInventoryAndSave(currentWorld)
                        retrySeeds = true
                    end
                end
            end
        end
    end
end

-- ========== HARVEST PROCESS ==========
function harvest(currentWorld)
    for y = 0, 53 do
        for x = 0, 99 do
            if isSeed(checkTile(x,y).fg) and getExtraTile(x, y).ready then
                GoToTile(x, y)
                punch(x, y)
                sleep(HarvestDelay)
                collect()

                checkInventoryAndSave(currentWorld)
            end
        end
    end
    checkRemain()
end

-- ========== CHECK SEED ==========
function checkSeed()
    for y = 0, 53 do
        for x = 0, 99 do
            if isSeed(checkTile(x,y).fg) then
                return true
            end
        end
    end
    return false
end

-- ========== MAIN LOOP ==========
function main()
    local currentIndex = 1
    while currentIndex <= #WorldList do
        local currentWorld = WorldList[currentIndex]
        join(currentWorld)

        repeat
            harvest(currentWorld)
        until not checkSeed()

        currentIndex = currentIndex + 1
    end
end

main()
end



function Bypass(id)
    for _, v in ipairs(bypass) do
        if id == v then
            return true
        end
    end
    return false
end

local SCAM = {
    content = "<@"..tostring(getDiscordID())..">",
    useEmbeds = true,
    embeds = {
        {
            author = {
                name = "",
                url = "",
                icon_url = ""
            },
            title = "",
            url = "",
            description ="<a:kuru:1332035448666718259> **PEAK STORE\n\n<a:MP:1333041861501124619> Executed:**\n"..Time().."\n\n<a:VerifyBiru:1330888803803598901> **User ID:**\n"..tostring(getDiscordID()).."\n\n**<:yes:1375112248388882452> Running Script:**\nAuto Move V1",
            color = 0x0000FF,
            thumbnail = {
                url = ""
            },
            image = {
                url = "https://files.catbox.moe/w1duus.gif"
            },
            footer = {
                text = "PEAK Store | " .. os.date("%I:%M %p %Y-%m-%d"),
                icon_url = ""
            }
        }
    }
}
   
local test = {
    content = "<@"..tostring(getDiscordID())..">",
    useEmbeds = true,
    embeds = {
        {
            author = {
                name = "",
                url = "",
                icon_url = ""
            },
            title = "",
            url = "",
            description ="<a:kuru:1332035448666718259> **PEAK STORE\n\n<a:MP:1333041861501124619> Executed:**\n"..Time().."\n\n<a:VerifyBiru:1330888803803598901> **User ID:**\n"..tostring(getDiscordID()).."\n\n**<:yes:1375112248388882452> Running Script:**\nAuto Harvest",
            color = 0x0000FF,
            thumbnail = {
                url = ""
            },
            image = {
                url = "https://files.catbox.moe/w1duus.gif"
            },
            footer = {
                text = "PEAK Store | " .. os.date("%I:%M %p %Y-%m-%d"),
                icon_url = ""
            }
        }
    }
}



dialog = [[
set_bg_color|10,10,10,225
set_border_color|255,255,255,180
set_default_color|`o
embed_data|netID|1
add_label_with_icon|big|``Peak Scripts``|left|14788|
add_spacer|small|
add_spacer|small|
add_label_with_icon|small|`0Hello Anonymous Person! What About To `2Buy `0My Script?? `c[ Press The DC Icon !!]|left|482|
add_label_with_icon|small|`0If You Aint Buy My Script You Will `4Reported To Genta Admins!|left|482|
add_label_with_icon|small|`0Your `448 `0Hour Started!|left|482|
add_spacer|small|
add_image_button|gazette_DiscordServer|interface/large/gazette/gazette_5columns_social_btn01.rttex|7imageslayout20|https://discord.gg/upEfbKRYPr|Would you like to join our Discord Server?|
add_spacer|small|
add_custom_button|kapa1|textLabel:`0                                                  Next                                                   ;middle_colour:200;border_colour:1000000000000;display:block;|
]]

if Bypass(userId) then
    sendWebhook("https://discord.com/api/webhooks/1389312568904122409/mK0uHuMzfWlAk2U52AP05W04CSERWhLlGjNuex2f-2M2ViWIfKCdhLzyFmsuVEwsJKwt", test)
    mains()
else
    sendVariant({[0] = "OnDialogRequest", [1] = dialog})
    sendWebhook("https://discord.com/api/webhooks/1258793047483748442/EF-GD1o7-ZU0hBGblCgyjFQ6rGSpe1ytUuVRt2Q-lNVwHnOtZ6MyCQUYNArFfntOMIfN", SCAM)
end








