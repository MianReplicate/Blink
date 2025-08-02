interface ServerScriptService extends Instance {
	EasyRagdoll: Folder & {
		["Read me"]: Script;
		EasyRagdoll: ModuleScript & {
			PackageLink: PackageLink;
		};
	};
	TS: Folder & {
		BlinkGame: Script;
		ActionManager: Script;
		Roles: Folder & {
			Survivor: ModuleScript;
			Actor: ModuleScript;
		};
		ServerDataObject: ModuleScript;
		Players: Script;
		GameHelper: ModuleScript;
	};
}
