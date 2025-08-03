interface RagdollModule {
	char: Model;
	player: Player;
	Ragdolled: boolean;
	RagdollOnDeath: boolean;
	ragdoll(Vector: Vector3): void;
}

interface RagdollModuleConstructor {
	new (character: Model, ragdollondeath: boolean): RagdollModule;
}

declare const RagdollModule: RagdollModuleConstructor;

export = RagdollModule;
