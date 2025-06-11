--[[
      ___           ___                                  ___           ___           ___     
     /\__\         /\__\                  _____         /\  \         /\__\         /\__\    
    /::|  |       /:/  /                 /::\  \       /::\  \       /:/ _/_       /:/ _/_   
   /:/:|  |      /:/  /                 /:/\:\  \     /:/\:\  \     /:/ /\  \     /:/ /\__\  
  /:/|:|  |__   /:/  /  ___            /:/ /::\__\   /:/ /::\  \   /:/ /::\  \   /:/ /:/ _/_ 
 /:/ |:| /\__\ /:/__/  /\__\          /:/_/:/\:|__| /:/_/:/\:\__\ /:/_/:/\:\__\ /:/_/:/ /\__\
 \/__|:|/:/  / \:\  \ /:/  /          \:\/:/ /:/  / \:\/:/  \/__/ \:\/:/ /:/  / \:\/:/ /:/  /
     |:/:/  /   \:\  /:/  /            \::/_/:/  /   \::/__/       \::/ /:/  /   \::/_/:/  / 
     |::/  /     \:\/:/  /              \:\/:/  /     \:\  \        \/_/:/  /     \:\/:/  /  
     |:/  /       \::/  /                \::/  /       \:\__\         /:/  /       \::/  /   
     |/__/         \/__/                  \/__/         \/__/         \/__/         \/__/    
     
Name: Zeta's Currency Base (ZC Base)
Description:
Module to handle currencies and transactions ingame.
Author: Zetalasis

Version: 0.1B (Callisto)
Creation Date: Thursday, March 28th, 2024
Last Updated: Saturday, June 1st, 2024
]]

local RunService = game:GetService("RunService")

local module = {}

function ServerRun()
	return RunService:IsServer()
end

function ClientRun()
	return RunService:IsClient()
end

function module.new(UserID : int, SaveToDataStore : boolean, _CurrencyType : string)
	--local ZCBaseInstance_PREMT = {}
	local ZCBaseInstance = {}
	--setmetatable(ZCBaseInstance, ZCBaseInstance_PREMT)

	-- INIT VARIABLES --
	ZCBaseInstance = {
		["UserID"]            = UserID,
		["DataStoresAllowed"] = SaveToDataStore,
		["Data"]              = {

		}
	}

	-- TRANSACTIONS
	function ZCBaseInstance:CreateTransactionInfo(
		CurrencyType : string
		,Supplier : string
		,Cost : int
		,Amount : int
		,ServiceOrGood)

		local TransactionInfo = {
			["CurrencyType"] = CurrencyType,
			["Supplier"]     = Supplier,
			["Cost"]         = Cost,
			["Amount"]       = Amount,
			["Good"]         = ServiceOrGood
		}

		return TransactionInfo
	end

	function ZCBaseInstance:AddTransaction(TransactionInfo)
		if not ServerRun() then warn("You cannot run AddTransaction on the client!") return -1 end
		if TransactionInfo["CurrencyType"] == nil then warn("TransactionInfo invalid!") return -1 end

		local CurrencyType = TransactionInfo["CurrencyType"]
		local Supplier = TransactionInfo["Supplier"]
		local Cost = TransactionInfo["Cost"]
		local Amount = TransactionInfo["Amount"]
		local Good = TransactionInfo["Good"]

		local Data = self["Data"]
		local CTInDataIndex = table.find(Data, CurrencyType)

		local TransactionData

		if CTInDataIndex ~= nil then
			if Data[CTInDataIndex + 1] == nil then
				table.insert(Data, {TransactionInfo})
				TransactionData = Data[CTInDataIndex+1]
			end

			if type(Data[CTInDataIndex+1]) == "table" then
				TransactionData = Data[CTInDataIndex+1]
				table.insert(TransactionData, TransactionInfo)
			end
		else
			self["Data"] = {["CurrencyType"] = CurrencyType, {TransactionInfo}}
			--table.insert(Data, {["CurrencyType"] = CurrencyType, {TransactionInfo}})
		end
	end

	function ZCBaseInstance:Set(Money : int, CurrencyType : string)
		if not ServerRun() then warn("You can't run this on the client!") return -1 end
	end

	return ZCBaseInstance
end

return module
