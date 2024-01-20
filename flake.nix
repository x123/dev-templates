{
  description = "templates for flake-driven dev environments";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      overlays = [
        (final: prev:
          let
            exec = pkg: "${prev.${pkg}}/bin/${pkg}";
          in
          {
            format = prev.writeScriptBin "format" ''
              ${exec "nixpkgs-fmt"} **/*.nix
            '';
            dvt = prev.writeScriptBin "dvt" ''
              if [ -z $1 ]; then
                echo "no template specified"
                exit 1
              fi

              TEMPLATE=$1

              ${exec "nix"} \
                --experimental-features 'nix-command flakes' \
                flake init \
                --template \
                "github:the-nix-way/dev-templates#''${TEMPLATE}"
            '';
            binary-cache = prev.writeScriptBin "binary-cache" ''
              if [ -z $1 ]; then
                echo "No remote destiation specified."
                echo "Example usage: binary-cache root@somewhere.tld"
                exit 1
              fi

              REMOTE=$1
              CUR_SYSTEM=`${exec "nix"} eval --impure --raw --expr 'builtins.currentSystem'`

              for dir in `ls -d */`; do # Iterate through all the templates
                (
                  cd $dir
                  echo "Updating binary-cache for ''${dir}"
                  ${exec "nix"} copy --to ssh://''${REMOTE} .#devShells.''${CUR_SYSTEM}.default
                )
              done
            '';
            update = prev.writeScriptBin "update" ''
              for dir in `ls -d */`; do # Iterate through all the templates
                (
                  cd $dir
                  ${exec "nix"} flake update # Update flake.lock
                  ${exec "nix"} flake check  # Make sure things work after the update
                )
              done
            '';
          })
      ];
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit overlays system; };
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [ format update binary-cache ];
        };
      });

      packages = forEachSupportedSystem ({ pkgs }: rec {
        default = dvt;
        inherit (pkgs) dvt;
      });
    }

    //

    {
      templates = rec {
        elixir = {
          path = ./elixir;
          description = "Elixir development environment";
        };

        go = {
          path = ./go;
          description = "Go development environment";
        };

        terraform = {
          path = ./terraform;
          description = "terraform development environment";
        };

        nix = {
          path = ./nix;
          description = "Nix development environment";
        };

        python = {
          path = ./python;
          description = "Giga Python development environment";
        };

        python-giga = {
          path = ./python-giga;
          description = "Giga Python development environment";
        };
      };
    };
}
