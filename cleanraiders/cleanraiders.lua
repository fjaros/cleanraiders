
cleanraidersDB = {}
LastPage = ""

local VERSION = "v1"
local MaxRows = 6
local MaxColumns = 9 -- All raid marks & unmarked
local IconTranslations = {
	"Skull",
	"X",
	"Square",
	"Moon",
	"Triangle",
	"Diamond",
	"Circle",
	"Star",
	"Unmarked"
}
local IconSendTags = {
	["Skull"] = "{skull}",
	["X"] = "{cross}",
	["Square"] = "{square}",
	["Moon"] = "{moon}",
	["Triangle"] = "{triangle}",
	["Diamond"] = "{diamond}",
	["Circle"] = "{circle}",
	["Star"] = "{star}",
	["Unmarked"] = "Unmarked"
}
local Icons = {}
local SendBoxes = {}
local RoleBoxes = {}
local MobBoxes = {}
local NameBoxes = {}
local SyncButton

local cleanraiders = LibStub("AceAddon-3.0"):NewAddon("cleanraiders", "AceComm-3.0", "AceEvent-3.0", "AceSerializer-3.0")
local libCompress = LibStub("LibCompress")
local libCompressET = libCompress:GetAddonEncodeTable()
local AceGUI = LibStub("AceGUI-3.0")

