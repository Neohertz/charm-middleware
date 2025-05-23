local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Charm = require(ReplicatedStorage.DevPackages.Charm)
local atom = Charm.atom
local subscribe = Charm.subscribe
local CharmSync = require(ReplicatedStorage.DevPackages.CharmSync)
local client = CharmSync.client

return function()
	it("syncs state payload", function()
		local a = atom(1)
		local client = client({ atoms = { a = a } })

		client:sync({
			type = "init",
			data = { a = 2 },
		})

		expect(a()).to.equal(2)
	end)

	it("syncs state patch", function()
		local a = atom({ b = 1, c = 2 })
		local previous = a()
		local client = client({ atoms = { a = a } })

		client:sync({
			type = "init",
			data = { a = a() },
		})

		expect(a()).to.equal(previous)

		client:sync({
			type = "patch",
			data = { a = { b = 3 } },
		})

		expect(a()).to.never.equal(previous)
		expect(a().b).to.equal(3)
		expect(a().c).to.equal(2)
	end)

	it("fixes sparse array patches", function()
		local a = atom({ 1 })
		local client = client({ atoms = { a = a } })

		client:sync({
			type = "init",
			data = { a = a() },
		})

		-- This patch would be the result of a diff between { 1 } and { 1, 2 } that
		-- was JSON-serialized and deserialized. The client should be able to catch
		-- this and convert the string key back to a number.
		client:sync({
			type = "patch",
			data = { a = { ["2"] = 2 } },
		})

		expect(a()["2" :: any]).to.never.be.ok()
		expect(a()[2]).to.equal(2)
	end)

	it("applies multiple patches", function()
		local a = atom(1)
		local client = client({ atoms = { a = a } })
		local calls = {}

		subscribe(a, function(value)
			table.insert(calls, value)
		end)

		client:sync({
			type = "init",
			data = { a = a() },
		})

		client:sync({
			type = "patch",
			data = { a = 2 },
		}, {
			type = "patch",
			data = { a = 3 },
		})

		expect(a()).to.equal(3)
		expect(calls[1]).to.equal(2)
		expect(calls[2]).to.equal(3)
	end)

	it("batches patches", function()
		local a = atom(0)
		local b = atom(0)
		local client = client({ atoms = { a = a, b = b } })
		local states = {}

		subscribe(a, function()
			states.b = b()
		end)

		subscribe(b, function()
			states.a = a()
		end)

		client:sync({
			type = "init",
			data = { a = a(), b = b() },
		})

		client:sync({
			type = "patch",
			data = { a = 1, b = 2 },
		})

		expect(a()).to.equal(1)
		expect(b()).to.equal(2)
		expect(states.a).to.equal(1)
		expect(states.b).to.equal(2)
	end)
end
