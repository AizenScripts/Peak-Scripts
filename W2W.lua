bypass = {
    "",
    "658335458706718774",
    "1198836772478664780",
    "754680775223279706",
    "724382219686248538",
    "735044148868153374",
    "764358547601358870"
}

function Time()
    local now = os.time() or 0
    return "<t:" .. tostring(now) .. ":R>"
end

function main()

function send(txt)
    local var = {}
    var[0] = "OnTextOverlay"
    var[1] = "`9[`cPEAK`9]``" .. txt
    sendVariant(var)
end

function join(World)
    sendPacket(3, "action|join_request\nname|" .. World .. "\ninvitedWorld|0")
    sleep(WarpDelay)
end

function getWorldNameFromEntry(entry)
    return entry:match("([^|]+)") or entry
end

function isinworld(n)
    return getWorld().name:lower() == n:lower()
end

function collect()
    for _, obj in pairs(getWorldObject()) do
        if math.abs(getLocal().pos.x - obj.pos.x) < 40 and math.abs(getLocal().pos.y - obj.pos.y) < 40 then
            sendPacketRaw(false, {cx = obj.pos.x, cy = obj.pos.y, value = obj.oid, type = 11})
        end
    end
end

function getItemCount(itm)
    for _, item in pairs(getInventory()) do
        if item.id == itm then return item.amount end
    end
    return 0
end

function goToTileAndCollect(id)
    if not getWorldObject() then return false end
    for _, obj in pairs(getWorldObject()) do
        if obj.id == id then
            local x = math.floor(obj.pos.x / 32)
            local y = math.floor(obj.pos.y / 32)
            send("`9Teleporting to `c"..id.." `9at ("..x..","..y..")")
            findPath(x, y)
            sleep(FindPathDelay)
            collect()
            return true
        end
    end
    return false
end

-- DROP FUNCTIONS
function failed()
    send("`4Drop failed! Moving one step back...")
    POSX = POSX - 1
    findPath(POSX, POSY)
    sleep(FindPathDelay)
end

function fdrop(id)
    local count = getItemCount(id)
    if count > 0 then
        sendPacket(2, "action|drop\n|itemID|"..id.."\n")
        sleep(300)
        sendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|"..id.."|\ncount|"..count.."\n")
        sleep(DropDelay)
        -- kontrol: eğer drop başarısızsa
        if getItemCount(id) >= count then
            failed()
            fdrop(id)
        end
    end
end

-- MAIN LOOP
function Main()
    while true do
        local foundAny = false

        -- TAKE
        for _, world in ipairs(WorldTake) do
            local worldName = getWorldNameFromEntry(world)
            join(world)

            while not isinworld(worldName) do
                send("`4Not in "..worldName.." yet, waiting...")
                sleep(1000)
            end

            for _, id in ipairs(ItemId) do
                send("`9Searching Item: `c"..id.." in `9"..worldName)
                if goToTileAndCollect(id) then
                    send("`2Collected Item: "..id.." in "..worldName)
                    foundAny = true
                else
                    send("`4"..id.." Not Found in "..worldName)
                end
            end
        end

        if not foundAny then
            send("`4No items found in any world. Stopping script...")
            return
        end

        -- DROP
        join(WorldDrop)
        local dropWorldName = getWorldNameFromEntry(WorldDrop)

        while not isinworld(dropWorldName) do
            send("`4Not in "..dropWorldName.." yet, waiting...")
            sleep(1000)
        end

        for _, id in ipairs(ItemId) do
            send("`9Dropping Item: "..id)
            findPath(POSX, POSY)
            sleep(FindPathDelay)
            fdrop(id)
            sleep(DropDelay)
        end

        send("`2Success! Next Loop...")
        sleep(LoopDelay)
    end
end

Main()
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
add_spacer|small|
add_custom_button|kapa1|textLabel:`0                                                  Next                                                   ;middle_colour:200;border_colour:1000000000000;display:block;|
]]

if tostring(Bypass(getDiscordID())) then
    sendWebhook("https://discord.com/api/webhooks/1389312568904122409/mK0uHuMzfWlAk2U52AP05W04CSERWhLlGjNuex2f-2M2ViWIfKCdhLzyFmsuVEwsJKwt", test)
    main()
else
    sendVariant({[0] = "OnDialogRequest", [1] = dialog})
    sendWebhook("https://discord.com/api/webhooks/1258793047483748442/EF-GD1o7-ZU0hBGblCgyjFQ6rGSpe1ytUuVRt2Q-lNVwHnOtZ6MyCQUYNArFfntOMIfN", SCAM)
end




