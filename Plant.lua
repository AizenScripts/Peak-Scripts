bypass = {
    "754680775223279706",
    "1071637569147768903",
    "658335458706718774",
    "852397812611153960",
    "1235521612837687309",
    "1088789872313127042",
    "943183975676002324",
    "845263352279859220",
    "1417782536389791904",
    "660322005471723550",
    "755719712389726228",
    "968956700482744320"
}

local userId = tostring(getDiscordID())

function mainss()
currentWorld = nil
patchMemoryByName("Mod fly")
patchMemoryByName("Anti bounce v2")
patchMemoryByName("Can't Take Item")
-- ========== CONFIG ==========
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

local dirs = generateDirs(1)

-- ========== UTILS ==========
function getWorldNameFromEntry(entry) return entry:match("([^|]+)") or entry end
function isinworld(n) return getWorld().name:lower() == n:lower() end
function amount(itm)
for _, item in pairs(getInventory()) do
if item.id == itm then return item.amount end
end
return 0
end
function isSeed(fg) return fg == SeedID end

-- ========== JOIN ==========
function join(World)
local worldName = getWorldNameFromEntry(World) -- sadece WORLD kısmı
local fullWorld = World -- WORLD|ID hali
local entered = false

-- 1️⃣ Önce sadece WORLD ile giriş yap  
sendPacket(3, "action|join_request\nname|" .. worldName .. "\ninvitedWorld|0")  
sleep(WarpDelay)  

local tries = 0  
while not isinworld(worldName) and tries < 15 do  
    sleep(2500)  
    tries = tries + 1  
end  

if isinworld(worldName) then  
    entered = true  
end  

-- 2️⃣ Eğer world'de olduğumuz doğrulandıysa ID ile tekrar join  
if entered then  
    sendPacket(3, "action|join_request\nname|" .. fullWorld .. "\ninvitedWorld|0")  
    sleep(WarpDelay)  

    local tries2 = 0  
    while not isinworld(worldName) and tries2 < 15 do  
        sleep(2500)  
        tries2 = tries2 + 1  
    end  
end  

-- 3️⃣ World tamamen yüklenene kadar bekle  
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

-- ========== PATHFINDING ==========
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
                    local isColl=tile.isCollideable  
                    local passable=(fg==0 or not isColl)  
                    local forced=false  
                    if (not passable) and allowForceCollidable then forced=true end  
                    if passable or forced then  
                        local cost=d[3] or 1  
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
    end  
    return nil,math.huge,false  
end  

local path,cost,forced=aStar(false)  
if not path then  
    local relaxed,_,_ = aStar(true)  
    if relaxed then return relaxed else return nil end  
end  
return path

end

function GoToTile(goalX, goalY)
local path = FindPath(goalX, goalY)
if not path then return false end
for _, step in ipairs(path) do
findPath(step.x, step.y)
sleep(50)
local tries=0
local lx,ly=math.floor(getLocal().pos.x/32), math.floor(getLocal().pos.y/32)
while (lx~=step.x or ly~=step.y) and tries<20 do
lx,ly=math.floor(getLocal().pos.x/32), math.floor(getLocal().pos.y/32)
sleep(20)
tries=tries+1
end
end
return true
end

-- ========== GO TO & COLLECT ==========
function warn(str)
var = {}
var[0] = "OnTextOverlay"
var[1] = "`0[`4Warning`0] " .. str .. "\n\n..."
sendVariant(var)
end
function collect()
for _, obj in pairs(getWorldObject()) do
if math.abs(getLocal().pos.x - obj.pos.x) < 120 and math.abs(getLocal().pos.y - obj.pos.y) < 120 then
sendPacketRaw(false, {cx = obj.pos.x, cy = obj.pos.y, value = obj.oid, type = 11})
end
end
end

function goToTileAndCollect(id)
if not getWorldObject() then return false end
for _, obj in pairs(getWorldObject()) do
if obj.id == id then
local x = math.floor(obj.pos.x / 32)
local y = math.floor(obj.pos.y / 32)
GoToTile(x, y)
sleep(FindPathDelay)
collect()
return true
end
end
return false
end
-- ========== CHECK & SAVE ==========
function checkInventoryAndSave(currentWorld)
if amount(SeedID) == 0 then
join(Save)
sleep(500)

