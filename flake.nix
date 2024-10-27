{
  description = "Application packaged using poetry2nix";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # see https://github.com/nix-community/poetry2nix/tree/master#api for more functions and examples.
        pkgs = import nixpkgs {
          inherit system;
        };
        inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryApplication;

        python = pkgs.python310;

        myapp = mkPoetryApplication {
          projectDir = ./.;
          preferWheels = true;
          inherit python;
        };

        shellHook = ''
          export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring
        '';
      in
      {
        apps = {
          # they're already all exposed via nix-develop
          # # but this lets us nix-run
          flight-server = {
            type = "app";
            program = "${myapp}/bin/flight-server";
          };
          flight-client = {
            type = "app";
            program = "${myapp}/bin/flight-client";
          };
          flight-data-bootstrap = {
            type = "app";
            program = "${myapp}/bin/flight-data-bootstrap";
          };
        };
        packages.default = myapp;
        devShells = {

          myShell = pkgs.mkShell {
            packages = [
              myapp
              pkgs.poetry
            ];
            inherit shellHook;
          };

          # Shell for app dependencies.
          #
          #     nix develop
          #
          # Use this shell for developing your app.
          inputs = pkgs.mkShell {
            inputsFrom = [ myapp ];
          };

          # Shell for poetry.
          #
          #     nix develop .#poetry
          #
          # Use this shell for changes to pyproject.toml and poetry.lock.
          poetry = pkgs.mkShell {
            packages = [ pkgs.poetry ];
            inherit shellHook;
          };

          default = self.devShells.${system}.myShell;
        };
        legacyPackages = pkgs;
      }
    );
}
