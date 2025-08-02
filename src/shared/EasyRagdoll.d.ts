interface EasyRagdoll {
	SetRagdoll(character: Model, value: boolean, applyPushOnRagdoll?: boolean, pushMagnitude?: number): void;
}

declare const EasyRagdoll: EasyRagdoll;

export = EasyRagdoll;
