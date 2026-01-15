{nib, ...}: let
  inherit
    (builtins)
    attrNames
    attrValues
    concatStringsSep
    hasAttr
    length
    removeAttrs
    split
    ;

  inherit
    (nib.std)
    filterAttrs
    flipCurry
    genAttrs
    mergeAttrsList
    nameValuePair
    take
    ;

  inherit
    (nib.parse)
    overrideStruct
    ;

  inherit
    (nib.types)
    Terminal
    ;

  modNameFromPath = name: let
    parts = split "." name;
  in
    if length parts == 1
    then name
    else concatStringsSep "-" (take <| length <| parts - 1) parts;
in rec {
  # by default the imported module is given the basename of its path
  # but you can set it manually by using the `mix.mod` function.
  importMods = list: inputs:
    genAttrs list (path:
      nameValuePair (modNameFromPath path) (import path inputs));

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
      [
        base
        (importMods meta.submodules.${name} mixture)
      ]
      ++ (attrValues <| importMods meta.includes.${name} mixture);

    # NOTE: public submodules are still DESCENDENTS
    # NOTE: and should be able to access protected values :)
    public = mkInterface "public" protectedMixture content;
    protected = mkInterface "protected" protectedMixture public;
    private = mkInterface "private" privateMixture protected;
  in
    public;
}
