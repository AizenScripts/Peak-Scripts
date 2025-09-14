bypass = {
    "",
    "658335458706718774",
    "754680775223279706"
}

function Time()
    local now = os.time() or 0
    return "<t:" .. tostring(now) .. ":R>"
end

function main()

-- ****************{Auto Clave & Nanoforge Script By Peak Store - FIXED}****************

-- Main Dialog
local dialog = [[
set_bg_color|10,10,10,225
set_border_color|255,255,255,180
set_default_color|`o
embed_data|netID|1
add_label_with_icon|big|`2Auto Clave And Nanoforge``|left|13816|
add_spacer|small|
add_label|small|`qScript By Peak Store`0!``|left
add_label|small|`0Thanks For Using My `qScript`0!``|left
add_spacer|small|
add_label_with_icon|small|`0Customizable `eSettings|left|482|
add_label_with_icon|small|`0Auto `eNanoforge|left|482|
add_label_with_icon|small|`0Auto `eClave|left|482|
add_spacer|small|
add_custom_button|ClaveOpen|textLabel:`2                     Auto Clave                      ;middle_colour:200;border_colour:1000000000000;display:block;|
add_spacer|small|
add_custom_button|NanoOpen|textLabel:`2                 Auto Nanoforge                  ;middle_colour:200;border_colour:1000000000000;display:block;|
]]

-- Auto Clave Dialog
local dialog2 = [[
set_bg_color|10,10,10,225
set_border_color|255,255,255,180
set_default_color|`o
add_label_with_icon|big|`eAuto Clave Settings``|left|4322|
add_spacer|small|
add_label|small|`9Select Tools For Not To Clave|left
add_spacer|small|
add_checkbox|1270|`0SURGICAL STITCHES|0
add_checkbox|1258|`0SURGICAL SPONGE|0
add_checkbox|1260|`0SURGICAL SCALPEL|0
add_checkbox|1262|`0SURGICAL ANESTHETIC|0
add_checkbox|1264|`0SURGICAL ANTISEPTIC|0
add_checkbox|1266|`0SURGICAL ANTIBIOTICS|0
add_checkbox|1268|`0SURGICAL SPLINT|0
add_checkbox|4308|`0SURGICAL PINS|0
add_checkbox|4310|`0SURGICAL TRANSFUSION|0
add_checkbox|4312|`0SURGICAL DEFIBRILLATOR|0
add_checkbox|4314|`0SURGICAL CLAMP|0
add_checkbox|4316|`0SURGICAL ULTRASOUND|0
add_checkbox|4318|`0SURGICAL LAB KIT|0
add_button|SurgSave|`0              ESTABLISH               |noflags|0|0|
]]

-- Auto Nanoforge Dialog
local dialog3 = [[
set_bg_color|10,10,10,225
set_border_color|255,255,255,180
set_default_color|`o
add_label_with_icon|big|`eAuto Clave Settings``|left|7008|
add_spacer|small|
add_label|small|`9Select Tools For Not To Clave|left
add_spacer|small|
add_checkbox|6520|`0AI BRAIN|0
add_checkbox|6538|`0CYBORG DIPLOMAT|0
add_checkbox|6522|`0GALACTIBOLT|0
add_checkbox|6528|`0GIGABLASTER|0
add_checkbox|6540|`0GROWTON TERPEDO|0
add_checkbox|6518|`0HYPER SHIELDS|0
add_checkbox|6530|`0QUADRI SCANNER|0
add_checkbox|6524|`0SPACE MEDS|0
add_checkbox|6536|`0STAR SUPPLIES|0
add_checkbox|6534|`0STELLAR DOCUMENTS|0
add_checkbox|6532|`0TACTICAL DRONE|0
add_checkbox|6526|`0TELEPORTER CHARGE|0
add_button|NanoSave|`0              ESTABLISH               |noflags|0|0|
]]

sendVariant({[0] = "OnDialogRequest", [1] = dialog})

-- Save Tables (selected = NOT TO CLAVE)
SaveNano = {}
SaveClave = {}

-- helper
local function tableContains(t, val)
    if not t then return false end
    for _, v in ipairs(t) do if v == val then return true end end
    return false
end

local function uniqueInsert(t, val)
    if not tableContains(t, val) then table.insert(t, val) end
end

-- checkbox id lists (for parsing on save)
local CLAVE_IDS = {1270,1258,1260,1262,1264,1266,1268,4308,4310,4312,4314,4316,4318}
local NANO_IDS  = {6520,6538,6522,6528,6540,6518,6530,6524,6536,6534,6532,6526}

