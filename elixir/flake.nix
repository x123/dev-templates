{
  description = "standard elixir devShell w/ postgres";

  #inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = (with pkgs;
          [
            beam.packages.erlangR26.elixir_1_16
            git
            erlang
            postgresql_16
          ]) ++
          # Linux only
          pkgs.lib.optionals (pkgs.stdenv.isLinux) (with pkgs; [ inotify-tools libnotify ]) ++
          # macOS only
          pkgs.lib.optionals (pkgs.stdenv.isDarwin) (with pkgs; [ terminal-notifier ]) ++
          pkgs.lib.optionals (pkgs.stdenv.isDarwin) (with pkgs.darwin.apple_sdk.frameworks; [ CoreFoundation CoreServices ]);

          shellHook = ''
            #export PGDATA="$PWD/db"
            export PATH="$HOME/.mix/escripts:$PWD/bin:$PATH"
          '';
        };
      });
    };
}
