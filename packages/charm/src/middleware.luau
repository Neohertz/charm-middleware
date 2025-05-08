local store = require(script.Parent.store)
local types = require(script.Parent.types)
type Selector<T> = types.Selector<T>

--[=[
	Define middleware for a given atom. Upon updating the atom, this middleware method
	will be used to modify the value.
	
	@param atom The atom or selector to subscribe to.
	@param middleware The middleware method.
]=]
local function middleware<T>(atom: types.Atom<T>, middleware: (state: T, prev: T) -> T): ()
	store.setMiddleware(atom, middleware)
end

return middleware
