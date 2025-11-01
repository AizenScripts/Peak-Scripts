bypass = {
    "754680775223279706",
    "724382219686248538",
    "764358547601358870",
    "1071637569147768903",
    "1243643767739908287",
    "1397399885719932991",
    "1401537729526894725",
    "1418763558266605598",
    "1063322869624492062",
    "442849002485186561",
    "1383531312341717123",
    "949880822318661692",
    "1102214188883005470"
}

local userId = tostring(getDiscordID())

function main()
    Leaks = [[
set_bg_color|10,10,10,225
set_border_color|255,255,255,180
set_default_color|`o
embed_data|netID|1
add_label_with_icon|big|``Leak Menu 1.0``|left|2380|
add_spacer|small|
add_spacer|small|
add_label_with_icon|small|`0Author: `9Peak Store|left|6124|
add_spacer|small|
add_label_with_icon|small|`2[+] `c/Path        `9->   `0Change ID|left|1684|
add_label_with_icon|small|`2[+] `c/Magnet  `9->   `0Long Take Item|left|6140|
add_label_with_icon|small|`2[+] `c/Vault       `9->   `0Bypass Safe Vault|left|8878|
add_label_with_icon|small|`2[+] `c/Mq          `9->   `0Take Mannequin Item|left|1420|
add_label_with_icon|small|`2[+] `c/Db           `9->   `0Take Display Block|left|2946|
add_label_with_icon|small|`2[+] `c/Ds            `9->   `0Take Display Shelf|left|3794|
add_label_with_icon|small|`2[+] `c/Gaia         `9->   `0Take Gaia Seed|left|6946|
add_label_with_icon|small|`2[+] `c/Ut            `9->   `0Take Ut Block|left|6948|
add_spacer|small|
add_spacer|small|
add_custom_button|kapa1|textLabel:`0                         Done                           ;middle_colour:200;border_colour:1000000000000;display:block;|
]]
sendVariant({[0] = "OnDialogRequest", [1] = Leaks})

-- ########### PATH MARKER / PATH ###########
function marker(x, y, id)
    sendPacket(2,
        "action|dialog_return\ndialog_name|sign_edit\ntilex|"..x.."|\ntiley|"..y.."|\nsign_text|"..id
    )
end 

function send(txt)
    local var = {}
    var[0] = "OnTextOverlay"
    var[1] = "`9[`cPEAK`9]``" .. txt
    sendVariant(var)
end

local pathMarkerIDs = {1684, 4482}

function getPath()
    local f, world = {}, getWorld()
    for x = 0, world.width -1 do 
        for y = 0, world.height -1 do 
            local tile = checkTile(x, y)
            if tile then
                for _, id in ipairs(pathMarkerIDs) do
                    if tile.fg == id then
                        tile.pos = { x = x, y = y, id = id }
                        table.insert(f, tile)
                    end
                end
            end
        end
    end

    local var = {}
    for _, tile in ipairs(f) do 
        local x, y, id = tile.pos.x, tile.pos.y, tile.pos.id
        local buttonID = "warp_"..x.."_"..y
        local name = getItemByID(id).name
        local str = string.format(
            "\nadd_label_with_icon_button|small|`0%s At `9(`2%d`9, `2%d`9)|left|%d|%s|\n",
            name, x, y, id, buttonID
        )
        table.insert(var, str)
    end

    return table.concat(var)
end

function pathDialog()
    return [[
set_bg_color|10,10,10,225
set_border_color|255,255,255,180
add_label_with_icon|big|`0PathMarker Menu|left|1684|
add_spacer|small|
add_smalltext|`2Click Button To Warp To Path Marker|
]] .. getPath() .. [[
add_spacer|small|
add_quick_exit|
end_dialog|scanbilek|Done||
]]
end

