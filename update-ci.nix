{
  coq-nix-toolbox,
  coreutils,
  json2yaml,
  jq,
  pkgs,
  selfPath,
  writeShellScript,
  writeText,
  ...
}:

let
  inherit (pkgs) lib;
  inherit (lib.strings) escapeNixString escapeShellArg escape;

  # Nixpkgs to be used by the toolbox.
  # Rocq packages are injected via an overlay so that the coq-nix-toolbox will use local package definitions.
  # This a hack, a proper fix would be to make changes to the toolbox.
  #
  # It takes as argument a location for this flake.
  nixpkgsEntrypointToolbox = selfPath: ''
    { system, ... }@args:
    let
      rocqpkgs = builtins.getFlake ${escapeNixString selfPath};
      inherit (rocqpkgs.inputs) nixpkgs;
    in
    import nixpkgs {
      inherit system;
      overlays = [
        (_: _: rocqpkgs.packages.''${system})
      ];
    }
    // args
  '';

  evaluateToolbox =
    args:
    import coq-nix-toolbox (
      {
        src = ./.;
        inherit (pkgs.stdenv.hostPlatform) system;

        nixpkgs = writeText "nixpkgs.nix" (nixpkgsEntrypointToolbox selfPath);

        # This attribute is set by nix-shell.
        inNixShell = true;
      }
      // args
    );

  inherit (evaluateToolbox { }) bundles;

  actionFor =
    bundle:
    (evaluateToolbox {
      inherit bundle;
    }).jsonActionFile;
in
writeShellScript "update-ci" ''
  ${lib.getExe' coreutils "rm"} -rf .github/workflows/nix-action*.yml
  ${lib.getExe' coreutils "mkdir"} -p .github/workflows

  ${lib.concatStringsSep "\n" (
    lib.map (
      bundle:
      let
        # TODO: this does not seem to take into account the value of bundle?
        actionFile = actionFor bundle;
      in
      ''
        # Convert the action file generated as JSON by the toolbox into YAML to store it.
        # A new step is inserted to generate:
        # - /tmp/nixpkgs-toolbox-entry.nix, containing the nixpkgs entrypoint expression to be used by the toolbox;
        # - /tmp/nix-build.sh, in order to factorize our new options to nix-build
        # There is an extra fix-up step because it expects default.nix, a thin wrapper around coq-nix-toolbox, to exist in the repository.
        cat ${lib.escapeShellArg actionFile} \
          | ${lib.getExe jq} ${escapeShellArg ''
            walk(if type == "object" and has("run") then
              .run |= gsub("nix-build"; "/tmp/builder.sh")
              else . end
            )
          ''} \
          | ${lib.getExe jq} ${lib.escapeShellArg ''
            .jobs[].steps |= [ {
              name: "Creating the nixpkgs entrypoint expression file and builder script",
              run: "echo ${
                # A complicated escaping logic because we need to escape:
                # - for jq's string litteral
                # - for the shell echo command
                escape [ "\"" "\\" ] (
                  escapeShellArg (
                    # Here, using selfPath does not make sense because
                    # 1. selfPath is a path to the Nix store, which will not be present on the runner machine.
                    # 2. selfPath is pinned to the flake before the workflow files we are generating are present;
                    # Thankfully the CI is run in impure mode, meaning we can just refer to the checked-out repo via its path.
                    # However, Nix does not support relative path when retrieving a flake. We use a dummy string and we'll replace it right after.
                    nixpkgsEntrypointToolbox "placeholder-flake-path"
                  )
                )
              } > /tmp/nixpkgs-toolbox-entry.nix
              sed -i \"s|placeholder-flake-path|$(readlink -f .)|\" /tmp/nixpkgs-toolbox-entry.nix

              echo ${
                escape [ "\"" "\\" ] (escapeShellArg ''
                  #!/bin/bash
                  nix-build \
                    --extra-experimental-features flakes \
                    --expr "import (builtins.getFlake '''$(readlink -f .)''').inputs.coq-nix-toolbox" \
                    --arg src ./. \
                    --arg nixpkgs /tmp/nixpkgs-toolbox-entry.nix \
                    "$@"
                '')
              } > /tmp/builder.sh

              chmod +x /tmp/builder.sh",
            } ] + .
          ''} \
          | ${lib.getExe json2yaml} \
          > .github/workflows/nix-action-${bundle}.yml
      ''
    ) bundles
  )}
''
