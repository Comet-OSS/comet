type WatchHandler = (newValue: any?) -> any

declare debugger: {
	halt: (conditional: boolean?) -> (),
	watch: (name: string, handler: WatchHandler) -> (),
	watchBatch: (vars: { [string]: WatchHandler }) -> (),
	check: <T>(current: T, newValue: T?) -> T,

	watchStack: { [string]: WatchHandler },
}

--[=[
	<!-- markdownlint-disable MD024 -->

	# Marionette debugger

	## What it does

	Debugging tools are powerful. Virtually every IDE has one, including roblox studio.
	However, roblox cheat development is still behind, in, well every aspect of debugging. There is nothing.

	This project aims to fix that, it spins up a small node.js server and connects to your executor, injects debug macros and lets you have at it.

	- Hot reloads
	- Redirect output to VSCode terminals
	- Auto syntax and runtime redirection
	- Breakpoints

	### `debugger.halt()`

	Acts as a breakpoint.

	- Will pause execution once reached
	- Go back to your VSCode terminal to interact:
	- Evaluate expressions (only can interact to the watch stack or globals):

		```lua
		return getgenv().variable
		```

		```lua
		-- local var = 10
		-- debugger.watch("var", function(val) return debugger.check(score, val) end))
		var = 20; return var -- 20
		```

	- Type `continue` to resume

	#### Arguments

	- `conditional: boolean?` | Pass a inline conditional

	```lua
	local p = 10

	debugger.halt(p == 11) -- pass true/false explicitly
	```

	### `debugger.watch()`

	Register a variable to the watch stack. Lets you see its value and modify it in a eval.

	- Takes a get/set closure.
	- Automatically shows vars in the watch stack under `Local Variables` during a breakpoint.

	#### Arguments

	- `name: string` | The vars display name.
	- `handler: (set: any?) -> any` | Handles modifying and retrieving the variables value.

	```lua
	local score = 100

	debugger.watch("score", function(val)
		return debugger.check(score, val)
	end)
	```

	```lua
	-- In debug terminal
	DEBUG> return score
	10
	DEBUG> score = 20; return score
	20
	```

	### `debugger.watchBatch()`

	A convenience macro to register multiple local variables at once. Ideal for use at the start of a function or logic block.

	#### Arguments

	- `vars: {[string]: (set: any?) -> any}` | A dictionary of names and handler closures.

	```lua
	local power = 50
	local speed = 10

	debugger.watchBatch {
		power = function(v) debugger.check(power, v) end,
		speed = function(v) debugger.check(speed, v) end
	}
	```

	### `debugger.check()`

	Meant to be used within `debugger.watch()` or `debugger.watchBatch()`. Automatically checks conditions.

	#### Arguments

	- `current: any` | The current value
	- `newValue: any?` | Value passed from eval, if any.

	### `debugger.watchStack`

	The raw table containing all registered watch handlers.

	```lua
	table.clear(debugger.watchStack)
	```
]=]