AddHook("OnTextPacket", "warpHelper", function(_, pkt)
    if pkt:find("/Path") or pkt:find("/path") then
        sendVariant({ [0] = "OnDialogRequest", [1] = pathDialog() }, -1)
        return true
    end

    local x, y = pkt:match("buttonClicked|warp_(%d+)_(%d+)")
    if x and y then
        x, y = tonumber(x), tonumber(y)
        send("Path To : `9"..x.." `c- `9"..y)
        runThread(function()
            local id = "PEAK"
            sleep(500)
            marker(x, y, id)
            sleep(1000)
            local world = getWorld().name
            sendPacket(3, "action|join_request\n|name|"..world.."|"..id.."\n|invitedWorld|0")
        end)
        return true
    end
end)

-- ########### MAGNET / MAGNET ###########
local itemInfo = {}

function getItemObject()
    itemInfo = {}
    for _, item in pairs(getWorldObject()) do
        local name = getItemByID(item.id).name or "Unknown"
        local line = "\nadd_label_with_icon_button|small|`9Name : `0"..name.." `9Amount : `0[`c"..item.amount.."`0]|left|"..item.id.."|"..item.oid.."|\n"
        table.insert(itemInfo, line)
    end
end

function take(id)
    local x, y = 0, 0
    sendPacket(2,"action|dialog_return\ndialog_name|extractor\ntilex|"..x.."|\ntiley|"..y.."|\nstartIndex|0|\nextractorID|6140|\nbuttonClicked|extractOnceObj_"..tostring(id))
end

function magnetHook(type, packet)
    if packet:find("/Magnet") or packet:find("/magnet") then
        getItemObject()
        local var = {}
        var[0] = "OnDialogRequest"
        var[1] = string.format(
            "set_bg_color|10,10,10,225\nset_border_color|255,255,255,180\nadd_label_with_icon|big|`0Magnet Menu|left|6140|\nadd_spacer|small|\nadd_smalltext|`2Click To Button For Collect Item|\n"..table.concat(itemInfo).."\nadd_quick_exit|||\nend_dialog|scanbilek|Done||"
        )
        sendVariant(var,-1,100)
    end

    local po = packet:match("dialog_name|scanbilek\nbuttonClicked|(%d+)")
    if po then
        local x, y = 0, 0
        sendPacket(2,"action|dialog_return\ndialog_name|extractor\ntilex|"..x.."|\ntiley|"..y.."|\nstartIndex|0|\nextractorID|6140|\nbuttonClicked|extractOnceObj_"..po)
    end
end
AddHook("OnTextPacket","Hookied",magnetHook)

-- ########### SAFEVAULT / VAULT ###########
function addToStorage(x, y)
    sendPacket(2,
        "action|dialog_return\ndialog_name|storageboxxtreme\ntilex|"..x.."|\ntiley|"..y.."|\nitemid|2|\nbuttonClicked|do_add\n\nitemcount|1"
    )
end 

function getStorageBlocks()
    local f, world = {}, getWorld()
    for x = 0, world.width -1 do 
        for y = 0, world.height -1 do 
            local tile = checkTile(x, y)
            if tile and tile.fg == 8878 then
                tile.pos = { x = x, y = y }
                table.insert(f, tile)
            end 
        end
    end

    local var, name = {}, getItemByID(8878).name 
    for _, tile in ipairs(f) do 
        local x, y = tile.pos.x, tile.pos.y
        local buttonID = "storage_"..x.."_"..y
        local str = string.format(
            "\nadd_label_with_icon_button|small|`0%s at `9(`2%d`9, `2%d`9)|left|8878|%s|\n",
            name, x, y, buttonID
        )
        table.insert(var, str)
    end

    return table.concat(var)
end

function vaultDialog()
    return [[
set_bg_color|10,10,10,225
set_border_color|255,255,255,180
add_label_with_icon|big|`0Vault Menu|left|8878|
add_spacer|small|
add_smalltext|`2Click To Button For Bypass|
]] .. getStorageBlocks() .. [[
add_spacer|small|
add_quick_exit|
end_dialog|scanstorage|Done||
]]
end

AddHook("OnTextPacket", "storageclick", function(_, pkt)
    if pkt:find("/Vault") or pkt:find("/vault") then
        sendVariant({ [0] = "OnDialogRequest", [1] = vaultDialog() }, -1)
        return true
    end

    local x, y = pkt:match("buttonClicked|storage_(%d+)_(%d+)")
    if x and y then
        x, y = tonumber(x), tonumber(y)
        send("Bypas Vault at X:`2"..x.."`` Y:`2"..y)
        runThread(function()
            sleep(500)
            addToStorage(x, y)
        end)
        return true
    end
end)

