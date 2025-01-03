local frame = CreateFrame("Frame", "HardcoreDeathFMainFrame", UIParent)
frame:RegisterEvent("CHAT_MSG_CHANNEL")

-- Configuration for channel settings, stored in saved variables
HardcoreDeathFConfig = HardcoreDeathFConfig or {
    channels = {
        ["GUILD"] = { enabled = true },
        ["SAY"] = { enabled = false },
        ["YELL"] = { enabled = false },
        ["PARTY"] = { enabled = false },
        ["RAID"] = { enabled = false },
        ["INSTANCE_CHAT"] = { enabled = false },
        ["WHISPER"] = { enabled = true }, -- Changed to boolean as it's now auto-targeted
        ["CHANNEL"] = { enabled = true, target = "LookingForGroup" }
    },
    customMessage = {
        enabled = false,
        message = "F" -- Default to "F" when not enabled
    }
}

-- Safe table insert
local function SafeInsert(t, v)
    if t and type(t) == "table" then
        table.insert(t, v)
    end
end

-- Helper function to get current timestamp
local function GetTimestamp()
    local now = date("*t")
    return string.format("[%02d:%02d:%02d]", now.hour, now.min, now.sec)
end

local function LogToFile(message)
    if not HardcoreDeathNotesDB then
        HardcoreDeathNotesDB = {}
    end
    local timestamp = GetTimestamp()
    SafeInsert(HardcoreDeathNotesDB, timestamp .. " " .. message)
end

local function OnEvent(self, event, message, sender, _, channelName)
    if string.find(channelName, "HardcoreDeaths") then
        local playerName = message:match("%[(.*)%]")
        local mobName = message:match("by%s+(.-)%sin%s+") -- or drown, or fell
        local level = message:match("They were level (%d+)")
        -- print("Death found.")

        if playerName and level then
            local player = playerName:gsub("%s+", " "):trim()
            local formattedMessage
            if mobName then
                local mob = mobName:gsub("%s+", " "):trim()
                formattedMessage = string.format("%s died by %s at level %s", player, mob, level)
            else
                formattedMessage = string.format("%s", message)
            end
            
            -- LogToFile(formattedMessage)
            -- print("Death logged:", formattedMessage)

            -- Store this information for later use
            frame.deathInfo = {player = player, mob = mobName, level = level}
        end
    end
end

frame:SetScript("OnEvent", OnEvent)

-- Function to check if we should send the chat message with error handling
local function CheckSendMessage()
    if frame.deathInfo then
        local myGuildName = GetGuildInfo("player")
        local playerGuildName = GetGuildInfo(frame.deathInfo.player or "")
        local messageToSend = HardcoreDeathFConfig.customMessage.enabled and HardcoreDeathFConfig.customMessage.message or "F"

        for channel, config in pairs(HardcoreDeathFConfig.channels) do
            if config.enabled then
                local status, err = pcall(function()
                    if channel == "GUILD" and myGuildName and playerGuildName and myGuildName == playerGuildName then
                        SendChatMessage(messageToSend, channel)
                    elseif channel == "WHISPER" then
                        SendChatMessage(messageToSend, channel, nil, frame.deathInfo.player) -- Automatically whisper to the player who died
                    elseif channel == "CHANNEL" then
                        local channelID = GetChannelName(config.target)
                        if channelID > 0 then
                            SendChatMessage(messageToSend, channel, nil, channelID)
                        end
                    elseif channel ~= "GUILD" and (channel ~= "SAY" or not IsInInstance()) then
                        SendChatMessage(messageToSend, channel)
                    end
                end)
                if not status then
                    print("Error sending message to", channel, ":", err)
                end
            end
        end
        frame.deathInfo = nil -- Clear after sending to avoid repeating
    end
end

-- Listen for ANY key press
frame:SetScript("OnKeyDown", CheckSendMessage)

-- Helper function to trim whitespace
function string.trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- Make sure the frame captures keyboard input
frame:SetPropagateKeyboardInput(true)

-- GUI for configuration with a background and right-side positioning
local configFrame = CreateFrame("Frame", "HardcoreDeathFConfigFrame", UIParent, "BackdropTemplate")
configFrame:SetSize(300, 400)
configFrame:SetPoint("TOPRIGHT", -20, -300)
configFrame:Hide()

-- Apply backdrop settings
configFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", 
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", 
    tile = true, tileSize = 32, edgeSize = 32, 
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
configFrame:SetBackdropColor(0, 0, 0, 0.8) -- Darker background for better visibility

-- Title
local title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -10)
title:SetText("HardcoreDeathF Configuration")

-- Create checkboxes for each channel
local checkboxes = {}
local inputs = {}