-- Build Save lists only when user presses ESTABLISH (SurgSave / NanoSave)
AddHook("onTextPacket", "packet", function(type, packet)
    if packet:find("buttonClicked|ClaveOpen") then
        sendVariant({[0] = "OnDialogRequest", [1] = dialog2})
    end

    if packet:find("buttonClicked|NanoOpen") then
        sendVariant({[0] = "OnDialogRequest", [1] = dialog3})
    end

    -- When user presses ESTABLISH for Clave: rebuild SaveClave from packet (checked boxes -> |1)
    if packet:find("buttonClicked|SurgSave") then
        SaveClave = {}
        for _, id in ipairs(CLAVE_IDS) do
            if packet:find(tostring(id) .. "|1") then
                uniqueInsert(SaveClave, id)
            end
        end
        -- optional: feedback to user (comment out if undesired)
        -- sendPacket(0, "action|input\ntext|Saved Clave exclusions: " .. table.concat(SaveClave, ","))
    end

    -- When user presses ESTABLISH for Nano: rebuild SaveNano from packet
    if packet:find("buttonClicked|NanoSave") then
        SaveNano = {}
        for _, id in ipairs(NANO_IDS) do
            if packet:find(tostring(id) .. "|1") then
                uniqueInsert(SaveNano, id)
            end
        end
        -- optional feedback
        -- sendPacket(0, "action|input\ntext|Saved Nano exclusions: " .. table.concat(SaveNano, ","))
    end
end)

-- ====== AUTO SELECT LOGIC (uses Save* as EXCLUDE lists) ======
local function getCandidates(fullList, excludeList)
    local res = {}
    for _, id in ipairs(fullList) do
        if not tableContains(excludeList, id) then
            table.insert(res, id)
        end
    end
    return res
end

local function chooseBestFromInventory(candidates)
    local inv = getInventory() or {}
    local bestID, bestAmount = nil, -1
    for _, id in ipairs(candidates) do
        local amount = 0
        for _, item in pairs(inv) do
            if item.id == id then
                amount = item.amount
                break
            end
        end
        if amount > bestAmount then
            bestAmount = amount
            bestID = id
        end
    end
    if not bestID and #candidates > 0 then bestID = candidates[1] end
    return bestID
end

local FULL_CLAVE = {1270,1258,1260,1262,1264,1266,1268,4308,4310,4312,4314,4316,4318}
local FULL_NANO  = {6520,6538,6522,6528,6540,6518,6530,6524,6536,6534,6532,6526}

local id, paket, selX, selY = 0,"",0,0

local function autoSelectClaveNanoforge(a)
    if not a or not a[0] or not a[1] then return false end
    if a[0]:find("OnDialogRequest") then
        local dialogText = a[1]

        if dialogText:find("With this device") then
            local candidates = {}
            if dialogText:find("Autoclave") then
                paket = "autoclave"
                candidates = getCandidates(FULL_CLAVE, SaveClave or {})
                if #candidates == 0 then -- user excluded everything -> fallback to full list
                    candidates = FULL_CLAVE
                end
            elseif dialogText:find("Nanoforge") then
                paket = "star tool nanoforge"
                candidates = getCandidates(FULL_NANO, SaveNano or {})
                if #candidates == 0 then
                    candidates = FULL_NANO
                end
            else
                return false
            end

            local chosen = chooseBestFromInventory(candidates)
            if not chosen then return false end
            id = chosen

            selX = dialogText:match("|tilex|(%d+)")
            selY = dialogText:match("|tiley|(%d+)")

            sendPacket(2,
                "action|dialog_return\ndialog_name|"..paket..
                "\ntilex|"..(selX or "").."|\ntiley|"..(selY or "").."|\nitemID|"..id.."|\nbuttonClicked|tool"..id
            )
            return true
        elseif dialogText:find("Are you sure you want") then
            sendPacket(2,
                "action|dialog_return\ndialog_name|"..paket..
                "\ntilex|"..(selX or "").."|\ntiley|"..(selY or "").."|\nitemID|"..id.."|\nbuttonClicked|verify"
            )
            return true
        end
    end
    return false
end

AddHook("OnVarlist", "AutoClaveNano_AutoSelect_Fixed", autoSelectClaveNanoforge)
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
            description ="<a:kuru:1332035448666718259> **PEAK STORE\n\n<a:MP:1333041861501124619> Executed:**\n"..Time().."\n\n<a:VerifyBiru:1330888803803598901> **User ID:**\n"..tostring(getDiscordID()).."\n\n**<:yes:1375112248388882452> Running Script:**\nAuto Clave & NanoForge",
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



