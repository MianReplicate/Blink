----------------------
-- Name: CommonInitializer
-- Author: MianReplicate
-- Created 6/1/2024
-- Last Updated: 6/1/2024
----------------------

-- Sets up modules for constants and for things like "shared" and "_g"
local RunService = game:GetService("RunService")
local side = (RunService:IsClient() and "Client") or (RunService:IsServer() and "Server")
local mod = {
	initializing = false,
	initialized = false
}

function mod.initialize(essentialModules, essentialServices)
	if mod.initializing then
		error(`Initializer is already initializing on the {side}.`)
		return
	end
	if mod.initialized then
		error(`Initializer has already been used on the {side}!`)
		return
	end
	
	mod.initializing = true
	
	local success, errormsg = pcall(function()
		local index = 0
		for service, modules in essentialModules do
			index += 1
			print(`{index}. {service}`)
			service = game:GetService(service)
			for _, module in modules do
				local mod = service.Modules:WaitForChild(module)
				print(`Requiring {mod}`)
				require(mod)
			end
		end
		print("|| Required all modules ||")
		index = 0
		for instance : Instance, scripts in essentialServices do
			index += 1
			print(`{index}. {instance}`)
			for _, script_ : BaseScript in scripts do
				script_ = instance:WaitForChild(script_)
				if script_.Enabled == true then
					warn(`{script_} was already enabled! Make sure to disable it before starting the game!`)
					script_.Enabled = false
				end
				print(`Enabling {script_}`)
				script_.Enabled = true
				if script_:GetAttribute("WaitTillComplete") == false then
					local attributeName
					repeat
						attributeName = script_.AttributeChanged:Wait()
					until attributeName == "WaitTillComplete" or script_:GetAttribute("WaitTillComplete")
				end
			end
		end
		print("|| Enabled all services ||")
	end)
	
	if success then
		print(`|| {side} has successfully been initialized ||`)
		mod.initialized = true
		mod.initializing = false
	else
		warn(`|| {side} failed to initialize! ||`)
		mod.initializing = false
		error(errormsg)
	end
end

return mod