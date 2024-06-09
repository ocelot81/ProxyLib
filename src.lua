--// ocelot81 - 29.05.2024
--// ProxyLib

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Signal = require(ReplicatedStorage.Modules.MockSignal);

local ProxyLib = {};

export type Proxy = {
	__indexEvent : typeof(Signal) & {OnIndex : (Index : string) -> typeof(Signal)};
	__newindexEvent : typeof(Signal) & {OnIndex : (Index : string) -> typeof(Signal), OnValue : (Value : any) -> typeof(Signal)};
	__DisconnectEventHandler : (self : Proxy) -> ();
};

export type WrappedObj = {SetInterfaceProperty : (Index : string, Property : any) -> (), UnWrap : () -> Instance} & Proxy & Instance;

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

function ProxyLib.Wrap(Obj : Instance, Properties : {[any] : any}?) : WrappedObj

	Properties = Properties or {};

	function Properties.UnWrap()
		return Obj;
	end;
	function Properties.SetInterfaceProperty(Index, Property)
		Properties[Index] = Property;
	end;
	return ProxyLib.Proxify({},{
		__index = function(_, Index)
			if Properties[Index] then
				return Properties[Index];
			end;
			return Obj;
		end,
		__newindex = function(_, Index, Val)
			if Properties[Index] then
				return Properties[Index];
			end;
			Obj[Index] = Val;
		end,
		__wrapped = true;
		__type = "WrappedObj";
	})
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


function ProxyLib.Proxify(Tab : {[any] : any}, Metadata : {[string] : any}?) : Proxy

	Metadata = Metadata or {};

	local NewIndexConnection = Signal.new();
	local IndexConnection = Signal.new();

	local Closure = {
		__indexEvent = setmetatable({OnIndex = function(Expected) 
			local OnIndexSignal = Signal.new();
			IndexConnection:Connect(function(Recieved) 
				if Expected == Recieved then 
					OnIndexSignal:Fire(Recieved);
				end;
			end);
			return OnIndexSignal;
		end},{__index = IndexConnection}), __newindexEvent = setmetatable({OnIndex = function(Expected)
			local OnNewIndexSignal = Signal.new();
			NewIndexConnection:Connect(function(Recieved, Value) 
				if Expected == Recieved then 
					OnNewIndexSignal:Fire(Value);
				end;
			end);
			return OnNewIndexSignal;
		end; OnValue = function(Expected) 
			local OnValueSignal = Signal.new();
			NewIndexConnection:Connect(function(Recieved, Value) 
				if Expected == Value then 
					OnValueSignal:Fire(Recieved);
				end;
			end);
			return OnValueSignal;	
		end},
	{__index = NewIndexConnection}), DisconnectEventHandler = function(self)
		setmetatable(self.__indexEvent, nil);
		self.__indexEvent = nil;  
		setmetatable(self.__newindexEvent, nil);
		self.__newindexEvent = nil;  
	end; __proxy = Tab;};

	local ExistingMeta = ProxyLib.RetrieveMetatable(Tab, true);

	local ProxyMeta = {
		__index = function(_, Index)
			if Closure[Index] then
				return Closure[Index];
			end;
			IndexConnection:Fire(Index);

			if Metadata.__index then
				if typeof(Metadata.__index) == "function" then
					return Metadata:__index(Index);
				end;
				return Metadata.__index;
			elseif ExistingMeta.__index then
				if typeof(ExistingMeta.__index) == "function" then
					return ExistingMeta:__index(Index);
				end;
				return ExistingMeta.__index;
			end;

			return Tab[Index];
		end;
		__newindex = function(_, Index, Val)
			NewIndexConnection:Fire(Index, Val);

			if Metadata.__newindex then
				if typeof(Metadata.__newindex) == "function" then
					return Metadata:__newindex(Index, Val);
				end;
				return Metadata.__newindex;
			elseif ExistingMeta.__newindex then
				if typeof(ExistingMeta.__newindex) == "function" then
					return ExistingMeta:__newindex(Index, Val);
				end;
				return ExistingMeta.__newindex;
			end;

			Tab[Index] = Val;
		end;
	};
	--// Metamethod overrides

	for Index, Metamethod in Metadata do
		if ProxyMeta[Index] then  --//__newindex and __index can be set in metadata but its handled internally
			continue;
		end;
		ProxyMeta[Index] = Metamethod;
	end;

	for Index, Metamethod in ExistingMeta do
		if ProxyMeta[Index] then
			continue;
		end;
		ProxyMeta[Index] = Metamethod;
	end;

	return ProxyLib.NewProxy(ProxyMeta);
