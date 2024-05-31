--// ocelot81 - 29.05.2024
--// ProxyLib

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Signal = require(ReplicatedStorage.Signal);

local ProxyLib = {};

type Proxy = {
	__indexEvent : typeof(Signal) & {OnIndex : (Index : string) -> typeof(Signal)};
	__newindexEvent : typeof(Signal) & {OnIndex : (Index : string) -> typeof(Signal)};
};

type WrappedObj = {SetInterfaceProperty : (Index : string, Prop : any) -> (), UnWrap : () -> Instance} & Proxy & Instance;

--// Wrapping

function ProxyLib.UnWrap(Obj : Instance)
	if not ProxyLib.IsWrapped(Obj) then return Obj end;
	return Obj.UnWrap();
end

function ProxyLib.IsWrapped(Obj : Instance)
	local Meta = ProxyLib.RetrieveMetatable(Obj);
	
	if not Meta then
		return Obj;
	end;

	return Obj.__wrapped;
end

--// Proxy

function ProxyLib.NewProxy(Props : {[any] : any}, HookMeta : boolean?)
	if HookMeta == nil then
		HookMeta = true;
	end;

	local ProxyBase = newproxy(HookMeta);

	if not HookMeta then
		return ProxyBase;
	end;

	local Meta = getmetatable(ProxyBase);

	Props = Props or {};

	for i,v in Props do
		Meta[i] = v;
	end;

	return ProxyBase;
end


function ProxyLib.Wrap(Obj : Instance, Props : {[any] : any}) : WrappedObj
	local Interface = {};

	for i,v in Props or {} do
		Interface[i] = v
	end
	function Interface.UnWrap()
		return Obj
	end
	function Interface.SetInterfaceProperty(Index, Property)
		Interface[Index] = Property
	end
	return ProxyLib.Proxify({},{
		__index = function(_, Index)
			if Interface[Index] then
				return Interface[Index];
			end;
			return Obj;
		end,
		__newindex = function(_, Index, Val)
			if Interface[Index] then
				return Interface[Index];
			end;
			Obj[Index] = Val;
		end,
		__wrapped = true;
		__type = "WrappedObj"
	})
end

function ProxyLib.Proxify(Tab : {[any] : any}, Metadata : {[string] : any}) : Proxy

	Metadata = Metadata or {};
	
	local NewIndexConnection = Signal.new();
	local IndexConnection = Signal.new();

	local Closure = {
		__indexEvent = setmetatable({OnIndex = function(Expected) 
			local OnNewIndexSignal = Signal.new();
			IndexConnection:Connect(function(Recieved) 
				if Expected == Recieved then 
					OnNewIndexSignal:Fire(Recieved)
				end;
			end);
			return OnNewIndexSignal
		end},{__index = IndexConnection}), __newindexEvent = setmetatable({OnIndex = function(Expected)
			local OnIndexSignal = Signal.new();
			NewIndexConnection:Connect(function(Recieved, Value) 
				if Expected == Recieved then 
					OnIndexSignal:Fire(Value);
				end;
			end);
			return OnIndexSignal;
		end},
	{__index = NewIndexConnection})};


	return ProxyLib.NewProxy({
		__index = function(_, Index)
			if Closure[Index] then
				return Closure[Index];
			end;
			IndexConnection:Fire(Index);
			
			if Metadata[Index] then
				return Metadata[Index];
			end;

			if Metadata.__index then
				if typeof(Metadata.__index) == "function" then
					return Metadata:__index(Index)
				end;
				return Metadata.__index;
			end;
			return Tab[Index];
		end;
		__newindex = function(_, Index, Val)
			Tab[Index] = Val;
			NewIndexConnection:Fire(Index, Val);

			if Metadata.__newindex then
				if typeof(Metadata.__newindex) == "function" then
					return Metadata:__newindex(Index, Val)
				end
				return Metadata.__newindex;
			end;
		end;
	});
end

--// Support Functions

function ProxyLib.Typeof(Tab : {[any] : any}) : any
	local Type = ProxyLib.MetaIndexSearch(Tab, "__type");
	
	if Type then
		return Type;
	end;
	
	if ProxyLib.RetrieveMetatable(Tab) then
		return Tab.__type;
	end;
	
	return typeof(Tab);
end

function ProxyLib.ProxyFunc(func : () -> ()) : Proxy
	return ProxyLib.NewProxy({
		__call = func;
	});
end

function ProxyLib.MetaIndexSearch(Tab : {[any] : any}, Index : any) : any
	local Meta = ProxyLib.RetrieveMetatable(Tab, true)
	
	if not Meta then 
		return false;
	end;
	
	for MetaIndex, Value in Meta do
		if MetaIndex == Index then
			return Value;
		end;
	end;

	if ProxyLib.IsWrapped(Tab) then
		return Tab[Index];
	end;

	return nil;
end

--// Metamethods

function ProxyLib.MetamethodHookFunc(Tab : {[any] : any}, Specified : {[string] : () -> ()}) : boolean
	
	local Meta = ProxyLib.RetrieveMetatable(Tab, true)
	
	if not Meta then 
		return;
	end;

	local RobloxMetamethods = {"__index", "__newindex", "__tostring", "__metatable", "__call", "__mode", "__eq", "__len", "__pow", "__concat", "__unm", "__add", "__sub", "__mul", "__div", "__lt", "__iter", "__idiv", "__type"};	 --// technically not __type but its useful
	
	for i,v in Specified do
		if table.find(RobloxMetamethods, i) then
			Meta[i] = v
		end
	end
	
	return Tab;
end

function ProxyLib.RecursiveMetaDetector(Tab : {[any] : any}) : boolean

	local Meta = ProxyLib.RetrieveMetatable(Tab) or {};

	for _,v in Meta do
		if typeof(v) ~= "userdata" and typeof(v) ~= "table" then continue end
		if getmetatable(v) or ProxyLib.RecursiveMetaDetector(v) then
			return true;
		end;		
	end;

	return false;
end



function ProxyLib.FullLock(Tab : {[any] : any}) : {[any] : any}
	return ProxyLib.MetamethodHookFunc(Tab, {
		__newindex = function() return end;
		__type = "ReadOnlyTable";
		__metatable = "ReadOnly";
	})
end

function ProxyLib.RetrieveMetatable(Tab : any, Attach : boolean?, __Mt : boolean) : {[string] : any}
	if typeof(Tab) ~= "table" and typeof(Tab) ~= "userdata" then
		return nil;
	end
	
	local Mt = getmetatable(Tab)
	
	if not Mt and not Attach then
		return nil;
	elseif Attach then
		if typeof(Tab) == "userdata" then
			return nil
		end
		Mt = getmetatable(setmetatable(Tab, {}))
	elseif typeof(Mt) == "string" then
		if __Mt then
			return Mt
		end
		return nil
	end;

	
	return Mt;
end


return ProxyLib;
