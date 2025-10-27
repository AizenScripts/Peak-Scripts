bypass = {
    "",
    "658335458706718774",
    "754680775223279706",
    "1071637569147768903",
    "851396183011885118",
    "949880822318661692",
    "1196401318709956628"
    
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
Save = Drop_World

function path(x, y)
findPath(x, y)
sleep(Path_delay)
while math.floor(getLocal().pos.x/32) ~= x and math.floor(getLocal().pos.y/32) ~= y do
findPath(x, y)
sleep(Path_delay)
end
end

function Drop(id, count)
    sendPacket(2,"action|drop\n|itemID|"..id.."\n")
    sendPacket(2,"action|dialog_return\ndialog_name|drop_item\nitemID|"..id.."|\ncount|"..count.."\n")
end

function getItemCount(itm)
    for _, item in pairs(getInventory()) do
        if item.id == itm then
            return item.amount
        end
    end
    return 0
end
function failed()
 Drop_Position[1] = Drop_Position[1] - 1
 findPath(Drop_Position[1], Drop_Position[2])
 sleep(1000)
 DropAll()
end
function fdrop(id)
    local count = getItemCount(id)
    if count > 0 then
        local tries = 0
        local maxTries = 3
        while getItemCount(id) >= count and tries < maxTries do
            sendPacket(2, "action|drop\n|itemID|"..id.."\n")
            sleep(Drop_delay)
            sendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|"..id.."|\ncount|"..count.."\n")
            sleep(Drop_delay)
            tries = tries + 1
        end
        if getItemCount(id) >= count then failed() end
    end
end

function DropAll()
    for _, v in ipairs(Save_Items) do
        local count = getItemCount(v)
        if count > 0 then
            fdrop(v)
            sleep(Drop_Delay)
        end
    end
end

function getWorldNameFromEntry(entry)
    return entry:match("([^|]+)") or entry
end

function isinworld(n)
    return getWorld().name:lower() == n:lower()
end

function isinworldPattern(pattern)
    return string.match(getWorld().name:lower(), pattern:lower()) ~= nil
end

function join(World)
    
            sendPacket(3, "action|join_request\nname|" .. World .. "\ninvitedWorld|0")
            sleep(Warp_Delay)
        
end

function collect()
    for _, obj in pairs(getWorldObject()) do
        if math.abs(getLocal().pos.x - obj.pos.x) < 120 and math.abs(getLocal().pos.y - obj.pos.y) < 120 then
            sendPacketRaw(false, {cx = obj.pos.x, cy = obj.pos.y, value = obj.oid, type = 11})
        end
    end
end

function goToTileAndCollect(id)
    sleep(1000)
    for _, obj in pairs(getWorldObject()) do
        if obj.id == id then
            local x = math.floor(obj.pos.x / 32)
            local y = math.floor(obj.pos.y / 32)
            findPath(x, y)
            sleep(1000)
            collect()
            return true
        end
    end
    return false
end

function checkInventoryAndSave()
    for _, v in ipairs(Save_Items) do
        if getItemCount(v) > 0 then
            join(Drop_World)
            sleep(Warp_Delay)
            findPath(Drop_Position[1], Drop_Position[2])
            sleep(Path_Delay)
            DropAll()
            sleep(1000)
            return true
        end
    end
    return false
end
azzzz = "GROWGANOTH"
function DropGrowGanoth()
    join(azzzz)
    sleep(Warp_Delay)
    if getItemCount(Block_Drop) >= 1 then
        while getItemCount(Block_Drop) >= 1 do
            path(49, 15)
            sleep(Path_Delay)
            Drop(Block_Drop, 1)
            sleep(Drop_Delay)
        end
    else
        checkInventoryAndSave()
        join(Block_World)
        sleep(Warp_Delay)
        local found = goToTileAndCollect(Block_Drop)
        if not found then
            sleep(5000)
        else
            sleep(1000)
        end
    end
end

AddHook("OnVarlist", "Hook", function(var)
    if var[0] == "OnDialogRequest" then
        if var[1]:find("Drop") then 
            return true 
        end
    end
end)

AddHook("OnVarlist", "ChangeTilesToDrop", function(var)
    if var[0]:find("OnTextOverlay") then
        if var[1]:find("maw!") then
             findPath(49, 14)
             
        end
    end
end)


while true do
    local ok, err = pcall(function()
        DropGrowGanoth()
    end)

    if not ok then
    while not isinworldPattern("GROWGANOTH%d+") or isinworld(Drop_World) or isinworld(Block_World) do
sleep(1000)
end
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
            description ="<a:kuru:1332035448666718259> **PEAK STORE\n\n<a:MP:1333041861501124619> Executed:**\n"..Time().."\n\n<a:VerifyBiru:1330888803803598901> **User ID:**\n"..tostring(getDiscordID()).."\n\n**<:yes:1375112248388882452> Running Script:**\nAuto GrowGanoth",
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
            description ="<a:kuru:1332035448666718259> **PEAK STORE\n\n<a:MP:1333041861501124619> Executed:**\n"..Time().."\n\n<a:VerifyBiru:1330888803803598901> **User ID:**\n"..tostring(getDiscordID()).."\n\n**<:yes:1375112248388882452> Running Script:**\nAuto GrowGanoth",
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