-- Common functions
local function strSplit(str, sep)
   local sep, fields = sep, {}
   local pattern = string.format("([^%s]+)", sep)
   str:gsub(pattern, function(c) fields[#fields + 1] = c end)
   return fields
end

local function strStartswith(str, token)
	return str:sub(1, token:len()) == token
end

local function strTrim(str)
   local n = str:find"%S"
   return n and str:match(".*%S", n) or ""
end

local function strLenSplit(str)
	local tmp, ret = "", {}
	local splt = strSplit(str, " ")
	for _, s in pairs(splt) do
		if tmp:len() + s:len() + 1 < 230 then
			tmp = tmp .. " " .. s
		else
			table.insert(ret, tmp)
			tmp = ""
		end
	end
	if tmp ~= "" then
		table.insert(ret, tmp)
	end
	return ret
end

local function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a, b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

-- Read DB
local function getSelectedPage()
	local splt = strSplit(LastPage, "\001")
	if not splt[3] then
		return nil
	end
	
	return cleanraidersDB[splt[1]][tonumber(splt[2])][tonumber(splt[3])]
end

local function setSelectedPage(value)
	local splt = strSplit(LastPage, "\001")
	if not splt[3] then
		return
	end
	
	cleanraidersDB[splt[1]][tonumber(splt[2])][tonumber(splt[3])] = value
end

-- Tree Group generation/population
local function generateTree()
	local tree = {}

	for dt, raidWings in spairs(cleanraidersDB, function(tbl, k1, k2) return k1 > k2 end) do
		local dateItem = {
			value = dt,
			text = dt,
			children = {}
		}
		
		for raidWingIndex, raid in pairs(raidWings) do
			local raidWing = {
				value = raidWingIndex,
				text = raid[1],
				children = {}
			}
			
			for mobIndex, mob in pairs(raidWings[raidWingIndex]) do
				if mobIndex > 1 then	
					local mobItem = {
						value = mobIndex,
						text = mob[1][1]
					}
					
					table.insert(raidWing["children"], mobItem)
				end
			end
			
			table.insert(dateItem["children"], raidWing)
		end
		
		table.insert(tree, dateItem)
	end
	
	return tree
end

local function populatePage(values)
	local row = 1
	local lastKey
	for key = 1, #values do
		lastKey = key
		local value = values[key]
		if key == 1 then
			-- beginning key, ignore mob name but keep raid marker labels
			for i = 1, MaxColumns do
				if value[i + 1] and value[i + 1]:upper() ~= IconTranslations[i]:upper() then
					Icons[i]:SetLabel(value[i + 1])
				end
			end
		else
			local titleUpper
			if value[1] then
				titleUpper = value[1]:upper()
			else
				titleUpper = ""
			end
			if strStartswith(titleUpper, "--") then
				-- ignore comment
			elseif strStartswith(titleUpper, "TACTICS") then
				TacticsBox.row = key
				TacticsBox.col = 2
				TacticsBox:SetText(value[2] or "")
			elseif strStartswith(titleUpper, "MOB") then
				for col = 1, MaxColumns do
					MobBoxes[col].row = key
					MobBoxes[col].col = col + 1
					if value[col + 1] then
						MobBoxes[col]:SetText(value[col + 1])
					end
				end
			else
				RoleBoxes[row]:SetText(value[1])
				for col = 1, MaxColumns do
					NameBoxes[row][col].row = key
					NameBoxes[row][col].col = col + 1
					if value[col + 1] then
						NameBoxes[row][col]:SetText(value[col + 1])
					end
				end
				row = row + 1
			end
		end
	end
	
	for nextRow = row, MaxRows do
		lastKey = lastKey + 1
		for col = 1, MaxColumns do
			NameBoxes[nextRow][col].row = lastKey
			NameBoxes[nextRow][col].col = col + 1
		end
	end
end

local function cleanPage()
	for row = 1, MaxRows do
		RoleBoxes[row]:SetText("")
	end
	
	for col = 1, MaxColumns do
		Icons[col]:SetLabel("-")
		MobBoxes[col]:SetText("")
		for row = 1, MaxRows do
			NameBoxes[row][col]:SetText("")
		end
	end
	
	TacticsBox:SetText("")
end

function cleanraiders:setPage(page, force)
	if force == nil and LastPage == page then
		return
	end

	local tbl = strSplit(page, "\001")

	if tbl[3] then
		LastPage = page
		self.treeGroup:SelectByValue(page)
		cleanPage()
		populatePage(getSelectedPage())
	end
end

local function editBoxTextChanged(self, event, text)
	local splt = strSplit(LastPage, "\001")
	if not cleanraidersDB[splt[1]][tonumber(splt[2])][tonumber(splt[3])][self.row] then
		cleanraidersDB[splt[1]][tonumber(splt[2])][tonumber(splt[3])][self.row] = {}
	end
	cleanraidersDB[splt[1]][tonumber(splt[2])][tonumber(splt[3])][self.row][self.col] = text
end

local function canSendSync(player)
	local isLeader = UnitIsGroupLeader(player)
	local isAssistant = UnitIsGroupAssistant(player)
	return isLeader or (isAssistant and isAssistant ~= player)
end

local function sendMessage(message, tp)
	local message = strTrim(message)
	if message == nil or message == "" then
		return
	end
	
	local tp = tp
	if not tp then
		if IsInRaid() then
			tp = "RAID"
		else
			tp = "PARTY"
		end
	end

	for _, s in pairs(strLenSplit(message)) do
		SendChatMessage(s, tp)
	end
end

local function sendRaidWarning(message)
	if IsInRaid() and canSendSync(UnitName("player")) then
		sendMessage(message, "RAID_WARNING")
	end
end

local function sendRow(row)
	local role = RoleBoxes[row]:GetText()
	if role == "" then
		return
	end

	sendRaidWarning(role:upper() .. " ASSIGNMENTS IN RAID CHAT")
	for col = 1, MaxColumns do
		local text = NameBoxes[row][col]:GetText()
		if text ~= "" then
			local tag = IconSendTags[IconTranslations[col]]
			sendMessage(tag .. ": " .. text, "RAID")
		end
	end
end

local function sendColumn(col, event, to)
	local tag = IconSendTags[IconTranslations[col]]
	local mobText = MobBoxes[col]:GetText()
	if mobText ~= "" then
		sendRaidWarning(tag:upper() .. " ASSIGNMENTS IN RAID CHAT")
		local out = tag .. " (" .. mobText .. ")"
		sendMessage(out)
	end

	for row = 1, MaxRows do
		local text = NameBoxes[row][col]:GetText()
		if text ~= "" then
			local out = RoleBoxes[row]:GetText():upper() .. ": " .. text
			sendMessage(out)
		end
	end
end

local function ChatHook(self, event, msg, author, ...)
--[[
	local upperAuthor = author:upper()
	if strStartswith(msg:upper(), "!ROLE") then
		for row = 1, MaxRows do
			for col = 1, MaxColumns do
				local field = RoleBoxes[row][col]:GetText():upper()
				if field:match(upperAuthor) then
					sendColumn(i, "WHISPER", author)
				end
			end
		end
	end
]]
end

function cleanraiders:SendSync(page)
	if not canSendSync(UnitName("player")) then
		if IsInRaid() then
			self.f:SetStatusText("You must be a raid leader or assistant to send syncs.")
		else
			self.f:SetStatusText("You must be the party leader to send syncs.")
		end
		return
	end

	if not page then
		return
	end
	
	local splt = strSplit(page, "\001")
	if not splt[1] then
		return
	end
	
	local tp
	if IsInRaid() then
		tp = "RAID"
	else
		tp = "PARTY"
	end
	self.f:SetStatusText("Syncing to " .. tp:lower() .. "...")
	
	local dt = splt[1]
	local message = {
		key = page,
		dt = dt
	}
	if splt[2] then
		local raid = cleanraidersDB[dt][tonumber(splt[2])]
		message["raid"] = raid[1]
		if splt[3] then
			local encounter = raid[tonumber(splt[3])]
			message["encounter"] = encounter[1][1]
			message["value"] = encounter
		else
			message["value"] = raid
		end
	else
		message["value"] = cleanraidersDB[dt]
	end

	local messageSerialized = libCompressET:Encode(libCompress:Compress(self:Serialize(message)))
	self:SendCommMessage("cleanraidersS", messageSerialized, tp)
end

function cleanraiders:OnCommReceived(prefix, message, distribution, sender)
	if prefix == "cleanraidersS" then
		if not canSendSync(sender) or (distribution ~= "PARTY" and distribution ~= "RAID") then
			return
		end
		
		if UnitName("player") == sender then
			self.f:SetStatusText("Synced successfully!")
			return
		end
		
		local decoded = libCompressET:Decode(message)
		local decompressed, err = libCompress:Decompress(decoded)
		if not decompressed then
			print("Failed to decompress sync: " .. err)
			return
		end
		
		local didDeserialize, deserialized = self:Deserialize(decompressed)
		if not didDeserialize then
			print("Failed to deserialize sync: " .. deserialized)
			return
		end
		
		if not deserialized["key"] or not deserialized["dt"] then
			print("Failed to parse deserialized comm.")
			return
		end
		
		local splt = strSplit(deserialized["key"], "\001")
		local status = "[" .. date("%H:%M:%S") .."] Received sync from " .. sender .. ": " .. deserialized["dt"]
		
		if not cleanraidersDB[deserialized["dt"]] then
			cleanraidersDB[deserialized["dt"]] = {}
		end	
		if deserialized["raid"] then
			status = status .. "/" .. deserialized["raid"]
			if deserialized["encounter"] then
				status = status .. "/" .. deserialized["encounter"]
				-- refresh single encounter
				if not cleanraidersDB[deserialized["dt"]][tonumber(splt[2])] then
					cleanraidersDB[deserialized["dt"]][tonumber(splt[2])] = {
						[1] = deserialized["raid"]
					}
				end
				cleanraidersDB[deserialized["dt"]][tonumber(splt[2])][tonumber(splt[3])] = deserialized["value"]
			else
				-- refresh raid within date
				cleanraidersDB[deserialized["dt"]][tonumber(splt[2])] = deserialized["value"]
			end
		else
			-- refresh entire date
			cleanraidersDB[deserialized["dt"]] = deserialized["value"]
		end
		
		self.tree = generateTree()
		self.treeGroup:SetTree(self.tree)
		self.treeGroup:RefreshTree()
		
		self.f:SetStatusText(status)
		self:setPage(LastPage, true)
	end
end

function cleanraiders:OnEnable()
	-- Basic Frame setup, minimap icon, and tree group population
	self.f = AceGUI:Create("Frame")
	self.f:Hide()
	self.f:SetTitle("<clean> raiders")
	self.f:SetLayout("Flow")
	self.f:SetWidth(1280)
	self.f:SetHeight(420)
	_G["cleanraidersFrame"] = self.f.frame
	table.insert(UISpecialFrames, "cleanraidersFrame")
	
	local iconDataBroker = LibStub("LibDataBroker-1.1"):NewDataObject("minimapIcon", {
		type = "data source",
		text = "clean raiders",
		label = "clean raiders",
		icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",
		OnClick = function() 
			if self.f:IsVisible() then
				self.f:Hide()
			else
				self.f:Show()
			end
		end,
	    OnTooltipShow = function(tooltip)
			tooltip:SetText("clean raiders")
			tooltip:Show()
		end,
	})
	local minimapIcon = LibStub("LibDBIcon-1.0")
	minimapIcon:Register("minimapIcon", iconDataBroker, {hide = false})
	minimapIcon:Show()

	self.tree = generateTree()
	self.treeGroup = AceGUI:Create("TreeGroup")
	self.treeGroup:SetFullWidth(true)
	self.treeGroup:SetFullHeight(true)
	self.treeGroup:SetAutoAdjustHeight(false)
	self.treeGroup:SetTreeWidth(200)
	self.treeGroup:SetTree(self.tree)
	
	local selectedGroup
	local treeGroupDrowndownMenu = _G["cleanraidersDropdownMenu"]:New()
	treeGroupDrowndownMenu:AddItem("Sync", function() 
		self:SendSync(selectedGroup)
	end)
	treeGroupDrowndownMenu:AddItem("Delete", function()
		local splt = strSplit(selectedGroup, "\001")
		for key, value in pairs(self.tree) do
			if value["value"] == splt[1] then
				if splt[2] then
					if splt[3] then
						cleanraidersDB[splt[1]][tonumber(splt[2])][tonumber(splt[3])] = nil
						table.remove(value["children"][tonumber(splt[2])]["children"], tonumber(splt[3]) - 1)
					else
						cleanraidersDB[splt[1]][tonumber(splt[2])] = nil
						table.remove(value["children"], tonumber(splt[2]))
					end
				else
					cleanraidersDB[selectedGroup] = nil
					table.remove(self.tree, key)
				end
				break
			end
		end

		if LastPage:sub(1, selectedGroup:len()) == selectedGroup then
			LastPage = ""
			cleanPage()
		end
		self.treeGroup:RefreshTree()
	end)
	treeGroupDrowndownMenu:AddItem("Close")	
	
	self.treeGroup:SetCallback("OnClick", function(_, _, group)
		if GetMouseButtonClicked() == "RightButton" then
			selectedGroup = group
			treeGroupDrowndownMenu:Show()
		end
	end)
	
	self.treeGroup:SetCallback("OnGroupSelected", function(_, _, group)
		self:setPage(group)
	end)
	
	-- Encounter view setup
	-- Create icons
	for col = 1, MaxColumns do
		local icon = AceGUI:Create("Icon")
		icon:SetImageSize(24, 24)
		if col > 8 then
			icon:SetImage("Interface\\Icons\\INV_Misc_QuestionMark")
		else
			icon:SetImage("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. (9 - col))
		end
		icon:SetLabel("-")
		icon:SetCallback("OnClick", function() sendColumn(col) end)
		Icons[col] = icon
		self.treeGroup:AddChild(icon)
	end
	
	-- Create Roles label and mob editboxes
	local rolesLabel = AceGUI:Create("Label")
	rolesLabel:SetFont("Fonts\\FRIZQT__.ttf", 16)
	rolesLabel:SetText("Roles")
	self.treeGroup:AddChild(rolesLabel)

	for col = 1, MaxColumns do
		MobBoxes[col] = AceGUI:Create("EditBox")
		MobBoxes[col]:DisableButton(true)
		MobBoxes[col]:SetCallback("OnTextChanged", editBoxTextChanged)
		self.treeGroup:AddChild(MobBoxes[col])
	end
	
	-- For each name row, create a send button, a role box, and name boxes
	for row = 1, MaxRows do
		local sendButton = AceGUI:Create("Button")
		sendButton:SetText("Send")
		sendButton:SetCallback("OnClick", function() sendRow(row) end)
		SendBoxes[row] = sendButton
		self.treeGroup:AddChild(sendButton)
	
		local roleBox = AceGUI:Create("EditBox")
		roleBox:DisableButton(true)
		RoleBoxes[row] = roleBox
		self.treeGroup:AddChild(roleBox)
		
		NameBoxes[row] = {}
		for col = 1, MaxColumns do
			local nameBox = AceGUI:Create("EditBox")
			nameBox:DisableButton(true)
			nameBox:SetCallback("OnTextChanged", editBoxTextChanged)
			NameBoxes[row][col] = nameBox
			self.treeGroup:AddChild(nameBox)
		end
	end
	
	-- Create tactics send box and multibox
	TacticsSendBox = AceGUI:Create("Button")
	TacticsSendBox:SetText("Send")
	TacticsSendBox:SetCallback("OnClick", function()
		local text = TacticsBox:GetText()
		if text ~= "" then
			sendRaidWarning("TACTICS IN RAID CHAT")
			sendMessage(text)
		end
	end)
	self.treeGroup:AddChild(TacticsSendBox)

	TacticsBox = AceGUI:Create("MultiLineEditBox")
	TacticsBox:SetLabel("Tactics")
	TacticsBox:SetNumLines(5)
	TacticsBox:DisableButton(true)
	TacticsBox:SetCallback("OnTextChanged", editBoxTextChanged)
	self.treeGroup:AddChild(TacticsBox)
	
	-- Create sync button	
	SyncButton = AceGUI:Create("Button")
	SyncButton:SetWidth(100)
	SyncButton:SetText("Sync")
	SyncButton:SetCallback("OnClick", function() self:SendSync(LastPage) end)
	self.treeGroup:AddChild(SyncButton)
	
	-- Build GUI Layout
	AceGUI:RegisterLayout("EncounterLayout", function()
		if self.f.frame:GetWidth() < 747 then
			self.f:SetWidth(747)
		end
		if self.f.frame:GetHeight() < 420 then
			self.f:SetHeight(420)
		end
	
		SendBoxes[1]:ClearAllPoints()
		SendBoxes[1]:SetWidth(68)
		SendBoxes[1]:SetPoint("TOPLEFT", self.treeGroup.frame, "TOPLEFT", 204, -78)
		for row = 2, MaxRows do
			SendBoxes[row]:ClearAllPoints()
			SendBoxes[row]:SetWidth(SendBoxes[row - 1].frame:GetWidth())
			SendBoxes[row]:SetPoint("TOPLEFT", SendBoxes[row - 1].frame, "BOTTOMLEFT", 0, 0)
		end
		
		rolesLabel:ClearAllPoints()
		rolesLabel:SetWidth(self.treeGroup.frame:GetWidth() / 14)
		rolesLabel.label:SetJustifyH("CENTER")
		rolesLabel:SetPoint("BOTTOMLEFT", SendBoxes[1].frame, "TOPRIGHT", 0, 4)
		
		RoleBoxes[1]:ClearAllPoints()
		RoleBoxes[1]:SetWidth(rolesLabel.frame:GetWidth())
		RoleBoxes[1]:SetHeight(24)
		RoleBoxes[1]:SetPoint("LEFT", SendBoxes[1].frame, "RIGHT", 0, 1)
		for row = 2, MaxRows do
			RoleBoxes[row]:ClearAllPoints()
			RoleBoxes[row]:SetWidth(RoleBoxes[row - 1].frame:GetWidth())
			RoleBoxes[row]:SetHeight(RoleBoxes[row - 1].frame:GetHeight())
			RoleBoxes[row]:SetPoint("TOPLEFT", RoleBoxes[row - 1].frame, "BOTTOMLEFT", 0, 0)
		end

		Icons[1]:ClearAllPoints()
		Icons[1]:SetWidth((self.treeGroup.frame:GetWidth() - SendBoxes[1].frame:GetWidth() - RoleBoxes[1].frame:GetWidth() - 210) / MaxColumns)
		Icons[1]:SetPoint("BOTTOMLEFT", RoleBoxes[1].frame, "TOPRIGHT", 0, 24)
		for col = 2, MaxColumns do
			Icons[col]:ClearAllPoints()
			Icons[col]:SetWidth(Icons[col - 1].frame:GetWidth())
			Icons[col]:SetPoint("TOPLEFT", Icons[col - 1].frame, "TOPRIGHT", 0, 0)
		end
		
		MobBoxes[1]:ClearAllPoints()
		MobBoxes[1]:SetWidth(Icons[1].frame:GetWidth())
		MobBoxes[1]:SetHeight(24)
		MobBoxes[1]:SetPoint("TOPLEFT", Icons[1].frame, "BOTTOMLEFT", 0, 0)
		for col = 2, MaxColumns do
			MobBoxes[col]:ClearAllPoints()
			MobBoxes[col]:SetWidth(Icons[col].frame:GetWidth())
			MobBoxes[col]:SetHeight(MobBoxes[col - 1].frame:GetHeight())
			MobBoxes[col]:SetPoint("TOPLEFT", MobBoxes[col - 1].frame, "TOPRIGHT", 0, 0)
		end

		for row = 1, MaxRows do
			for col = 1, MaxColumns do
				NameBoxes[row][col]:ClearAllPoints()
				NameBoxes[row][col]:SetWidth(MobBoxes[col].frame:GetWidth())
				NameBoxes[row][col]:SetHeight(MobBoxes[col].frame:GetHeight())
				if row > 1 then
					NameBoxes[row][col]:SetPoint("TOPLEFT", NameBoxes[row - 1][col].frame, "BOTTOMLEFT", 0, 0)
				else
					NameBoxes[row][col]:SetPoint("TOPLEFT", MobBoxes[col].frame, "BOTTOMLEFT", 0, 0)
				end
			end
		end
		
		TacticsSendBox:ClearAllPoints()
		TacticsSendBox:SetWidth(SendBoxes[1].frame:GetWidth())
		TacticsSendBox:SetHeight(SendBoxes[1].frame:GetHeight())
		TacticsSendBox:SetPoint("TOPLEFT", SendBoxes[MaxRows].frame, "BOTTOMLEFT", 0, -40)
		
		TacticsBox:ClearAllPoints()
		TacticsBox:SetWidth(self.treeGroup.frame:GetWidth() - TacticsSendBox.frame:GetWidth() - 212)
		TacticsBox:SetPoint("LEFT", TacticsSendBox.frame, "RIGHT", 0, 0)
		
		SyncButton:ClearAllPoints()
		SyncButton:SetWidth(102)
		SyncButton:SetHeight(23)
		SyncButton:SetPoint("TOPRIGHT", TacticsBox.frame, "BOTTOMRIGHT", -1, 0)
	end)
	self.treeGroup:SetLayout("EncounterLayout")
	self.f:AddChild(self.treeGroup)

	self:setPage(LastPage, true)
	
	ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", ChatHook)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", ChatHook)

	self:RegisterComm("cleanraidersS")
end
