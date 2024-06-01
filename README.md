## Library dedicated to Proxies/Roblox instance wrapping with extra support functions for metamethods

### ⚠️ DISCLAIMER: Not fully compatible with stravants signal, use https://github.com/8ch32bit/MockSignal or another custom RBXScriptSignal with this library

Current API:

	-- Proxies --
	ProxyLib.NewProxy(Methods : Table, HookMeta : boolean) -> Returns a plain userdata with supplied metamethods, returns a blank one if HookMeta is false/nil) 
	ProxyLib.Proxy() -> Blank proxified table (/w Event handling)
	ProxyLib.Proxify(Tab : Table, Metadata : Table?) -> Proxified table containing Tab
	ProxyLib.Deproxify(Obj : Userdata) -> Original table that was proxified (unless __metatable was filled in)
	-- Support --
	ProxyLib.Typeof(Tab : any) -> Returns the __type value or typeof(Tab) if not feasible
	ProxyLib.AttachEventHandler(Tab : Table) -> Returns the table with EventHandler closure (NewIndex & Index and their filter connections)
	ProxyLib.FullLock(Tab : Table) -> Returns the table in a version where its read only & secured
	-- Metamethods
	ProxyLib.MetamethodHookFunc(Tab : Table, Methods : Table | Userdata) -> Returns version of the tab where its metamethods are supplied in the Methods argument
	ProxyLib.ForceTypeNewindex(Tab : Table, Type : any) -> Returns version of Tab where adding new indexes will only work if theyre the supplied type (ie. string, number)
	ProxyLib.ExtractMeta(Tab : Table | Userdata) -> Returns a new table containing contents of given objects metatable
	ProxyLib.RetrieveMetatable(Obj : any, Attach : boolean?, __mt : boolean?) -> Returns given object's metatable, conditionally attaching it (arg 2) or conditionally returning __metatable field (arg 3)
	ProxyLib.MetaIndexSearch(Tab : Table | Userdata, Index : any) -> Returns the value of the metatable field in given Tab
	-- Wrapping --
	Proxylib.Wrap(Obj : Instance, Properties : Table?) -> Userdata wrapping the object and containing properties
	Proxylib.UnWrap(Obj : Userdata) -> Instance wrapped by the userdata
	ProxyLib.IsWrapped(Obj : any) -> Boolean representing if the object is a userdata wrapping an Instance


Use example:

![image](https://github.com/ocelot81/ProxyLib/assets/128096274/9e89aed0-7554-4150-957d-d46ec5cbff52)


