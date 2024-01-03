{
  description =
    "terraform dev-env";


  #inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            google-cloud-sdk
            terraform
            terragrunt
            tflint
            #damon
            #levant
            #nomad
            #nomad-autoscaler
            #nomad-pack
            #packer
            #vault

            shellcheck
          ];
          shellHook = ''
            export PATH="$PWD/bin:$PATH"
          '';
        };
      });
    };
}
