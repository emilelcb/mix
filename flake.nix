{
  description = "Mix - (Better) Modules For Nix";

  inputs.systems.url = "github:nix-systems/default";

  outputs = {...} @ inputs: let
    systems = import inputs.systems;
  in
    import ./mix {inherit systems;};
}