end


function ProxyLib.Proxy() : Proxy
	return ProxyLib.Proxify({},{})
end

function ProxyLib.rawlen(Tab : any) : number
	return rawlen(Tab.__proxy)
end

function ProxyLib.rawget(Tab : any, Index : any) : any
	return rawget(Tab.__proxy, Index)
end

function ProxyLib.rawset(Tab : any, Index : any, Value : any) : any
	return rawset(Tab.__proxy, Index, Value)
end

function ProxyLib.DeProxify(Obj : any) : {[any] : any}
	if typeof(Obj) ~= "userdata" then
		return Obj;
	end;

	if not ProxyLib.RetrieveMetatable(Obj) then
		return {};
	end

	return Obj.__proxy
end

function ProxyLib.ProxyFunc(func : () -> ()) : any
	return ProxyLib.NewProxy({
		__call = func;
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

local RobloxMetamethods = {"__index", "__newindex", "__tostring", "__metatable", "__call", "__mode", "__eq", "__len", "__pow", "__concat", "__unm", "__add", "__sub", "__mul", "__div", "__lt", "__iter", "__idiv", "__type"}; --// technically not __type but its useful

function ProxyLib.FilterMetamethods(Tab : any) : any

	local Meta = ProxyLib.RetrieveMetatable(Tab);

	if not Meta then
		return Tab;
	end;

	for i,_ in Meta do
		if table.find(RobloxMetamethods, i) then
			continue;
		end;
		Meta[i] = nil;
	end

	return Tab
end

function ProxyLib.MetamethodHookFunc(Tab : {[any] : any}, Specified : {[string] : () -> ()}) : {[any] : any}

	local Meta = ProxyLib.RetrieveMetatable(Tab, true);

	if not Meta then 
		return;
	end;

	for i,v in Specified do
		if table.find(RobloxMetamethods, i) then
			Meta[i] = v;	
		end;
	end;

	return Tab;
end

function ProxyLib.FullLock(Tab : {[any] : any}) : {[any] : any}
	return ProxyLib.MetamethodHookFunc(Tab, {
		__newindex = function() return end;
		__type = "ReadOnlyTable";
		__metatable = "ReadOnly";
	})
end

function ProxyLib.ForceTypeNewindex(Tab : any, Type : string)
	return ProxyLib.MetamethodHookFunc(Tab, {
		__newindex = function(self, Index, Val) 
			if typeof(Index) ~= Type then
				return
			end
			rawset(self, Index, Val)
		end,
	});
end

function ProxyLib.ExtractMeta(Tab : any) : {[string] : any}
	local Meta = ProxyLib.RetrieveMetatable(Tab);

	if not Meta then
		return setmetatable(Meta, {});
	end;

	Tab = {};

	for i,v in Meta do
		Tab[i] = v;
	end;

	return Tab;
end

function ProxyLib.RetrieveMetatable(Tab : any, Attach : boolean?, __Mt : boolean?) : {[string] : any}
	if typeof(Tab) ~= "table" and typeof(Tab) ~= "userdata" then
		return nil;
	end

	local Mt = getmetatable(Tab);

	if not Mt and not Attach then
		return nil;
	elseif not Mt and Attach then
		if typeof(Tab) == "userdata" then
			return nil;
		end;
		Mt = getmetatable(setmetatable(Tab, {}))
	elseif typeof(Mt) == "string" then
		if __Mt then
			return Mt;
		end;
		return nil;
	end;

	return Mt;
end


return ProxyLib;
