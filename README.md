## Library dedicated to Proxies/Metamethods & support for instance wrapping

### ⚠️ DISCLAIMER: Not fully compatible with stravants signal, use https://github.com/8ch32bit/MockSignal or another custom RBXScriptSignal with this library

Current API:

	-- Proxies --
	ProxyLib.NewProxy(Methods : Table, HookMeta : boolean?) -> Plain userdata with supplied metamethods, returns a blank one if HookMeta is false
	ProxyLib.Proxy() -> Blank proxified table (/w Event handling)
	ProxyLib.Proxify(Tab : Table, Metadata : Table?) -> Proxified table containing Tab with additional supplied metamethods
	ProxyLib.Deproxify(Obj : Userdata) -> Original table that was proxified (unless __metatable was filled in)
 	ProxyLib.rawset / .rawget / .rawlen -> raw-funcs for proxied tables
	-- Support --
	ProxyLib.Typeof(Tab : any) -> The __type value or typeof(Tab) if not feasible
	ProxyLib.FullLock(Tab : Table) -> Version of Tab where its read only & secured
	-- Metamethods
	ProxyLib.FilterMetamethods(Tab : Table | Userdata) -> Version of Tab where its metatable fields are removed if they arent a valid metamethod (excluding __type)
	ProxyLib.MetamethodHookFunc(Tab : Table | Userdata, Methods : Table | Userdata) -> Version of Tab where its metamethods are supplied in the Methods argument
	ProxyLib.ForceTypeNewindex(Tab : Table, Type : any) -> Version of Tab where adding new indexes will only work if theyre the supplied type (ie. string, number)
	ProxyLib.ExtractMeta(Tab : Table | Userdata) -> New table containing contents of given objects metatable
	ProxyLib.RetrieveMetatable(Obj : any, Attach : boolean?, __mt : boolean?) -> Returns given object's metatable, conditionally attaching it (arg 2) or conditionally returning __metatable field (arg 3)
	ProxyLib.MetaIndexSearch(Tab : Table | Userdata, Index : any) -> Value of Tab's specified metatable field
	-- Wrapping --
	Proxylib.Wrap(Obj : Instance, Properties : Table?) -> Userdata wrapping the object and containing properties
	Proxylib.UnWrap(Obj : Userdata) -> Instance wrapped by the userdata
	ProxyLib.IsWrapped(Obj : any) -> Boolean representing if the object is a userdata wrapping an Instance


Use example:

![image](https://github.com/ocelot81/ProxyLib/assets/128096274/9e89aed0-7554-4150-957d-d46ec5cbff52)


