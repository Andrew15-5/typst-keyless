{
  description = "Keyless Typst compatibility tests";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      checks = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };

          typstRelease = version: hash:
            pkgs.stdenvNoCC.mkDerivation {
              pname = "typst";
              inherit version;

              src = pkgs.fetchurl {
                url = "https://github.com/typst/typst/releases/download/v${version}/typst-x86_64-unknown-linux-musl.tar.xz";
                inherit hash;
              };

              installPhase = ''
                runHook preInstall
                install -Dm755 typst $out/bin/typst
                runHook postInstall
              '';
            };

          versions = {
            "0_8_0" = typstRelease "0.8.0" "sha256-qoh3WtoMU/Sr1I/v+z70gZkw/DOlI3UlW1SaSoegWGc=";
            "0_9_0" = typstRelease "0.9.0" "sha256-8dL13SZD/ndfzoEU3t344rAXulEZgo+lLPT3FPxuQiM=";
            "0_10_0" = typstRelease "0.10.0" "sha256-0+HyZhhvmhMHYig7yJB6vrxjJn8IvQOjNm95UnupWtk=";
            "0_11_0" = typstRelease "0.11.0" "sha256-cLiyWsDObSP9vAsFXPALB2mtdffVop+urpKG4VjM6VI=";
            "0_11_1" = typstRelease "0.11.1" "sha256-u2N9HWVjSy7ktOEB0LLVQb8/HgOsX1H5YZlB5I3Si9A=";
            "0_12_0" = typstRelease "0.12.0" "sha256-YFEwp3Dr1ZpKV5ZzB5y5E6E+dZhSMWV6cdYjmldTnsM=";
            "0_13_0" = typstRelease "0.13.0" "sha256-zRFI2mHWhE5iwzD8YiLpiEgKyv4zt22uyOtdIhJY/rY=";
            "0_13_1" = typstRelease "0.13.1" "sha256-fSFL/v/C5YXcQi0aCdKxRJaUISgejH9deEtl/Gm1Zz8=";
            "0_14_0" = typstRelease "0.14.0" "sha256-mYFtKYLeCNKwkbrFa1my+qUjoQ4TeK083WjjW463Sz0=";
            "0_14_1" = typstRelease "0.14.1" "sha256-ate3lPcceB/sSnQvzdEF3qwStZ5eeljbmMyuf4QI0UE=";
            "0_14_2" = typstRelease "0.14.2" "sha256-pgRMutKpVN65IRZ+JX4SCsChayAznsARIRlP+dOUmW0=";
          };

          compatTest = name: typst:
            pkgs.runCommand "keyless-typst-${name}-compat" { nativeBuildInputs = [ pkgs.coreutils pkgs.python3 typst ]; } ''
              cp -R ${self} source
              chmod -R u+w source
              base64 -d source/tests/fixtures/white-black.png.b64 > source/tests/fixtures/white-black.png
              typst query --root source source/tests/compat.typ '<keyed-png>' --one --field value --format json > keyed.json
              python3 source/tests/analyze-keyed-png.py keyed.json keyed.png
              typst compile --root source source/tests/compat.typ compat.pdf
              typst compile --root source source/tests/visual-kun.typ visual-kun.pdf
              typst compile --root source source/tests/visual-chan.typ visual-chan.pdf
              mkdir $out
              cp compat.pdf keyed.json keyed.png visual-kun.pdf visual-chan.pdf $out/
            '';
        in
        builtins.mapAttrs compatTest versions);

      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          checkNames = [
            "0_8_0"
            "0_9_0"
            "0_10_0"
            "0_11_0"
            "0_11_1"
            "0_12_0"
            "0_13_0"
            "0_13_1"
            "0_14_0"
            "0_14_1"
            "0_14_2"
          ];
          copyArtifact = check: ''
            version=${nixpkgs.lib.replaceStrings [ "_" ] [ "." ] check}
            mkdir -p "$out/typst-$version"
            cp -R ${self.checks.${system}.${check}}/* "$out/typst-$version/"
            printf 'Typst %s: compat.pdf, visual-kun.pdf, visual-chan.pdf, keyed.png, keyed.json\n' "$version" >> "$out/report.txt"
          '';
          latestCheck = "0_14_2";
        in
        {
          artifacts = pkgs.runCommand "keyless-typst-artifacts" { } ''
            mkdir $out
            printf 'Keyless Typst compatibility artifacts\n\n' > "$out/report.txt"
            ${nixpkgs.lib.concatMapStringsSep "\n" copyArtifact checkNames}
          '';
          artifacts-latest = pkgs.runCommand "keyless-typst-latest-artifacts" { } ''
            mkdir $out
            printf 'Keyless Typst latest compatibility artifacts\n\n' > "$out/report.txt"
            ${copyArtifact latestCheck}
          '';
          default = self.packages.${system}.artifacts;
        });

      apps = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          checkNames = [
            "0_8_0"
            "0_9_0"
            "0_10_0"
            "0_11_0"
            "0_11_1"
            "0_12_0"
            "0_13_0"
            "0_13_1"
            "0_14_0"
            "0_14_1"
            "0_14_2"
          ];
          testMatrix = pkgs.writeShellApplication {
            name = "keyless-test-matrix";
            runtimeInputs = [ pkgs.nix ];
            text = ''
              set +e

              checks=(${nixpkgs.lib.concatStringsSep " " checkNames})
              total=''${#checks[@]}
              passed=0
              failed=()

              for check in "''${checks[@]}"; do
                version="''${check//_/.}"
                printf 'Typst %s ... ' "$version"

                log="$(mktemp)"
                nix build ".#checks.${system}.$check" --no-link >"$log" 2>&1
                status=$?

                if [ "$status" -eq 0 ]; then
                  passed=$((passed + 1))
                  printf 'passed\n'
                else
                  failed+=("$check")
                  printf 'failed\n'
                  sed 's/^/  /' "$log"
                fi

                rm -f "$log"
              done

              printf '\n%d/%d passed\n' "$passed" "$total"

              if [ "''${#failed[@]}" -ne 0 ]; then
                printf 'Failed checks: %s\n' "''${failed[*]}"
                exit 1
              fi
            '';
          };
        in
        {
          test-matrix = {
            type = "app";
            program = "${testMatrix}/bin/keyless-test-matrix";
            meta.description = "Run the Keyless Typst compatibility matrix with a pass/fail report";
          };
          default = self.apps.${system}.test-matrix;
        });
    };
}