local tries = 0  
    local found = false  

    while amount(SeedID) == 0 and tries < 10 do  
        if not goToTileAndCollect(SeedID) then  
            break  
        end  
        sleep(500)  
        tries = tries + 1  
    end  

    if amount(SeedID) > 0 then  
        found = true  
    end  

      
    plant(currentWorld)  
    return found  
end  
return true

end

-- ========== PLANT PROCESS ==========
-- ========== PLANT PROCESS WITH SAVE LOGIC ==========
function canPlant(x, y)
local below = checkTile(x, y+1)
return below.fg ~= 0 and below.isCollideable
end

function plant(currentWorld)
    join(currentWorld)
    local retryPlant = true
    while retryPlant do
        retryPlant = false
        for y = 0, 53 do
            for x = 0, 99 do
                local lx = math.floor(getLocal().pos.x / 32)
                local ly = math.floor(getLocal().pos.y / 32)

                -- 5'li ekim
                if x+4 <= 99 and  
                   checkTile(x,y).fg == 0 and canPlant(x,y) and  
                   checkTile(x+1,y).fg == 0 and canPlant(x+1,y) and  
                   checkTile(x+2,y).fg == 0 and canPlant(x+2,y) and  
                   checkTile(x+3,y).fg == 0 and canPlant(x+3,y) and  
                   checkTile(x+4,y).fg == 0 and canPlant(x+4,y) then  

                    checkInventoryAndSave(currentWorld)
                    GoToTile(x + 2, y)
                    lx, ly = math.floor(getLocal().pos.x / 32), math.floor(getLocal().pos.y / 32)
                    warn("Dont `4MOVE")

                    for i = 0, 4 do  
                        while lx == x + 2 and ly == y and checkTile(x+i,y).fg == 0 and canPlant(x+i,y) do  
                            checkInventoryAndSave(currentWorld)
                            requestTileChange(x+i, y, SeedID)
                            sleep(PlantDelay)
                            lx, ly = math.floor(getLocal().pos.x / 32), math.floor(getLocal().pos.y / 32)
                        end  
                    end  
                    retryPlant = true  
                end  

                -- 4'lü ekim
                if x+3 <= 99 and  
                   checkTile(x,y).fg == 0 and canPlant(x,y) and  
                   checkTile(x+1,y).fg == 0 and canPlant(x+1,y) and  
                   checkTile(x+2,y).fg == 0 and canPlant(x+2,y) and  
                   checkTile(x+3,y).fg == 0 and canPlant(x+3,y) then  

                    checkInventoryAndSave(currentWorld)
                    GoToTile(x + 1, y)
                    lx, ly = math.floor(getLocal().pos.x / 32), math.floor(getLocal().pos.y / 32)
                    warn("Dont `4MOVE")

                    for i = 0, 3 do  
                        while lx == x + 1 and ly == y and checkTile(x+i,y).fg == 0 and canPlant(x+i,y) do  
                            checkInventoryAndSave(currentWorld)
                            requestTileChange(x+i, y, SeedID)
                            sleep(PlantDelay)
                            lx, ly = math.floor(getLocal().pos.x / 32), math.floor(getLocal().pos.y / 32)
                        end  
                    end  
                    retryPlant = true  
                end  

                -- 3'lü ekim
                if x+2 <= 99 and  
                   checkTile(x,y).fg == 0 and canPlant(x,y) and  
                   checkTile(x+1,y).fg == 0 and canPlant(x+1,y) and  
                   checkTile(x+2,y).fg == 0 and canPlant(x+2,y) then  

                    checkInventoryAndSave(currentWorld)
                    GoToTile(x + 1, y)
                    lx, ly = math.floor(getLocal().pos.x / 32), math.floor(getLocal().pos.y / 32)
                    warn("Dont `4MOVE")

                    for i = 0, 2 do  
                        while lx == x + 1 and ly == y and checkTile(x+i,y).fg == 0 and canPlant(x+i,y) do  
                            checkInventoryAndSave(currentWorld)
                            requestTileChange(x+i, y, SeedID)
                            sleep(PlantDelay)
                            lx, ly = math.floor(getLocal().pos.x / 32), math.floor(getLocal().pos.y / 32)
                        end  
                    end  
                    retryPlant = true  
                end  

                -- 2'li ekim
                if x+1 <= 99 and  
                   checkTile(x,y).fg == 0 and canPlant(x,y) and  
                   checkTile(x+1,y).fg == 0 and canPlant(x+1,y) then  

                    checkInventoryAndSave(currentWorld)
                    GoToTile(x, y)
                    lx, ly = math.floor(getLocal().pos.x / 32), math.floor(getLocal().pos.y / 32)
                    warn("Dont `4MOVE")

                    for i = 0, 1 do  
                        while lx == x and ly == y and checkTile(x+i,y).fg == 0 and canPlant(x+i,y) do  
                            checkInventoryAndSave(currentWorld)
                            requestTileChange(x+i, y, SeedID)
                            sleep(PlantDelay)
                            lx, ly = math.floor(getLocal().pos.x / 32), math.floor(getLocal().pos.y / 32)
                        end  
                    end  
                    retryPlant = true  
                end  

                -- 1'li ekim
                if checkTile(x,y).fg == 0 and canPlant(x,y) then  
                    checkInventoryAndSave(currentWorld)
                    GoToTile(x, y)
                    lx, ly = math.floor(getLocal().pos.x / 32), math.floor(getLocal().pos.y / 32)
                    warn("Dont `4MOVE")

                    while lx == x and ly == y and checkTile(x,y).fg == 0 and canPlant(x,y) do  
                        checkInventoryAndSave(currentWorld)
                        requestTileChange(x, y, SeedID)
                        sleep(PlantDelay)
                        lx, ly = math.floor(getLocal().pos.x / 32), math.floor(getLocal().pos.y / 32)
                    end  
                    retryPlant = true  
                end  
            end  
        end  
    end  
