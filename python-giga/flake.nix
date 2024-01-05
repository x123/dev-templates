{
  description = "Giga python packaged using poetry2nix";
  nixConfig = {
    extra-substituters = [
      "https://nixium.boxchop.city"
    ];
    extra-trusted-public-keys = [
      # TODO: eventually remove this original
      "nixium.boxchop.city:VqGEePxRjPwhVfnLAJBi2duwwkIczIy5ODGW/8KCPbc="

      # current key
      "nixium.boxchop.city-1:I/9SEHdelbS1b8ZX5QeeQKtsugsCcIqCVCec4TZPXIw="
    ];
  };

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        myPostgres = pkgs.postgresql_13.withPackages (p:
          [ p.hypopg]
        );

        inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryApplication;
        inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) defaultPoetryOverrides;
      in
      {
        packages = {
          myapp = mkPoetryApplication {
            projectDir = self;

            python = pkgs.python310;

            # most of the overrides below are providing setuptools, and could
            # be streamlined a bit see:
            # https://github.com/nix-community/poetry2nix/blob/master/docs/edgecases.md
            #
            # other more complicated overrides are usually drawn directly from
            # options in the relevant nixpkgs/pkgs/development/python-modules

            overrides = defaultPoetryOverrides.extend
              (self: super: {

                setuptools = super.setuptools.overridePythonAttrs
                  (
                    old: {
                      version = "65.7.0";

                      src = super.pkgs.fetchFromGitHub {
                        version = "65.7.0";
                        owner = "pypa";
                        repo = "setuptools";
                        rev = "refs/tags/v65.7.0";
                        hash = "sha256-8SfWFQYg6I/7M5zUIMNmQPllmzH+jrSZg9j4n+DbFr4=";
                      };
                    }
                  );

                pygal = super.pygal.overridePythonAttrs
                  (
                    old: {
                      postPatch = ''
                        substituteInPlace setup.py \
                          --replace pytest-runner ""
                      '';
                    }
                  );

                starlette-wtf = super.starlette-wtf.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
                    }
                  );

                josepy = super.josepy.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.poetry ];
                    }
                  );

                pytest-only = super.pytest-only.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.poetry ];
                    }
                  );

                wsgi-lite = super.wsgi-lite.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
                      postPatch = ''
                        substituteInPlace setup.py \
                          --replace setuptools_hg "setuptools"
                      '';
                    }
                  );

                flake8-tidy-imports = super.flake8-tidy-imports.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
                    }
                  );

                # ssdeep still always fails with pytest-runner errors, even if
                # putting it in the buildInputs overrides as is often a fix
                # for other packages.
                ssdeep = super.ssdeep.overridePythonAttrs
                  (
                    old: {
                      nativeBuildInputs = (old.nativeBuildInputs or [ ])
                        ++ [
                      ];
                      buildInputs = (old.buildInputs or [ ])
                        ++ [
                        super.poetry
                        pkgs.ssdeep
                      ];

                      propagatedBuildInputs = (old.propagatedBuildInputs or [ ])
                        ++ [
                        super.cffi
                        super.six
                      ];

                      nativeCheckInputs = (old.nativeCheckInputs or [ ])
                        ++ [
                        super.pytestCheckHook
                      ];

                      # TODO: many other packages workaround pytest-runner issues
                      # by replacing calls to it, but none of the following
                      # appear to work
                      postPatch = ''
                        substituteInPlace setup.py \
                          --replace '"pytest-runner"' ""
                      '';

                      pythonImportsCheck = [
                        "ssdeep"
                      ];

                    }
                  );

                flake8-rst-docstrings = super.flake8-rst-docstrings.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
                    }
                  );

                pytest-faker = super.pytest-faker.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
                    }
                  );

                pyinterval = super.pyinterval.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
                    }
                  );

                # taken from nixpkgs/pkgs/development/python-modules/levenshtein 
                levenshtein = super.levenshtein.overridePythonAttrs
                  (
                    old: {
                      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ super.cmake super.cython_3 super.scikit-build ] ++ super.lib.optionals super.stdenv.isDarwin [ pkgs.xcodebuild ];
                      buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.rapidfuzz-cpp super.packaging ];
                      dontUseCmakeConfigure = true;
                      env.NIX_CFLAGS_COMPILE = toString (super.lib.optionals (super.stdenv.cc.isClang && super.stdenv.isDarwin) [
                        "-fno-lto"
                      ]);
                    }
                  );

                # TODO: fix pandas
                # took all options from nixpkgs/pkgs/development/python-modules/pandas
                # abandon all hope ye who enter here, for THERE BE DRAGONS!!!

                pandas = super.pandas.overridePythonAttrs
                  (
                    old: {
                      postPatch = ''
                        substituteInPlace pyproject.toml \
                          --replace "meson-python==0.13.1" "meson-python>=0.13.1" \
                          --replace "meson==1.2.1" "meson>=1.2.1"
                      '';

                      nativeBuildInputs = (old.nativeBuildInputs or [ ])
                        ++ [
                        super.cython
                        super.meson-python
                        super.meson
                        super.numpy
                        super.pkgconfig
                        super.versioneer
                        super.wheel
                      ]
                        ++ super.versioneer.optional-dependencies.toml
                        ++ super.lib.optionals (super.python.pythonOlder "3.12") [
                        #++ pkgs.lib.optionals (pkgs.python.pythonOlder "3.12") [
                        super.oldest-supported-numpy
                      ];

                      enableParallelBuilding = true;

                      propagatedBuildInputs = (old.propagatedBuildInputs or [ ])
                        ++ [
                        super.meson-python
                        super.meson
                        super.numpy
                        super.python-dateutil
                        super.pytz
                        super.tzdata
                      ];
                      #
                      #                      passthru.optional-dependencies =
                      #                        let
                      #                          extras = {
                      #                            aws = [
                      #                              super.s3fs
                      #                            ];
                      #                            clipboard = [
                      #                              super.pyqt5
                      #                              super.qtpy
                      #                            ];
                      #                            compression = [
                      #                              super.brotlipy
                      #                              super.python-snappy
                      #                              super.zstandard
                      #                            ];
                      #                            computation = [
                      #                              super.scipy
                      #                              super.xarray
                      #                            ];
                      #                            excel = [
                      #                              super.odfpy
                      #                              super.openpyxl
                      #                              # TODO: pyxlsb
                      #                              super.xlrd
                      #                              super.xlsxwriter
                      #                            ];
                      #                            feather = [
                      #                              super.pyarrow
                      #                            ];
                      #                            fss = [
                      #                              super.fsspec
                      #                            ];
                      #                            gcp = [
                      #                              super.gcsfs
                      #                              # TODO: pandas-gqb
                      #                            ];
                      #                            hdf5 = [
                      #                              super.blosc2
                      #                              super.tables
                      #                            ];
                      #                            html = [
                      #                              super.beautifulsoup4
                      #                              super.html5lib
                      #                              super.lxml
                      #                            ];
                      #                            mysql = [
                      #                              super.sqlalchemy
                      #                              super.pymysql
                      #                            ];
                      #                            output_formatting = [
                      #                              super.jinja2
                      #                              super.tabulate
                      #                            ];
                      #                            parquet = [
                      #                              super.pyarrow
                      #                            ];
                      #                            performance = [
                      #                              super.bottleneck
                      #                              super.numba
                      #                              super.numexpr
                      #                            ];
                      #                            plot = [
                      #                              super.matplotlib
                      #                            ];
                      #                            postgresql = [
                      #                              super.sqlalchemy
                      #                              super.psycopg2
                      #                            ];
                      #                            spss = [
                      #                              super.pyreadstat
                      #                            ];
                      #                            sql-other = [
                      #                              super.sqlalchemy
                      #                            ];
                      #                            xml = [
                      #                              super.lxml
                      #                            ];
                      #                          };
                      #                        in
                      #                        extras // {
                      #                          all = super.lib.concatLists (super.lib.attrValues extras);
                      #                        };
                      #
                      #                      nativeCheckInputs = (old.nativeCheckInputs or [ ])
                      #                        ++ [
                      #                        super.glibcLocales
                      #                        super.hypothesis
                      #                        super.pytest-asyncio
                      #                        super.pytest-xdist
                      #                        super.pytestCheckHook
                      #                      ] ++ super.lib.optionals (super.stdenv.isLinux) [
                      #                        # for locale executable
                      #                        super.glibc
                      #                      ] ++ super.lib.optionals (super.stdenv.isDarwin) [
                      #                        # for locale executable
                      #                        super.adv_cmds
                      #                      ];
                      #
                      #                      # don't max out build cores, it breaks tests
                      #                      dontUsePytestXdist = true;
                      #
                      #                      __darwinAllowLocalNetworking = true;
                      #
                      #                      pytestFlagsArray = (old.pytestFlagsArray or [ ])
                      #                        ++ [
                      #                        # https://github.com/pandas-dev/pandas/blob/main/test_fast.sh
                      #                        "-m"
                      #                        "'not single_cpu and not slow and not network and not db and not slow_arm'"
                      #                        # https://github.com/pandas-dev/pandas/issues/54907
                      #                        "--no-strict-data-files"
                      #                        "--numprocesses"
                      #                        "4"
                      #                      ];
                      #
                      #                      disabledTests = (old.disabledTests or [ ])
                      #                        ++ [
                      #                        # AssertionError: Did not see expected warning of class 'FutureWarning'
                      #                        "test_parsing_tzlocal_deprecated"
                      #                      ] ++ super.lib.optionals (super.stdenv.isDarwin && super.stdenv.isAarch64) [
                      #                        # tests/generic/test_finalize.py::test_binops[and_-args4-right] - AssertionError: assert {} == {'a': 1}
                      #                        "test_binops"
                      #                        # These tests are unreliable on aarch64-darwin. See https://github.com/pandas-dev/pandas/issues/38921.
                      #                        "test_rolling"
                      #                      ] ++ super.lib.optional super.stdenv.is32bit [
                      #                        # https://github.com/pandas-dev/pandas/issues/37398
                      #                        "test_rolling_var_numerical_issues"
                      #                      ];
                      #
                      #                      # Tests have relative paths, and need to reference compiled C extensions
                      #                      # so change directory where `import .test` is able to be resolved
                      #                      preCheck = ''
                      #                        export HOME=$TMPDIR
                      #                        export LC_ALL="en_US.UTF-8"
                      #                        cd $out/${super.python.sitePackages}/pandas
                      #                      ''
                      #                      # TODO: Get locale and clipboard support working on darwin.
                      #                      #       Until then we disable the tests.
                      #                      + super.lib.optionalString super.stdenv.isDarwin ''
                      #                        # Fake the impure dependencies pbpaste and pbcopy
                      #                        echo "#!${super.runtimeShell}" > pbcopy
                      #                        echo "#!${super.runtimeShell}" > pbpaste
                      #                        chmod a+x pbcopy pbpaste
                      #                        export PATH=$(pwd):$PATH
                      #                      '';
                      #
                      #                      pythonImportsCheck = [
                      #                        "pandas"
                      #                      ];
                      #
                      #                      buildInputs = (old.buildInputs or [ ]) ++ [ ];
                    }
                  );

                autodoc-pydantic = super.autodoc-pydantic.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.poetry ];
                    }
                  );

                o365 = super.o365.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
                    }
                  );

                wordsegment = super.wordsegment.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
                    }
                  );

                types-flask = super.types-flask.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
                    }
                  );

                types-jinja2 = super.types-jinja2.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
                    }
                  );

                types-werkzeug = super.types-werkzeug.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
                    }
                  );

                types-markupsafe = super.types-markupsafe.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
                    }
                  );

                sphinxcontrib-mermaid = super.sphinxcontrib-mermaid.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
                    }
                  );

                resolver = super.resolver.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
                    }
                  );

                py-interval = super.py-interval.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
                    }
                  );

                path-py = super.path-py.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
                    }
                  );

                jinja2-highlight = super.jinja2-highlight.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
                    }
                  );

                beanstalkc3 = super.beanstalkc3.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
                    }
                  );

                crlibm = super.crlibm.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
                    }
                  );
                interval = super.interval.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
                    }
                  );
                intervals = super.intervals.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
                    }
                  );

                wtforms-alchemy = super.wtforms-alchemy.overridePythonAttrs
                  (
                    old: {
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
                    }
                  );
              }
              );
          };

          default = self.packages.${system}.myapp;

          pg-up = pkgs.writeScriptBin "pg-up" ''
            ${myPostgres}/bin/pg_ctl -D $PGDATA start
          '';

          pg-down = pkgs.writeScriptBin "pg-down" ''
            ${myPostgres}/bin/pg_ctl -D $PGDATA stop
          '';

          pg-connect = pkgs.writeScriptBin "pg-connect" ''
            ${myPostgres}/bin/psql -h $PGDATA/sockets postgres
          '';
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [ self.packages.${system}.myapp ];
          packages = with pkgs; [
            db62
            libffi
            openssl
            poetry
            redis
            myPostgres

            self.packages.${system}.pg-up
            self.packages.${system}.pg-down
            self.packages.${system}.pg-connect
          ];
          shellHook = ''
            export PG_TMPDIR=`${pkgs.coreutils}/bin/mktemp -dt pg13-test-$$-XXXXXX`
            #echo $PG_TMPDIR
            export PGDATA=$PG_TMPDIR
            export PGPORT=5432
            export PGHOST=localhost
            export PGDATABASE=postgres
            export PGUSER=postgres
            ${myPostgres}/bin/initdb $PGDATA
            mkdir -pv $PGDATA/sockets
            echo "unix_socket_directories = '$PGDATA/sockets'" >> $PGDATA/postgresql.conf

            ${myPostgres}/bin/pg_ctl -D $PGDATA start
            ${myPostgres}/bin/createuser -h $PGDATA/sockets postgres --createdb
            ${myPostgres}/bin/createuser -h $PGDATA/sockets pgsql --createdb
            ${myPostgres}/bin/psql -h $PGDATA/sockets postgres -c "ALTER ROLE postgres SUPERUSER;"
            ${myPostgres}/bin/psql -h $PGDATA/sockets postgres -c "ALTER ROLE pgsql SUPERUSER;"

            #export "postgresql:///postgres?host=$PGDATA/sockets"
            ${pkgs.redis}/bin/redis-server --daemonize yes

            echo "#########################################################################"
            echo "Use pg-up, pg-connect, and pg-down to start, connect, and stop postgres. "
            echo "#########################################################################"

            trap cleanup EXIT

            cleanup()
            {
              ${myPostgres}/bin/pg_ctl -D $PGDATA stop
              echo "Removing PG_TMPDIR ''${PG_TMPDIR}"
              rm -rf ''${PG_TMPDIR}

              killall -9 redis-server
            }
          '';
        };
      });
}
