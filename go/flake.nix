{
  description = "flake for Golang 1.22 devenv";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = {
    self,
    nixpkgs,
    pre-commit-hooks,
  }: let
    supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forEachSupportedSystem = f:
      nixpkgs.lib.genAttrs supportedSystems (system:
        f {
          inherit system;
          pkgs = import nixpkgs {
            inherit system;
          };
        });
  in {
    checks = forEachSupportedSystem ({system, ...}: {
      pre-commit-check = pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          # nix
          alejandra.enable = true;
          alejandra.settings.check = true;
          deadnix.enable = true;
          deadnix.settings = {
            noLambdaArg = true;
            noLambdaPatternNames = true;
          };
          flake-checker.enable = true;
          # golang
          # revive.enable = true;
          gofmt.enable = true;
          gotest.enable = true;
          # shell scripts
          shellcheck.enable = true;
          beautysh.enable = true;
          # JSON
          check-json.enable = true;
          # generic
          check-toml.enable = true;
        };
      };
    });

    devShells = forEachSupportedSystem ({
      pkgs,
      system,
    }: {
      default = pkgs.mkShell {
        name = "go-dev";
        shellHook = ''
          export PATH="$PWD/bin:$PATH"
          ${self.checks.${system}.pre-commit-check.shellHook}
        '';
        packages =
          builtins.attrValues {
            inherit
              (pkgs)
              go_1_23
              gotools
              golangci-lint
              ;
          }
          ++ self.checks.${system}.pre-commit-check.enabledPackages;
      };
    });
  };
}