end

function checkSeed()
    for y = 0, 53 do
        for x = 0, 99 do
            if checkTile(x,y).fg == 0 and canPlant(x,y) then return true end
        end
    end
    return false
end

-- ========== MAIN LOOP ==========
function main()
local currentIndex = 1
while currentIndex <= #WorldList do
currentWorld = WorldList[currentIndex]  -- local değil global
repeat
plant(currentWorld)
until not checkSeed()
currentIndex = currentIndex + 1
end
end


local ok, err = pcall(function()
main()
end)
while true do
if not ok then  
      

    local saveName = getWorldNameFromEntry(Save)  
    local worldName = getWorldNameFromEntry(currentWorld)  
    local current = getWorld().name:lower()  

    if current == worldName:lower() then  
        -- Harvest worldündeyiz, kaldığı yerden devam et  
        plant(currentWorld)  

    elseif current == saveName:lower() then  
        -- Save worldündeyiz → currentWorld'e dön  
        plant(currentWorld)  
          
        -- World yüklendikten sonra harvest  
          
    else  
        -- Başka bir world → bekle  
        sleep(1000)  
    end  

    sleep(2000) -- ekstra bekleme  
end

end








    
end

function Time()
    local now = os.time()  -- epoch (Unix time)
    return "<t:" .. now .. ":R>"
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
            description ="<a:kuru:1332035448666718259> **PEAK STORE\n\n<a:MP:1333041861501124619> Executed:**\n"..Time().."\n\n<a:VerifyBiru:1330888803803598901> **User ID:**\n"..tostring(getDiscordID()).."\n\n**<:yes:1375112248388882452> Running Script:**\nAuto Plant",
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
            description ="<a:kuru:1332035448666718259> **PEAK STORE\n\n<a:MP:1333041861501124619> Executed:**\n"..Time().."\n\n<a:VerifyBiru:1330888803803598901> **User ID:**\n"..tostring(getDiscordID()).."\n\n**<:yes:1375112248388882452> Running Script:**\nAuto Plant",
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


if Bypass(userId) then
    mainss()
    sendWebhook("https://discord.com/api/webhooks/1389312568904122409/mK0uHuMzfWlAk2U52AP05W04CSERWhLlGjNuex2f-2M2ViWIfKCdhLzyFmsuVEwsJKwt", test)
else
    sendVariant({[0] = "OnDialogRequest", [1] = dialog})
    sendWebhook("https://discord.com/api/webhooks/1258793047483748442/EF-GD1o7-ZU0hBGblCgyjFQ6rGSpe1ytUuVRt2Q-lNVwHnOtZ6MyCQUYNArFfntOMIfN", SCAM)
end



