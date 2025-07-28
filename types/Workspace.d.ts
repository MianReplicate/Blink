interface Workspace extends Model {
	Camera: Camera;
	SpawnLocation: SpawnLocation & {
		Decal: Decal;
	};
	Baseplate: Part & {
		Texture: Texture;
	};
}
