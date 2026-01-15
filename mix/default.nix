{nib, ...}: let
  inherit
    (builtins)
    attrNames
    attrValues
    hasAttr
    listToAttrs
    removeAttrs
    ;

  inherit
    (nib.std)
    filterAttrs
    flipCurry
    hasInfix
    mergeAttrsList
    nameValuePair
    removeSuffix
    ;

  inherit
    (nib.parse)
    overrideStruct
    ;

  inherit
    (nib.types)
    Terminal
    ;

  modNameFromPath = path: let
    name = baseNameOf path |> removeSuffix ".nix";
  in
    assert (! hasInfix "." name)
    || throw ''
      Mix module ${path} has invalid name \"${name}\".
      Module names must not contain the . (period) character.
    ''; name;
in rec {
  # by default the imported module is given the basename of its path
  # but you can set it manually by using the `mix.mod` function.
  importMods = list: inputs:
    list
    |> map (path: nameValuePair (modNameFromPath path) (import path inputs))
    |> listToAttrs;

  importMergeMods = list: inputs:
    list
    |> map (path: (import path inputs))
    |> mergeAttrsList;

  # create a new and empty mixture
  newMixture' = let
    self = {
      # trapdoor attribute
      _' = {
        path = [];
        modName = null;
      };
    };
  in
    self;

  # a splash of this, a splash of that ^_^
  add = ingredients: mixture: let
    sidedish = mergeAttrsList ingredients;
  in
    # bone apple tea ;-;
    mixture // filterAttrs (x: _: ! hasAttr x mixture) sidedish;

  newMixture = inputs: modBuilder: let
    # mixture components are ordered based on shadowing
    mixture =
      inputs
      // importMods meta.submods.public inputs
      // importMergeMods meta.includes.public inputs
      // content;

    this = {
      # trapdoor attribute
      _' = {
        path = [];
      };
      parent' = throw "Mix: The mixture's root module has no parent by definition.";
    };

    # partition modAttrs' into metadata and content
    modAttrs' = modBuilder mixture;
    content = removeAttrs modAttrs' (attrNames meta);
    # attributes expected by and that directly modify mix's behaviour
    meta =
      flipCurry overrideStruct modAttrs'
      {
        includes = {
          public = [];
          private = [];
          protected = [];
        };
        submods = {
          public = [];
          private = [];
          protected = [];
        };
        options = Terminal {};
        config = Terminal {};
      };
  in
    mixture;

  mkMod = mixture: modBuilder: let
    # XXX: TODO
    # modAttrs = modBuilder privateMixture;
    modAttrs = modBuilder mixture;

    # attributes expected by and that directly modify mix's behaviour
    meta =
      flipCurry overrideStruct modAttrs
      {
        includes = {
          public = [];
          private = [];
          protected = [];
        };
        submods = {
          public = [];
          private = [];
          protected = [];
        };
        options = Terminal {};
        config = Terminal {};
      };

    # XXX: TODO
    # protectedMixture = add [public protected] mixture;
    # privateMixture = add [private] protectedMixture;

    mkInterface = name: mixture: base:
      mergeAttrsList
      (attrValues <| importMods meta.includes.${name} mixture)
      ++ [
        base
        (importMods meta.submods.${name} mixture)
      ];
    # XXX: TODO
    # NOTE: public submodules are still DESCENDENTS
    # NOTE: and should be able to access protected values :)
    # public = mkInterface "public" protectedMixture content;
    # protected = mkInterface "protected" protectedMixture public;
    # private = mkInterface "private" privateMixture protected;
    content = throw "TODO";
    public = mkInterface "public" mixture content;
    protected = mkInterface "protected" mixture public;
    private = mkInterface "private" mixture protected;
  in
    # XXX: TODO
    # public;
    modAttrs;
}
