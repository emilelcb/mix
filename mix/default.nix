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
    mergeAttrsList
    nameValuePair
    ;

  inherit
    (nib.parse)
    overrideStruct
    ;

  inherit
    (nib.strings)
    removeSuffix
    hasInfix
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

  # create a new and empty mixture
  newMixture = let
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

  mkMod = mixture: modBuilder: let
    modAttrs = modBuilder privateMixture;

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
    # other random attributes (ie functions and variables the user uses)
    content = removeAttrs modAttrs (attrNames modAttrs);

    protectedMixture = add [public protected] mixture;
    privateMixture = add [private] protectedMixture;

    mkInterface = name: mixture: base:
      mergeAttrsList
      (attrValues <| importMods meta.includes.${name} mixture)
      ++ [
        base
        (importMods meta.submods.${name} mixture)
      ];

    # NOTE: public submodules are still DESCENDENTS
    # NOTE: and should be able to access protected values :)
    public = mkInterface "public" protectedMixture content;
    protected = mkInterface "protected" protectedMixture public;
    private = mkInterface "private" privateMixture protected;
  in
    public;
}
