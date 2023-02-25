{ inputs, pkgs, ... }:
with inputs.nix-filter.lib;
with inputs.nix-utils.lib;
with pkgs.haskell.lib;
let
  hpkgs = slow pkgs.haskellPackages [{
    modifiers = [ ];
    extension = hfinal: hprevious:
      with hfinal; {
        EarleyM = overrideCabal (callCabal2nix "EarleyM" (filter {
          root = inputs.self;
          exclude = [ (matchExt "cabal") "stack.yaml" ];
        }) { }) (drv: {
          postPatch = (drv.postPatch or "") + ''
            substituteInPlace examples/Example/DictionaryLexing.hs --replace "/usr/share/dict/cracklib-small" "${inputs.cracklib}/src/dicts/cracklib-small"
          '';
        });
      };
  }];
in with hpkgs;
with pkgs; {
  env.GREET = "devenv";
  packages = [
    git
    (ghcWithPackages
      (p: with p; [ EarleyM cabal-install haskell-language-server ]))
  ];
  scripts = {
    repl.exec = ''${ghcid}/bin/ghcid -W -a -c "cabal repl lib:EarleyM"'';
  };
  enterShell = ''
    ${fortune}/bin/fortune | ${ponysay}/bin/ponysay
    git --version
    ${hpack}/bin/hpack -f package.yaml
    ${implicit-hie}/bin/gen-hie --cabal &> hie.yaml
  '';
  languages = { nix.enable = true; };
  pre-commit.hooks = {
    nixfmt.enable = true;
    fourmolu.enable = true;
  };
}
