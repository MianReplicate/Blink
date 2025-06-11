local types = {}

export type ReplicatedData = {
	storageIdentifier : string,
	tag : string,
	object : any,
	storage : {[any]:any},
	objectMetadata : ObjectMetadata,
	version : number | nil,
}
export type ReplicatedDataRemoving = {
	tag : string,
	object : any,
	objectMetadata : ObjectMetadata
}
export type ValueChanged = {
	storageIdentifier : string,
	tag : string,
	object : any,
	key : any,
	value : any,
	version : number,
}
export type ObjectMetadata = {
	isInstance : boolean
}
export type ValueEdited = {
	tag : string,
	object : any,
	key : any,
	value : any,
}

types.stopListener = {}

-- Stop the listener being used
function types.stopListener:stop()
	if(not self.stopped) then
		self.stopped = true
		local i = table.find(self.listenerIn, self.listener)
		if(i) then
			table.remove(self.listenerIn, i)
		end
	end
end

function types.stopListener.new()
	local newListener = {}
	newListener["stop"] = types.stopListener.stop 
	
	newListener.listener = function() end :: Types.KeyListener | Types.OnSetListener
	newListener.listenerIn = {}
	newListener.stopped = false

	return newListener
end

export type StopListener = typeof(types.stopListener)
export type KeyListener = (oldValue : any, newValue : any) -> ()
export type OnSetListener = (key : any, oldValue : any, newValue : any) -> ()

return types