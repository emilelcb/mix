{
  description = "Mix - (Better) Modules For Nix";

  inputs = {
    nib = {
      url = "github:emilelcb/nib";
      # url = "/home/me/agribit/nexus/nib";
    };
  };

  outputs = inputs: import ./mix inputs;
}