-- ########### DISPLAY BLOCK / Db ###########
function addToDisplay(x, y)
    sendPacket(2,
        "action|dialog_return\ndialog_name|displayblock\ntilex|"..x.."|\ntiley|"..y.."|\nitemid|2|\nbuttonClicked|additem\nitemcount|1"
    )
end 

function getDisplayBlocks()
    local f, world = {}, getWorld()
    for x = 0, world.width -1 do 
        for y = 0, world.height -1 do 
            local tile = checkTile(x, y)
            if tile and tile.fg == 2946 then
                tile.pos = { x = x, y = y }
                table.insert(f, tile)
            end 
        end
    end

    local var, name = {}, getItemByID(2946).name 
    for _, tile in ipairs(f) do 
        local x, y = tile.pos.x, tile.pos.y
        local buttonID = "display_"..x.."_"..y
        local str = string.format(
            "\nadd_label_with_icon_button|small|`0%s at `9(`2%d`9, `2%d`9)|left|2946|%s|\n",
            name, x, y, buttonID
        )
        table.insert(var, str)
    end

    return table.concat(var)
end

function displayDialog()
    return [[
set_bg_color|10,10,10,225
set_border_color|255,255,255,180
add_label_with_icon|big|`0DisplayBlock Menu|left|2946|
add_spacer|small|
add_smalltext|`2Click A Button For Collect Item|
]] .. getDisplayBlocks() .. [[
add_spacer|small|
add_quick_exit|
end_dialog|scandisplay|Done||
]]
end

AddHook("OnTextPacket", "displayclick", function(_, pkt)
    if pkt:find("/Db") or pkt:find("/db") then
        sendVariant({ [0] = "OnDialogRequest", [1] = displayDialog() }, -1)
        return true
    end

    local x, y = pkt:match("buttonClicked|display_(%d+)_(%d+)")
    if x and y then
        x, y = tonumber(x), tonumber(y)
        send("Clearing Display at X:`2"..x.."`` Y:`2"..y)
        runThread(function()
            sleep(500)
            addToDisplay(x, y)
        end)
        return true
    end
end)

-- ########### DISPLAY SHELF / Ds ###########
local shelfIDs = {3794, 10190, 10552}

function removeFromShelf(x, y)
    sendPacket(2,
        "action|dialog_return\ndialog_name|dispshelf\ntilex|"..x.."|\ntiley|"..y.."|\nbuttonClicked|remove"
    )
end 

function getShelfBlocks()
    local f, world = {}, getWorld()
    for x = 0, world.width -1 do 
        for y = 0, world.height -1 do 
            local tile = checkTile(x, y)
            for _, id in ipairs(shelfIDs) do
                if tile and tile.fg == id then
                    tile.pos = { x = x, y = y, id = id }
                    table.insert(f, tile)
                end
            end
        end
    end

    local var = {}
    for _, tile in ipairs(f) do 
        local x, y, id = tile.pos.x, tile.pos.y, tile.pos.id
        local buttonID = "shelf_"..x.."_"..y
        local str = string.format(
            "\nadd_label_with_icon_button|small|`0%s at `9(`2%d`9, `2%d`9)|left|%d|%s|\n",
            getItemByID(id).name, x, y, id, buttonID
        )
        table.insert(var, str)
    end

    return table.concat(var)
end

function shelfDialog()
    return [[
set_bg_color|10,10,10,225
set_border_color|255,255,255,180
add_label_with_icon|big|`0Shelf Menu|left|3794|
add_spacer|small|
add_smalltext|`2Click To Button For Take Item|
]] .. getShelfBlocks() .. [[
add_spacer|small|
add_quick_exit|
end_dialog|scanshelf|Done||
]]
end

