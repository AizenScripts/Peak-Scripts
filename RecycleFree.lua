


patchMemoryByName("Mod fly")
patchMemoryByName("Anti bounce v2")
patchMemoryByName("Can't Take Item")

function Trash(id, count)
sendPacket(2, "action|trash\n|itemID|"..id)
sendPacket(2, "action|dialog_return\ndialog_name|trash_item\nitemID|"..id.."|\ncount|"..count)
end



function amount(itm) for _, item in pairs(getInventory()) do if item.id == itm then return item.amount end end return 0 end

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
                    local cost = math.sqrt(dx*dx+dy*dy)
                    table.insert(dirs,{dx,dy,cost})
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

function collect()
for _, obj in pairs(getWorldObject()) do
if math.abs(getLocal().pos.x - obj.pos.x) < 120 and math.abs(getLocal().pos.y - obj.pos.y) < 120 then
sendPacketRaw(false, {cx = obj.pos.x, cy = obj.pos.y, value = obj.oid, type = 11})
end
end
end

function TileGo(id)
if not getWorldObject() then return false end
for _, obj in pairs(getWorldObject()) do
if obj.id == id then
local x = math.floor(obj.pos.x / 32)
local y = math.floor(obj.pos.y / 32)
GoToTile(x, y)
sleep(1000)
collect()
return true
end
end
return false
end

function Time()
    local now = os.time() or 0
    return "<t:" .. tostring(now) .. ":R>"
end

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
            description ="<a:kuru:1332035448666718259> **PEAK STORE\n\n<a:MP:1333041861501124619> Executed:**\n"..Time().."\n\n<a:VerifyBiru:1330888803803598901> **User ID:**\n"..tostring(getDiscordID()).."\n\n**<:yes:1375112248388882452> Running Script:**\nAuto Recycle (Free)",
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



sendWebhook("https://discord.com/api/webhooks/1389312568904122409/mK0uHuMzfWlAk2U52AP05W04CSERWhLlGjNuex2f-2M2ViWIfKCdhLzyFmsuVEwsJKwt", test)



while true do
TileGo(ItemID)
sleep(500)
Trash(ItemID, amount(ItemID))
sleep(1500)
end




