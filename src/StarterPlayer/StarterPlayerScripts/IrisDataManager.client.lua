local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local UserInputService = game:GetService("UserInputService")
local Iris = require(script.Parent:WaitForChild("Iris"))
local ClientDataCreator = require(script.Parent:WaitForChild("ClientDataCreator"))
local Util = require(Modules:WaitForChild("Util"))
local Types = require(Modules:WaitForChild("Types"))
local DataCommunication = require(Modules:WaitForChild("DataCommunication"))

local editing = {
	started = false,
	tag = nil,
	object = nil,
	key = nil,
	currentValue = nil,
	newValue = nil
}

local isVisible = false
local wasLockedInFirstPerson = false

local function crawlForTable(key : any, tble : {[any]:any})
	Iris.Tree({`{tostring(key)}`})
	for _key, value in tble do
		if(type(value) == 'table') then
			crawlForTable(_key, value)
		else
			Iris.Text({`{tostring(_key)}: {tostring(value)}`})
		end
	end
	Iris.End()
end

Iris.Init()
Iris:Connect(function()
	if(isVisible) then
		if(editing.tag and editing.object and editing.key and editing.currentValue ~= nil) then

			local editingWindow = Iris.Window({[Iris.Args.Window.Title]="Data Editor",[Iris.Args.Window.NoClose]=true},{size=Iris.State(Vector2.new(500, 250))})
			Iris.Text(`Tag: {editing.tag}`)
			Iris.Text(`Object: {tostring(editing.object)}`)
			Iris.Text(`Editing: {tostring(editing.key)}`)
			local originalType = type(editing.currentValue)
			local inputBox = Iris.InputText({"New Value"})
			local input = inputBox.state.text:get()
			
			if(not editing.started) then
				inputBox.state.text:set(tostring(editing.currentValue))
			end
			
			editing.started = true
			
			if(Iris.Button({"Confirm"}).clicked()) then
				local value
				
				if(input) then
					if(originalType == 'number') then value = tonumber(input) end
					if(originalType == 'string') then value = tostring(input) end
					if(originalType == 'boolean') then
						local stringToBool = {
							['true'] = true,
							['false'] = false
						}
						value = stringToBool[input:lower()]
					end
				end
				
				if(value ~= nil) then
					local valueEdited : Types.ValueEdited = {
						tag = editing.tag,
						object = editing.object,
						key = editing.key,
						value = value
					}
					--DataCommunication.packets.ValueEdited.send(valueEdited)
					Util.fireRemote("ValueEdited", valueEdited)
				end
				
				for key, _ in editing do
					editing[key] = nil
				end
				
				editing.started = false
			end
			
			if(Iris.Button({"Cancel"}).clicked()) then
				for key, _ in editing do
					editing[key] = nil
				end
				
				editing.started = false
			end
			
			Iris.End()
		end
		
		local window = Iris.Window({[Iris.Args.Window.Title]="Data Viewer: F6 to hide/open window; F7 to unlock/lock mouse",[Iris.Args.Window.NoClose]=true},{size=Iris.State(Vector2.new(500, 500))})
		local forgetInstanceNames = Iris.Checkbox({"Ignore Instance Names"}, {isChecked=Iris.State(false)})
		
		if(window.state.isOpened:get() and window.state.isUncollapsed:get()) then
			Iris.Text({"Now see, that's kinda cool, don't ya think?"})
			
			local storages = ClientDataCreator.getAllStorages()
			
			local storageTrees = {}
			local storageFoundUncollapsed = false
			
			for storageIdentifier, tagToObjectToDatas in storages do
				local storageTree = Iris.Tree({storageIdentifier})
				
				local tagTrees = {}
				local foundUncollapsed = false
				
				if(storageFoundUncollapsed) then
					storageTree.state.isUncollapsed:set(false)
				end

				if(storageTree.uncollapsed()) then
					storageFoundUncollapsed = storageTree
					for _, _storageTree in storageTrees do
						_storageTree.state.isUncollapsed:set(false)
					end
				end

				for tag, objectToData in tagToObjectToDatas do
					local tagTree = Iris.Tree({tag})

					if(foundUncollapsed) then
						tagTree.state.isUncollapsed:set(false)
					end

					if(tagTree.uncollapsed()) then
						foundUncollapsed = tagTree
						for _, _tagTree in tagTrees do
							_tagTree.state.isUncollapsed:set(false)
						end
					end

					local objectTrees = {}
					local objectFoundUncollapsed = false

					if(tagTree.state.isUncollapsed:get()) then
					for object, data : ClientDataCreator.Data in objectToData do
						local data : ClientDataCreator.Data = data

						if(not forgetInstanceNames.state.isChecked:get() and data:getObjectMetadata().isInstance) then
							object = ClientDataCreator.getInstanceFromUUID(object) or object
						end

						local objectTree = Iris.Tree({tostring(object)})

						if(objectFoundUncollapsed) then
							objectTree.state.isUncollapsed:set(false)
						end

						if(objectTree.uncollapsed()) then
							objectFoundUncollapsed = objectTree
							for _, _objectTree in objectTrees do
								_objectTree.state.isUncollapsed:set(false)
							end
						end

						if(objectTree.state.isUncollapsed:get()) then
						local metaTree = Iris.Tree({"Metadata"})
						do
							if(metaTree.state.isUncollapsed:get()) then
								Iris.Text({`Is Instance: {data:getObjectMetadata().isInstance}`})
								Iris.Text({`Version: {data:getVersion()}`})
								--do
								--	Iris.Tree({"Key Listeners"})
								--	for key, listeners in data.metadata.keyListeners do
								--		Iris.Text(`{tostring(key)}: {#listeners} listeners`)
								--	end
								--	Iris.End()
								--end

								--Iris.Text({"On Set Listeners: "..#data.metadata.onSetListeners})

								--Iris.Tree({"Key Sanity Checks"})
								--for key, listeners in data.metadata. do
								--	Iris.Text(`{tostring(key)}: {#listeners} listeners`)
								--end
								--Iris.End()
							end
						end
						Iris.End()

						local storageTree = Iris.Tree({"Storage"})
						do
							if(storageTree.state.isUncollapsed:get()) then
								for key, value in data.storage do
									if(not forgetInstanceNames.state.isChecked:get() and ClientDataCreator.isValidUUID(key)) then
										key = ClientDataCreator.getInstanceFromUUID(key) or key
									end
									if(not forgetInstanceNames.state.isChecked:get() and ClientDataCreator.isValidUUID(value)) then
										value = ClientDataCreator.getInstanceFromUUID(value) or value
									end
									local typeOf = type(value)
									if(storageIdentifier == 'default') then
										Iris.Text({`{tostring(key)}: {tostring(value)}`})
									elseif(typeOf == 'string' or typeOf == 'boolean' or typeOf == 'number') then
										if(Iris.Button({`({typeOf}) {tostring(key)}: {tostring(value)}`})).clicked() then
											editing.tag = tag
											editing.object = object
											editing.key = key
											editing.currentValue = value
										end
									elseif(typeOf == 'table') then
										crawlForTable(key, value)
									else
										Iris.Text({`{tostring(key)}: {tostring(value)}`})
									end
								end
							end
						end
						Iris.End()
						end
						Iris.End()
						table.insert(objectTrees, objectTree)
					end
					end
					Iris.End()
					table.insert(tagTrees, tagTree)
				end
				Iris.End()
				table.insert(storageTrees, storageTree)
			end
		end

		Iris.End()	
	end
end)

UserInputService.InputEnded:Connect(function(input: InputObject, gameProcessedEvent: boolean) 
	if(input.KeyCode == Enum.KeyCode.F6) then
		isVisible = not isVisible
	elseif(input.KeyCode == Enum.KeyCode.F7) then
		if(UserInputService.MouseBehavior == Enum.MouseBehavior.Default) then
			if(wasLockedInFirstPerson) then
				Players.LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
			end
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		else
			if(Players.LocalPlayer.CameraMode == Enum.CameraMode.LockFirstPerson) then
				Players.LocalPlayer.CameraMode = Enum.CameraMode.Classic
				wasLockedInFirstPerson = true
			end
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
	end
end)

Players.LocalPlayer.CharacterAdded:Connect(function()
	wasLockedInFirstPerson = false -- reset
end)