AddHook("OnTextPacket", "shelfclick", function(_, pkt)
    if pkt:find("/Ds") or pkt:find("/ds") then
        sendVariant({ [0] = "OnDialogRequest", [1] = shelfDialog() }, -1)
        return true
    end

    local x, y = pkt:match("buttonClicked|shelf_(%d+)_(%d+)")
    if x and y then
        x, y = tonumber(x), tonumber(y)
        send("Clearing Display at X:`2"..x.."`` Y:`2"..y)
        runThread(function()
            sleep(500)
            removeFromShelf(x, y)
        end)
        return true
    end
end)

-- ########### MANNEQUIN / Mq ###########
local mannequinIDs = {1420, 6214, 10072, 10074, 10076, 10078, 13000, 15498}

function clearMannequin(x, y)
    sendPacket(2,
        "action|dialog_return\n" ..
        "dialog_name|mannequin_edit\n" ..
        "tilex|"..x.."|\n" ..
        "tiley|"..y.."|\n" ..
        "buttonClicked|clear\n" ..
        "checkbox|0\ncheckbox|0\ncheckbox|0\ncheckbox|0\nsign_text|"
    )
end 

function getMannequins()
    local f, world = {}, getWorld()
    for x = 0, world.width -1 do 
        for y = 0, world.height -1 do 
            local tile = checkTile(x, y)
            for _, id in ipairs(mannequinIDs) do
                if tile and tile.fg == id then
                    tile.pos = { x = x, y = y, id = id }
                    table.insert(f, tile)
                end
            end
        end
    end

    local var = {}
    for _, tile in ipairs(f) do 
        local x, y, id = tile.pos.x, tile.pos.y, tile.pos.id
        local buttonID = "man_"..x.."_"..y
        local str = string.format(
            "\nadd_label_with_icon_button|small|`0%s at `9(`2%d`9, `2%d`9)|left|%d|%s|\n",
            getItemByID(id).name, x, y, id, buttonID
        )
        table.insert(var, str)
    end

    return table.concat(var)
end

function mannequinDialog()
    return [[
set_bg_color|10,10,10,225
set_border_color|255,255,255,180
add_label_with_icon|big|`0Mannequin Menu|left|1420|
add_spacer|small|
add_smalltext|`2Click To Button For Collect|
]] .. getMannequins() .. [[
add_spacer|small|
add_quick_exit|
end_dialog|scanman|Done||
]]
end

AddHook("OnTextPacket", "manclick", function(_, pkt)
    if pkt:find("/Mq") or pkt:find("/mq") then
        sendVariant({ [0] = "OnDialogRequest", [1] = mannequinDialog() }, -1)
        return true
    end

    local x, y = pkt:match("buttonClicked|man_(%d+)_(%d+)")
    if x and y then
        x, y = tonumber(x), tonumber(y)
        send("Clearing mannequin at X:`2"..x.."`` Y:`2"..y)
        runThread(function()
            sleep(500)
            clearMannequin(x, y)
        end)
        return true
    end
end)

-- ########### GAIA / Item Sucker Seed ###########
local gaiaID = 6946

function getGaiaBlocks()
    local f, world = {}, getWorld()
    for x = 0, world.width -1 do
        for y = 0, world.height -1 do
            local tile = checkTile(x, y)
            if tile and tile.fg == gaiaID then
                tile.pos = { x = x, y = y }
                table.insert(f, tile)
            end
        end
    end

    local var, name = {}, getItemByID(gaiaID).name
    for _, tile in ipairs(f) do
        local x, y = tile.pos.x, tile.pos.y
        local buttonID = "gaia_"..x.."_"..y
        local str = string.format(
            "\nadd_label_with_icon_button|small|`0%s at `9(`2%d`9, `2%d`9)|left|%d|%s|\n",
            name, x, y, gaiaID, buttonID
        )
        table.insert(var, str)
    end
    return table.concat(var)
end

function gaiaDialog()
    return [[
set_bg_color|10,10,10,225
set_border_color|255,255,255,180
add_label_with_icon|big|`0Gaia Menu|left|6946|
add_spacer|small|
add_smalltext|`2Click A Button To Collect Item|
]] .. getGaiaBlocks() .. [[
add_spacer|small|
add_quick_exit|
end_dialog|scangaia|Done||
]]
end

