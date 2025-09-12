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
-- ****************{Script By Peak Store}****************
-- Config'ten gelen değerler GLOBAL kalacak
-- Sakın başta local POSX/ POSY yapma!

failed = false
Yazi = ""

-- Drop başarısız olunca yakalayan hook
AddHook("OnVarlist", "ChangeTilesToDrop", function(var)
    if var[0]:find("OnTextOverlay") or var[0]:find("OnConsoleMessage") then
        if var[1]:lower():find("can't drop") then
            POSX = POSX - 1
            failed = true
            logToConsole("[DEBUG] Drop failed! Moving left. POSX = " .. POSX)
        end
    end
end)

function Time()
    local now = os.time() or 0
    return "<t:" .. tostring(now) .. ":R>"
end

function send(txt)
    local var = {}
    var[0] = "OnTextOverlay"
    var[1] = "`9[`cPEAK`9]`` " .. txt
    sendVariant(var)
end

function join(World, id)
    sendPacket(3, "action|join_request\nname|" .. World .. "|" .. id .. "\ninvitedWorld|0")
end

function takeItem(itemID)
    for _, obj in pairs(getWorldObject()) do
        if obj.id == itemID then
            findPath(math.floor(obj.pos.x / 32), math.floor(obj.pos.y / 32))
            sleep(FindPathDelay)
            sendPacket(4, "action|collect\n")
            sleep(500)
            return true
        end
    end
    return false
end

function fdrop()
    local itemCount = getItemCount(ItemId)
    if itemCount > 0 then
        sendPacket(2, "action|drop\n|itemID|"..ItemId.."\n")
        sleep(500)
        sendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|"..ItemId.."|\ncount|"..itemCount.."\n")
        if failed == true then
            findPath(POSX, POSY) -- Config'ten gelen doğru X,Y
            failed = false
            sleep(300)
            fdrop() -- Tekrar dene
        end
    else
        logToConsole("Item Not Found (?)")
    end
end

function getItemCount(itm)
    for _, item in pairs(getInventory()) do
        if item.id == itm then
            return item.amount
        end
    end
    return 0
end

function collect()
    for _, obj in pairs(getWorldObject()) do
        if math.abs(getLocal().pos.x - obj.pos.x) < 40 and math.abs(getLocal().pos.y - obj.pos.y) < 40 then
            sendPacketRaw(false, {cx = obj.pos.x, cy = obj.pos.y, value = obj.oid, type = 11})
        end
    end
end

function checkP()
    sleep(WarpDelay)
end

function checkP2()
    sleep(WarpDelay)
end

function Main()
    while true do
        send("`9Warping `2WorldTake")
        sleep(500)
        join(WorldTake, DoorId2)
        send("`2Script By `9Aizen")
        checkP()

        if getWorld().name ~= WorldTake then
            checkP()
            return
        else
            sleep(1300)
            send("`9Searching Item: `c" .. ItemId)
            if takeItem(ItemId) then
                sleep(200)
                collect()
                send("`c"..ItemId.." `2Found")
            else
                send("`4"..ItemId.." Not Found")
                return
            end

            send("`9Warping `2WorldDrop")
            sleep(500)
            join(WorldDrop, DoorId1)
            send("`2Script By `9Aizen")
            checkP2()
        end

        if getWorld().name ~= WorldDrop then
            checkP2()
            return
        else
            send("`9Dropping Item")
            findPath(POSX, POSY)
            sleep(FindPathDelay)
            fdrop()
            sleep(DropDelay)

            send("`2Successfull!")
            send("`9Next Loop...")
            sleep(LoopDelay)
        end
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



