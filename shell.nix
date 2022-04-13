let
  pkgs = import <nixpkgs> { };
  hunspellES = pkgs.hunspellWithDicts [ pkgs.hunspellDicts.es_ES ];
in pkgs.mkShell {
  name = "yorodm-blog";
  buildInputs = with pkgs; [ hugo hunspellES ];
}