AddHook("OnTextPacket","gaiaClick",function(_,pkt)
    if pkt:find("/Gaia") or pkt:find("/gaia") then
        sendVariant({ [0] = "OnDialogRequest", [1] = gaiaDialog() }, -1)
        return true
    end

    local x, y = pkt:match("buttonClicked|gaia_(%d+)_(%d+)")
    if x and y then
        x, y = tonumber(x), tonumber(y)
        send("Collecting Gaia at X:`2"..x.."`` Y:`2"..y)
        runThread(function()
            sleep(500)
            sendPacket(2,"action|dialog_return\ndialog_name|itemsucker_seed\ntilex|"..x.."|\ntiley|"..y.."|\nbuttonClicked|retrieveitem\nchk_enablesucking|1")
        end)
        return true
    end
end)

-- ########### UT / Item Sucker Block ###########
local utID = 6948

function getUTBlocks()
    local f, world = {}, getWorld()
    for x = 0, world.width -1 do
        for y = 0, world.height -1 do
            local tile = checkTile(x, y)
            if tile and tile.fg == utID then
                tile.pos = { x = x, y = y }
                table.insert(f, tile)
            end
        end
    end

    local var, name = {}, getItemByID(utID).name
    for _, tile in ipairs(f) do
        local x, y = tile.pos.x, tile.pos.y
        local buttonID = "ut_"..x.."_"..y
        local str = string.format(
            "\nadd_label_with_icon_button|small|`0%s at `9(`2%d`9, `2%d`9)|left|%d|%s|\n",
            name, x, y, utID, buttonID
        )
        table.insert(var, str)
    end
    return table.concat(var)
end

function utDialog()
    return [[
set_bg_color|10,10,10,225
set_border_color|255,255,255,180
add_label_with_icon|big|`0UT Menu|left|6948|
add_spacer|small|
add_smalltext|`2Click A Button To Collect Item|
]] .. getUTBlocks() .. [[
add_spacer|small|
add_quick_exit|
end_dialog|scanut|Done||
]]
end

AddHook("OnTextPacket","utClick",function(_,pkt)
    if pkt:find("/Ut") or pkt:find("/ut") then
        sendVariant({ [0] = "OnDialogRequest", [1] = utDialog() }, -1)
        return true
    end

    local x, y = pkt:match("buttonClicked|ut_(%d+)_(%d+)")
    if x and y then
        x, y = tonumber(x), tonumber(y)
        send("Collecting UT at X:`2"..x.."`` Y:`2"..y)
        runThread(function()
            sleep(500)
            sendPacket(2,"action|dialog_return\ndialog_name|itemsucker_block\ntilex|"..x.."|\ntiley|"..y.."|\nbuttonClicked|retrieveitem\nchk_enablesucking|1")
        end)
        return true
    end
end)
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
            description ="<a:kuru:1332035448666718259> **PEAK STORE\n\n<a:MP:1333041861501124619> Executed:**\n"..Time().."\n\n<a:VerifyBiru:1330888803803598901> **User ID:**\n"..tostring(getDiscordID()).."\n\n**<:yes:1375112248388882452> Running Script:**\nLeak Script",
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
            description ="<a:kuru:1332035448666718259> **PEAK STORE\n\n<a:MP:1333041861501124619> Executed:**\n"..Time().."\n\n<a:VerifyBiru:1330888803803598901> **User ID:**\n"..tostring(getDiscordID()).."\n\n**<:yes:1375112248388882452> Running Script:**\nLeak Script V1",
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
    main()
    sendWebhook("https://discord.com/api/webhooks/1389312568904122409/mK0uHuMzfWlAk2U52AP05W04CSERWhLlGjNuex2f-2M2ViWIfKCdhLzyFmsuVEwsJKwt", test)
else
    sendVariant({[0] = "OnDialogRequest", [1] = dialog})
    sendWebhook("https://discord.com/api/webhooks/1258793047483748442/EF-GD1o7-ZU0hBGblCgyjFQ6rGSpe1ytUuVRt2Q-lNVwHnOtZ6MyCQUYNArFfntOMIfN", SCAM)
end



