{
  description = "standard elixir devShell w/ postgres";

  outputs = {
    self,
    nixpkgs,
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
    devShells = forEachSupportedSystem ({
      pkgs,
      system,
    }: {
      default = pkgs.mkShell {
        packages =
          builtins.attrValues {
            inherit
              (pkgs)
              git
              erlang
              postgresql_16
              ;
            inherit
              (pkgs.beam.packages.erlang_26)
              elixir_1_16
              ;
          }
          ++
          # Linux only
          pkgs.lib.optionals (pkgs.stdenv.isLinux) (with pkgs; [inotify-tools libnotify])
          ++
          # macOS only
          pkgs.lib.optionals (pkgs.stdenv.isDarwin) (with pkgs; [terminal-notifier])
          ++ pkgs.lib.optionals (pkgs.stdenv.isDarwin) (with pkgs.darwin.apple_sdk.frameworks; [CoreFoundation CoreServices]);

        shellHook = ''
          #export PGDATA="$PWD/db"
          export PATH="$HOME/.mix/escripts:$PWD/bin:$PATH"
        '';
      };
    });
  };
}
