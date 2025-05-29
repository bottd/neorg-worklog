{
  description = "Neorg worklog plugin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix.url = "github:numtide/treefmt-nix";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = { self, nixpkgs, flake-utils, neovim-nightly-overlay, treefmt-nix, pre-commit-hooks }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ neovim-nightly-overlay.overlays.default ];
        pkgs = import nixpkgs { inherit system overlays; };
        
        treefmtEval = treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs = {
            nixpkgs-fmt.enable = true;
            stylua = {
              enable = true;
              settings = {
                indent_type = "spaces";
                indent_width = 2;
              };
            };
          };
        };

        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            treefmt = {
              enable = true;
              package = treefmtEval.config.build.wrapper;
            };
            luacheck.enable = true;
          };
        };
      in
      {
        formatter = treefmtEval.config.build.wrapper;

        checks = {
          formatting = treefmtEval.config.build.check ./.;
          pre-commit = pre-commit-check;
        };

        devShells.default = pkgs.mkShell {
          name = "neorg-worklog";
          shellHook = ''
            ${pre-commit-check.shellHook}
            echo "🚀 Neorg Worklog Development Environment"
          '';

          buildInputs = with pkgs; [
            # Use stable by default
            neovim
            # Uncomment for nightly:
            # neovim-nightly
            
            lua-language-server
            stylua
            luacheck
            treefmtEval.config.build.wrapper
          ];
        };
      });
}
