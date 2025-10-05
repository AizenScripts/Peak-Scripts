bypass = {
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

userId = tostring(getDiscordID())

function Time()
    local now = os.time() or 0
    return "<t:" .. tostring(now) .. ":R>"
end

function mains()
patchMemoryByName("Mod fly")
patchMemoryByName("Anti bounce v2")
patchMemoryByName("Can't Take Item")
        
            Drop = {}
currentWorld = nil

-- MoonCake itemlerini ekle
if collectMoonCake then
    for _, id in ipairs({1058, 1094, 1096, 1098, 1828, 7058}) do
        table.insert(Drop, id)
    end
end

-- Gem ekle
if collectGem then table.insert(Drop, 112) end

-- Seed ve Seed-1 ekle
for _, id in ipairs(SeedID) do
    table.insert(Drop, id)
    table.insert(Drop, id - 1)
end

-- Pathfinding ayarları
Config = {
    pathfinding = {
        width = 100,
        height = 60,
        detourFactor = 3,
        forcedPenalty = 15,
        avoided_blocks = {
            [6] = true,
            [8] = true,
            [376] = true
        }
    }
}

-- Yardımcı: yönler (1 tile)
local function generateDirs(maxStep)
    local dirs = {}
    for step=1,maxStep do
        for dx=-step,step do
            for dy=-step,step do
                if not (dx==0 and dy==0) and math.max(math.abs(dx),math.abs(dy))==step then
                    table.insert(dirs,{dx,dy,math.sqrt(dx*dx+dy*dy)})
                end
            end
        end
    end
    return dirs
end

local dirs = generateDirs(1)

-- ========== PATHFINDING ==========
function FindPath(goalX, goalY)
    local tiles = getTile()
    local startX = getLocal().pos.x // 32
    local startY = getLocal().pos.y // 32
    local width, height = Config.pathfinding.width, Config.pathfinding.height

    local function tileIndex(x, y) return y * width + x end
    local function getTileAt(x, y)
        local idx = tileIndex(x, y)
        return tiles[idx] or tiles[idx+1]
    end
    local function heuristic(x1,y1,x2,y2) return math.max(math.abs(x1-x2), math.abs(y1-y2)) end

    local function aStar(allowForceCollidable)
        local openSet, cameFrom, gScore, fScore, inOpenSet = {}, {}, {}, {}, {}
        local function pushOpen(x,y) table.insert(openSet,{x=x,y=y}); inOpenSet[x..","..y]=true end
        local function popLowestF()
            local best=1
            for i=2,#openSet do
                if fScore[openSet[i].x..","..openSet[i].y] < fScore[openSet[best].x..","..openSet[best].y] then best=i end
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

        local startKey = startX..","..startY
        gScore[startKey]=0
        fScore[startKey]=heuristic(startX,startY,goalX,goalY)
        pushOpen(startX,startY)
        local forcedPenalty = Config.pathfinding.forcedPenalty
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
                                local stepX=d[1]/math.abs(d[1])
                                local stepY=d[2]/math.abs(d[2])
                                for i=1,math.max(math.abs(d[1]), math.abs(d[2])) do
                                    local side1=getTileAt(current.x + stepX*i, current.y)
                                    local side2=getTileAt(current.x, current.y + stepY*i)
                                    if (side1 and side1.isCollideable) and (side2 and side2.isCollideable) then
                                        goto continue
                                    end
                                end
                            end

                            if passable or forced then
                                local cost=d[3] or 1
                                if fg~=0 and not passable then cost=cost+5 end
                                if forced then cost=cost+forcedPenalty; forcedUsed=true end
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

function GoToTile(goalX, goalY)
    local path, forced = FindPath(goalX, goalY)
    if not path then log("`4[YOL] Bulunamadı -> ("..goalX..","..goalY..")"); return false end
    for _, step in ipairs(path) do
        local lx = math.floor(getLocal().pos.x/32)
        local ly = math.floor(getLocal().pos.y/32)
        if lx==step.x and ly==step.y then goto continue end
        findPath(step.x, step.y)
        sleep(50)
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
function collect()
    for _, obj in pairs(getWorldObject()) do
        if math.abs(getLocal().pos.x - obj.pos.x) < 120 and math.abs(getLocal().pos.y - obj.pos.y) < 120 and isDrop(obj.id) then
            sendPacketRaw(false, {cx = obj.pos.x, cy = obj.pos.y, value = obj.oid, type = 11})
        end
    end
end
function punch(x, y) requestTileChange(x, y, 18) end
function amount(itm) for _, item in pairs(getInventory()) do if item.id == itm then return item.amount end end return 0 end
function failed()
 POSX = POSX - 1
 GoToTile(POSX, POSY)
 sleep(1000)
 DropAll()
end
function fdrop(id)
    local count = amount(id)
    if count > 0 then
        local tries = 0
        local maxTries = 3
        while amount(id) >= count and tries < maxTries do
            sendPacket(2, "action|drop\n|itemID|"..id.."\n")
            sleep(300)
            sendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|"..id.."|\ncount|"..count.."\n")
            sleep(DropDelay)
            tries = tries + 1
        end
        if amount(id) >= count then failed() end
    end
end
function DropAll() for _, v in ipairs(Drop) do if amount(v) > 0 then fdrop(v) sleep(400) end end end

-- ========== SAVE LOGIC DURING HARVEST ==========
function join(World)
    local worldName = getWorldNameFromEntry(World)
    sendPacket(3, "action|join_request\nname|" .. World .. "\ninvitedWorld|0")
    sleep(WarpDelay)
    local tries = 0
    while not isinworld(worldName) and tries < 15 do sleep(2500); tries=tries+1 end
    local loaded=false; tries=0
    while not loaded and tries<20 do
        local tiles = getTile()
        if tiles and #tiles>0 then loaded=true; break end
        sleep(500)
        tries=tries+1
    end
end

function checkInventoryAndSave(currentWorld)
function checkInventoryAndSave(currentWorld)
    for _, v in ipairs(Drop) do
        if amount(v) >= 160 then
            -- Önce Save world’e ID’siz giriş
            local saveName = getWorldNameFromEntry(Save)
            sendPacket(3, "action|join_request\nname|" .. saveName .. "\ninvitedWorld|0")
            sleep(WarpDelay)

            local tries = 0
            while not isinworld(saveName) and tries < 15 do
                sleep(2000)
                tries = tries + 1
            end

            -- Sonra ID’li giriş
            sendPacket(3, "action|join_request\nname|" .. Save .. "\ninvitedWorld|0")
            sleep(WarpDelay)

            tries = 0
            while not isinworld(saveName) and tries < 15 do
                sleep(500)
                tries = tries + 1
            end

            GoToTile(POSX, POSY)
            sleep(250)
            DropAll()
            sleep(DropDelay)

            -- Tekrar current world’e dön
            local worldName = getWorldNameFromEntry(currentWorld)
            sendPacket(3, "action|join_request\nname|" .. worldName .. "\ninvitedWorld|0")
            sleep(WarpDelay)

            tries = 0
            while not isinworld(worldName) and tries < 15 do
                sleep(2500)
                tries = tries + 1
            end

            sendPacket(3, "action|join_request\nname|" .. currentWorld .. "\ninvitedWorld|0")
            sleep(WarpDelay)

            while not isinworld(worldName) do
                sleep(1000)
            end

            return true -- ✅ save işlemi oldu diyoruz
        end
    end
    return false -- ✅ save olmadı, devam et
end

-- ========== HARVEST ==========
function harvest(currentWorld)
    -- Önce ID'siz giriş yap
    local worldName = getWorldNameFromEntry(currentWorld)
    sendPacket(3, "action|join_request\nname|" .. worldName .. "\ninvitedWorld|0")
    sleep(WarpDelay)

    local tries = 0
    while not isinworld(worldName) and tries < 15 do
        sleep(2500)
        tries = tries + 1
    end

    -- Şimdi ID'li giriş yap
    sendPacket(3, "action|join_request\nname|" .. currentWorld .. "\ninvitedWorld|0")
    sleep(WarpDelay)

    tries = 0
    while not isinworld(worldName) and tries < 15 do
        sleep(500)
        tries = tries + 1
    end

    -- Sonra tile’ların yüklenmesini bekle
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

    -- Harvest kısmı normal devam
    for y = 0, 53 do
        for x = 0, 99 do
            if x+4 <= 99 and
               (isSeed(checkTile(x,y).fg) and getExtraTile(x,y).ready) and
               (isSeed(checkTile(x+1,y).fg) and getExtraTile(x+1,y).ready) and
               (isSeed(checkTile(x+2,y).fg) and getExtraTile(x+2,y).ready) and
               (isSeed(checkTile(x+3,y).fg) and getExtraTile(x+3,y).ready) and
               (isSeed(checkTile(x+4,y).fg) and getExtraTile(x+4,y).ready) then
               
                checkInventoryAndSave(currentWorld)
                GoToTile(x+2, y)
                for i=0,4 do
                    while isSeed(checkTile(x+i, y).fg) and getExtraTile(x+i, y).ready do
                        checkInventoryAndSave(currentWorld)
                        punch(x+i, y)
                        sleep(HarvestDelay)
                    end
                end
                collect()
                sleep(180)
                checkInventoryAndSave(currentWorld)
            -- 4'lü kombinasyon
            elseif x+3 <= 99 and
               (isSeed(checkTile(x,y).fg) and getExtraTile(x,y).ready) and
               (isSeed(checkTile(x+1,y).fg) and getExtraTile(x+1,y).ready) and
               (isSeed(checkTile(x+2,y).fg) and getExtraTile(x+2,y).ready) and
               (isSeed(checkTile(x+3,y).fg) and getExtraTile(x+3,y).ready) then
               
                checkInventoryAndSave(currentWorld)
                GoToTile(x+1, y)
                for i=0,3 do
                    while isSeed(checkTile(x+i, y).fg) and getExtraTile(x+i, y).ready do
                        checkInventoryAndSave(currentWorld)
                        punch(x+i, y)
                        sleep(HarvestDelay)
                    end
                end
                collect()
                sleep(180)
                checkInventoryAndSave(currentWorld)
            -- 3'lü kombinasyon
            elseif x+2 <= 99 and
               (isSeed(checkTile(x,y).fg) and getExtraTile(x,y).ready) and
               (isSeed(checkTile(x+1,y).fg) and getExtraTile(x+1,y).ready) and
               (isSeed(checkTile(x+2,y).fg) and getExtraTile(x+2,y).ready) then
               
                checkInventoryAndSave(currentWorld)
                GoToTile(x+1, y)
                for i=0,2 do
                    while isSeed(checkTile(x+i, y).fg) and getExtraTile(x+i, y).ready do
                        checkInventoryAndSave(currentWorld)
                        punch(x+i, y)
                        sleep(HarvestDelay)
                    end
                end
                collect()
                sleep(180)
                checkInventoryAndSave(currentWorld)
            -- 2'li kombinasyon
            elseif x+1 <= 99 and
               (isSeed(checkTile(x,y).fg) and getExtraTile(x,y).ready) and
               (isSeed(checkTile(x+1,y).fg) and getExtraTile(x+1,y).ready) then
               
                checkInventoryAndSave(currentWorld)
                GoToTile(x, y)
                for i=0,1 do
                    while isSeed(checkTile(x+i, y).fg) and getExtraTile(x+i, y).ready do
                        checkInventoryAndSave(currentWorld)
                        punch(x+i, y)
                        sleep(HarvestDelay)
function harvest(currentWorld)
    -- Önce ID'siz giriş yap
    local worldName = getWorldNameFromEntry(currentWorld)
    sendPacket(3, "action|join_request\nname|" .. worldName .. "\ninvitedWorld|0")
    sleep(WarpDelay)

    local tries = 0
    while not isinworld(worldName) and tries < 15 do
        sleep(2500)
        tries = tries + 1
    end

    -- Şimdi ID'li giriş yap
    sendPacket(3, "action|join_request\nname|" .. currentWorld .. "\ninvitedWorld|0")
    sleep(WarpDelay)

    tries = 0
    while not isinworld(worldName) and tries < 15 do
        sleep(500)
        tries = tries + 1
    end

    -- Sonra tile’ların yüklenmesini bekle
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

    -- Harvest kısmı
    for y = 0, 53 do
        for x = 0, 99 do
            -- 5'li kombinasyon
            if x+4 <= 99 and
               (isSeed(checkTile(x,y).fg) and getExtraTile(x,y).ready) and
               (isSeed(checkTile(x+1,y).fg) and getExtraTile(x+1,y).ready) and
               (isSeed(checkTile(x+2,y).fg) and getExtraTile(x+2,y).ready) and
               (isSeed(checkTile(x+3,y).fg) and getExtraTile(x+3,y).ready) and
               (isSeed(checkTile(x+4,y).fg) and getExtraTile(x+4,y).ready) then
               
                if checkInventoryAndSave(currentWorld) then
                    return harvest(currentWorld)
                end
                GoToTile(x+2, y)
                for i=0,4 do
                    while isSeed(checkTile(x+i, y).fg) and getExtraTile(x+i, y).ready do
                        if checkInventoryAndSave(currentWorld) then
                            return harvest(currentWorld)
                        end
                        punch(x+i, y)
                        sleep(HarvestDelay)
                    end
                end
                collect()
                sleep(180)

            -- 4'lü kombinasyon
            elseif x+3 <= 99 and
               (isSeed(checkTile(x,y).fg) and getExtraTile(x,y).ready) and
               (isSeed(checkTile(x+1,y).fg) and getExtraTile(x+1,y).ready) and
               (isSeed(checkTile(x+2,y).fg) and getExtraTile(x+2,y).ready) and
               (isSeed(checkTile(x+3,y).fg) and getExtraTile(x+3,y).ready) then
               
                if checkInventoryAndSave(currentWorld) then
                    return harvest(currentWorld)
                end
                GoToTile(x+1, y)
                for i=0,3 do
                    while isSeed(checkTile(x+i, y).fg) and getExtraTile(x+i, y).ready do
                        if checkInventoryAndSave(currentWorld) then
                            return harvest(currentWorld)
                        end
                        punch(x+i, y)
                        sleep(HarvestDelay)
                    end
                end
                collect()
                sleep(180)

            -- 3'lü kombinasyon
            elseif x+2 <= 99 and
               (isSeed(checkTile(x,y).fg) and getExtraTile(x,y).ready) and
               (isSeed(checkTile(x+1,y).fg) and getExtraTile(x+1,y).ready) and
               (isSeed(checkTile(x+2,y).fg) and getExtraTile(x+2,y).ready) then
               
                if checkInventoryAndSave(currentWorld) then
                    return harvest(currentWorld)
                end
                GoToTile(x+1, y)
                for i=0,2 do
                    while isSeed(checkTile(x+i, y).fg) and getExtraTile(x+i).ready do
                        if checkInventoryAndSave(currentWorld) then
                            return harvest(currentWorld)
                        end
                        punch(x+i, y)
                        sleep(HarvestDelay)
                    end
                end
                collect()
                sleep(180)

            -- 2'li kombinasyon
            elseif x+1 <= 99 and
               (isSeed(checkTile(x,y).fg) and getExtraTile(x,y).ready) and
               (isSeed(checkTile(x+1,y).fg) and getExtraTile(x+1,y).ready) then
               
                if checkInventoryAndSave(currentWorld) then
                    return harvest(currentWorld)
                end
                GoToTile(x, y)
                for i=0,1 do
                    while isSeed(checkTile(x+i, y).fg) and getExtraTile(x+i).ready do
                        if checkInventoryAndSave(currentWorld) then
                            return harvest(currentWorld)
                        end
                        punch(x+i, y)
                        sleep(HarvestDelay)
                    end
                end
                collect()
                sleep(180)

            -- Tekli seed
            elseif (isSeed(checkTile(x,y).fg) and getExtraTile(x,y).ready) then
                if checkInventoryAndSave(currentWorld) then
                    return harvest(currentWorld)
                end
                GoToTile(x, y)
                while isSeed(checkTile(x,y).fg) and getExtraTile(x,y).ready do
                    if checkInventoryAndSave(currentWorld) then
                        return harvest(currentWorld)
                    end
                    punch(x, y)
                    sleep(HarvestDelay)
                end
                collect()
                sleep(180)
            end
        end
    end
    checkRemain()
end
function checkSeed()
    for y = 0, 53 do
        for x = 0, 99 do
            if isSeed(checkTile(x,y).fg) then return true end
        end
    end
    return false
end


function main()
    local currentIndex = 1
    while currentIndex <= #WorldList do
        currentWorld = WorldList[currentIndex] -- artık global değişiyo
        repeat
            harvest(currentWorld)
        until not checkSeed()
        currentIndex = currentIndex + 1
    end
end

while true do
    local ok, err = pcall(function()
        main()
    end)

    if not ok then
        

        local saveName = getWorldNameFromEntry(Save)
        local worldName = getWorldNameFromEntry(currentWorld)
        local current = getWorld().name:lower()

        if current == worldName:lower() then
            -- Harvest worldündeyiz, kaldığı yerden devam et
            harvest(currentWorld)

        elseif current == saveName:lower() then
            -- Save worldündeyiz → currentWorld'e dön
            sendPacket(3, "action|join_request\nname|" .. worldName .. "\ninvitedWorld|0")
            sleep(WarpDelay)
            sendPacket(3, "action|join_request\nname|" .. currentWorld .. "\ninvitedWorld|0")
            sleep(WarpDelay)
            
            -- World yüklendikten sonra harvest
            local tries = 0
            while not isinworld(worldName) and tries < 15 do
                sleep(2500)
                tries = tries + 1
            end

            harvest(currentWorld)

        else
            -- Başka bir world → bekle
            sleep(1000)
        end

        sleep(2000) -- ekstra bekleme
    end
end
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








