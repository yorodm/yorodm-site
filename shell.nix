let
  pkgs = import <nixpkgs> {};
in
pkgs.mkShell {
  name ="yorodm-blog";
  buildInputs = with pkgs; [
    hugo
  ];
}
