--// ocelot81 - 29.05.2024
--// ProxyLib

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Signal = require(ReplicatedStorage.Signal)

local ProxyLib = {};

type Proxy = {
	__indexEvent : typeof(Signal) & {OnIndex : (Index : string, Func : () -> ()) -> ()};
	__newindexEvent : typeof(Signal) & {OnIndex : (Index : string, Func : () -> ()) -> ()};
};

type WrappedObj = {UnWrap : () -> Instance} & Proxy & Instance;

--// Wrapping

function ProxyLib.Wrap(Obj : Instance, Props : {[any] : any}) : WrappedObj

	local Interface = {};

	for i,v in Props do
		Interface[i] = v
	end

	function Interface:UnWrap()
		return Obj
	end

	function Interface:SetInterfaceIndex(Index, Property)
		Interface[Index] = Property
	end

	return ProxyLib.NewProxy({
		__index = function(_, Index)
			if Interface[Index] then
				return Interface[Index]
			end
			return Obj
		end;

		__newindex = function(_, Index, Prop)
			Obj[Index] = Prop
		end;

		__type = "WrappedObj"; 
		__wrapped = true; 
	})

end

function ProxyLib.UnWrap(Obj : Instance)
	if not ProxyLib.Typeof(Obj, "__wrapped") then return Obj end;
	return Obj:UnWrap();
end

--// Proxy

function ProxyLib.NewProxy(Props : {[any] : any}, HookMeta : boolean?) : Proxy

	if HookMeta == nil then
		HookMeta = true;
	end;

	local ProxyBase = newproxy(HookMeta);

	if not HookMeta then
		return ProxyBase;
	end;

	local Meta = getmetatable(ProxyBase);

	local NewIndexConnection = Signal.New();
	local IndexConnection = Signal.New();

	Props = Props or {};

	for i,v in Props do
		Meta[i] = v;
	end;

	Props.__newindex = Props.__newindex or function(self, index, val) rawset(self, index, val) end;

	Meta.__index = function(self, index)
		IndexConnection:Fire(index);
		if Props.__index and typeof(Props.__index) == "function" then
			return Props.__index(self, index);
		end;
		return Props.__index
	end

	Meta.__newindex = function(self, index, val)
		NewIndexConnection:Fire(index);
		if Props.__newindex and typeof(Props.__newindex) == "function" then
			return Props.__newindex(self, index, val);
		end;
		return Props.__newindex
	end

	local Closure = setmetatable(
		{__indexEvent = setmetatable({OnIndex = function(Expected, Listener) 
			IndexConnection:Connect(function(Recieved) 
				if Expected == Recieved then 
					Listener(Recieved);
				end;
			end);
		end},{__index = IndexConnection}), __newindexEvent = setmetatable({OnIndex = function(Expected, Listener)
			NewIndexConnection:Connect(function(Recieved) 
				if Expected == Recieved then 
					Listener(Recieved);
				end;
			end);
		end},
		{__index = NewIndexConnection})}, Meta);		

	return Closure;
end

function ProxyLib.Proxify(Tab : {[any] : any}) : Proxy
	local Proxy = ProxyLib.NewProxy();
	for i,v in Tab do	
		rawset(Proxy, i, v);
	end;
	return Proxy;
end

--// Metamethods

function ProxyLib.MetamethodHookFunc(Tab : {[any] : any}, Specified : {string}, Func : () -> ()) : boolean
	local Base = getmetatable(Tab) or getmetatable(setmetatable(Tab, {}));

	if typeof(Base) == "string" then
		return;
	end;

	local RobloxMetamethods = {"__index", "__newindex", "__tostring", "__call", "__mode", "__eq", "__len", "__pow", "__concat", "__unm", "__add", "__sub", "__mul", "__div", "__lt", "__iter", "__idiv"};	

	for _,v in ipairs(Specified) do
		local Found = table.find(RobloxMetamethods, v)
		if Found then
			Base[RobloxMetamethods[Found]] = Func;
		end;
	end;

	return Tab;
end

function ProxyLib.RecursiveMetaDetector(Tab : {[any] : any}) : boolean
	
	local Meta = getmetatable(Tab);
	
	if not Meta or typeof(Meta) == "string" then
		return;
	end;

	for _,v in Meta do
		if typeof(v) ~= "userdata" and typeof(v) ~= "table" then continue end
		if getmetatable(v) or ProxyLib.RecursiveMetaDetector(v) then
			return true
		end			
	end

	return false
end

function ProxyLib.MetaIndexSearch(Tab : {[any] : any}, Index : any) : any

	local Meta = getmetatable(Tab) or getmetatable(setmetatable(Tab, {}));

	if typeof(Meta) == "string" then
		return;
	end;

	for MetaIndex, Value in Meta do
		if MetaIndex == Index then
			return Value;
		end;
	end;

	return nil;
end

--// Support Functions

function ProxyLib.Typeof(Tab : {[any] : any}) : any
	return ProxyLib.MetaIndexSearch(Tab, "__type");
end

function ProxyLib.ProxyFunc(func : () -> ()) : Proxy
	return ProxyLib.NewProxy({
		__call = func;
	});
end

return ProxyLib;
