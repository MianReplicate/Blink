interface ReplicatedStorage extends Instance {
	SurvivorAnimations: Folder & {
		Dead: Animation;
		Blink: Animation;
	};
	TS: Folder & {
		module: ModuleScript;
		TickManager: ModuleScript;
		DataManager: ModuleScript;
		Util: ModuleScript;
		ReplicateManager: ModuleScript;
	};
	Settings: Configuration;
	rbxts_include: Folder & {
		RuntimeLib: ModuleScript;
		Promise: ModuleScript;
		node_modules: Folder & {
			["@rbxts"]: Folder & {
				["luau-polyfill"]: Folder & {
					out: ModuleScript & {
						Number: ModuleScript & {
							Number: ModuleScript;
							isSafeInteger: ModuleScript;
							toExponential: ModuleScript;
							isNaN: ModuleScript;
							MAX_SAFE_INTEGER: ModuleScript;
							isInteger: ModuleScript;
							isFinite: ModuleScript;
							MIN_SAFE_INTEGER: ModuleScript;
						};
						Console: ModuleScript & {
							makeConsoleImpl: ModuleScript;
						};
						InstanceOf: ModuleScript & {
							["instanceof"]: ModuleScript;
						};
						Symbol: ModuleScript & {
							["Registry.global"]: ModuleScript;
							Symbol: ModuleScript;
						};
						["extends"]: ModuleScript;
						Timers: ModuleScript & {
							makeIntervalImpl: ModuleScript;
							makeTimerImpl: ModuleScript;
						};
						encodeURIComponent: ModuleScript;
						String: ModuleScript & {
							endsWith: ModuleScript;
							indexOf: ModuleScript;
							lastIndexOf: ModuleScript;
							trimStart: ModuleScript;
							trim: ModuleScript;
							findOr: ModuleScript;
							substr: ModuleScript;
							slice: ModuleScript;
							startsWith: ModuleScript;
							charCodeAt: ModuleScript;
							trimEnd: ModuleScript;
							includes: ModuleScript;
							split: ModuleScript;
						};
						Promise: ModuleScript;
						ES7Types: ModuleScript;
						Collections: ModuleScript & {
							Map: ModuleScript & {
								Map: ModuleScript;
								coerceToTable: ModuleScript;
								coerceToMap: ModuleScript;
							};
							Object: ModuleScript & {
								values: ModuleScript;
								assign: ModuleScript;
								is: ModuleScript;
								seal: ModuleScript;
								entries: ModuleScript;
								preventExtensions: ModuleScript;
								isFrozen: ModuleScript;
								keys: ModuleScript;
								freeze: ModuleScript;
								None: ModuleScript;
							};
							Set: ModuleScript;
							Array: ModuleScript & {
								flat: ModuleScript;
								indexOf: ModuleScript;
								every: ModuleScript;
								slice: ModuleScript;
								sort: ModuleScript;
								shift: ModuleScript;
								map: ModuleScript;
								isArray: ModuleScript;
								findIndex: ModuleScript;
								unshift: ModuleScript;
								splice: ModuleScript;
								filter: ModuleScript;
								find: ModuleScript;
								forEach: ModuleScript;
								reverse: ModuleScript;
								includes: ModuleScript;
								concat: ModuleScript;
								from: ModuleScript & {
									fromString: ModuleScript;
									fromArray: ModuleScript;
									fromSet: ModuleScript;
									fromMap: ModuleScript;
								};
								join: ModuleScript;
								flatMap: ModuleScript;
								reduce: ModuleScript;
								some: ModuleScript;
							};
							inspect: ModuleScript;
							WeakMap: ModuleScript;
						};
						Math: ModuleScript;
						Error: ModuleScript & {
							["Error.global"]: ModuleScript;
						};
						Boolean: ModuleScript & {
							toJSBoolean: ModuleScript;
						};
						AssertionError: ModuleScript & {
							["AssertionError.global"]: ModuleScript;
						};
					};
				};
				services: ModuleScript;
				iris: Folder & {
					src: ModuleScript & {
						config: ModuleScript;
						lib: Folder & {
							widgets: Folder & {
								creation: Folder;
							};
							iris: Folder;
						};
						Types: ModuleScript;
						demoWindow: ModuleScript;
						Internal: ModuleScript;
						API: ModuleScript;
						widgets: ModuleScript & {
							Plot: ModuleScript;
							Combo: ModuleScript;
							Root: ModuleScript;
							Text: ModuleScript;
							Window: ModuleScript;
							Tree: ModuleScript;
							Table: ModuleScript;
							Image: ModuleScript;
							Menu: ModuleScript;
							RadioButton: ModuleScript;
							Input: ModuleScript;
							Format: ModuleScript;
							Checkbox: ModuleScript;
							Button: ModuleScript;
						};
					};
				};
				["compiler-types"]: Folder & {
					types: Folder;
				};
				types: Folder & {
					include: Folder & {
						generated: Folder;
					};
				};
			};
		};
	};
}