-- Before the existing loop for channels
local yOffset = -50
local customMessageCheckbox = CreateFrame("CheckButton", "HardcoreDeathFCustomMessageCheckbox", configFrame, "UICheckButtonTemplate")
customMessageCheckbox:SetPoint("TOPLEFT", 20, yOffset)
customMessageCheckbox:SetWidth(24)
customMessageCheckbox:SetHeight(24)
customMessageCheckbox:SetChecked(HardcoreDeathFConfig.customMessage.enabled)
customMessageCheckbox:SetScript("OnClick", function(self)
    HardcoreDeathFConfig.customMessage.enabled = self:GetChecked()
    if inputs["CUSTOM_MESSAGE"] then
        if HardcoreDeathFConfig.customMessage.enabled then
            inputs["CUSTOM_MESSAGE"].input:Show()
        else
            inputs["CUSTOM_MESSAGE"].input:Hide()
        end
    end
end)

local customMessageLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
customMessageLabel:SetPoint("LEFT", customMessageCheckbox, "RIGHT", 5, 0)
customMessageLabel:SetText("Custom Message")

local customMessageInput = CreateFrame("EditBox", "HardcoreDeathFCustomMessageInput", configFrame, "InputBoxTemplate")
customMessageInput:SetPoint("TOPLEFT", customMessageLabel, "BOTTOMLEFT", 0, -5)
customMessageInput:SetSize(260, 20)  -- Changed from 60 to 20 for single line
customMessageInput:SetMaxLetters(200)
customMessageInput:SetText(HardcoreDeathFConfig.customMessage.message)
customMessageInput:SetScript("OnTextChanged", function(self)
    -- Do nothing until saved
end)
if not HardcoreDeathFConfig.customMessage.enabled then
    customMessageInput:Hide()
end

inputs["CUSTOM_MESSAGE"] = {input = customMessageInput}

yOffset = yOffset - 90 -- Adjust yOffset for the new elements

for channel, config in pairs(HardcoreDeathFConfig.channels) do
    local checkbox = CreateFrame("CheckButton", "HardcoreDeathFCheckbox_" .. channel, configFrame, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", 20, yOffset)
    checkbox:SetWidth(24)
    checkbox:SetHeight(24)
    checkbox:SetChecked(config.enabled)
    checkbox:SetScript("OnClick", function(self)
        HardcoreDeathFConfig.channels[channel].enabled = self:GetChecked()
    end)

    local label = configFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    label:SetText(channel)

    if channel == "CHANNEL" then
        local input = CreateFrame("EditBox", "HardcoreDeathFInput_" .. channel, configFrame, "InputBoxTemplate")
        input:SetPoint("LEFT", label, "RIGHT", 5, 0)
        input:SetSize(100, 20)
        input:SetText(config.target)
        input:SetScript("OnTextChanged", function(self)
            -- Do nothing until saved
        end)
        input:Hide() -- Initially hide the input
        
        local editButton = CreateFrame("Button", "HardcoreDeathFEdit_" .. channel, configFrame, "UIPanelButtonTemplate")
        editButton:SetPoint("LEFT", input, "RIGHT", 5, 0)
        editButton:SetSize(50, 20)
        editButton:SetText("Edit")
        editButton:SetScript("OnClick", function()
            input:Show()
            editButton:Hide()
            inputs[channel].currentLabel:Hide()  -- Use the correct reference
            input:SetText(HardcoreDeathFConfig.channels[channel].target)
        end)
        -- Display current channel target
        local currentChannelLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        currentChannelLabel:SetPoint("RIGHT", editButton, "LEFT", -5, 0)
        currentChannelLabel:SetText(config.target)
        currentChannelLabel:Show() -- Show the label by default

        inputs[channel] = {input = input, editButton = editButton, currentLabel = currentChannelLabel}
    end
    
    checkboxes[channel] = checkbox
    yOffset = yOffset - 30
end

local saveButton = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
saveButton:SetPoint("BOTTOM", 0, 15)
saveButton:SetSize(100, 25)
saveButton:SetText("Save")
saveButton:SetScript("OnClick", function()
    for channel, config in pairs(HardcoreDeathFConfig.channels) do
        if inputs[channel] then
            local input = inputs[channel].input
            if input:IsVisible() then
                HardcoreDeathFConfig.channels[channel].target = input:GetText()
            end
        end
    end
    -- Save custom message
    if inputs["CUSTOM_MESSAGE"] then
        HardcoreDeathFConfig.customMessage.message = inputs["CUSTOM_MESSAGE"].input:GetText()
    end
    print("Configuration saved!")
    configFrame:Hide()
    -- Optionally, you might want to reload the UI here or restart the addon to take effect
    -- ReloadUI()
end)

-- Close button
local closeButton = CreateFrame("Button", nil, configFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -2, -2)

SLASH_HARDCOREDEATHF1 = "/hdf"
SlashCmdList["HARDCOREDEATHF"] = function()
    configFrame:Show()
    if inputs["CHANNEL"] then
        inputs["CHANNEL"].input:ClearFocus()
    end
    if inputs["CUSTOM_MESSAGE"] then
        inputs["CUSTOM_MESSAGE"].input:ClearFocus()
    end
end