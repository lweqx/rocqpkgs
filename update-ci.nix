{
  coq-nix-toolbox,
  coreutils,
  json2yaml,
  jq,
  pkgs,
  rocqpkgs,
  writeShellScript,
  writeText,
  ...
}:

let
  inherit (pkgs) lib;
  inherit (lib.strings) escapeNixString escapeShellArg escape;
  nixpkgs = pkgs.path;
  system = pkgs.stdenv.hostPlatform.system;

  # Nixpkgs to be used by the toolbox.
  # Rocq packages are injected via an overlay so that the coq-nix-toolbox will local package definitions.
  # This a hack, a proper fix would be to make changes to the toolbox.
  nixpkgsEntrypointToolbox = ''
    args:
    let
      rocqpkgs = builtins.getFlake ${escapeNixString rocqpkgs};
      system = ${escapeNixString system};
    in
    import ${nixpkgs} {
      inherit system;
      overlays = [
        (_: _: rocqpkgs.packages.''${system})
      ];
    }
    // args
  '';

  evaluateToolbox =
    args:
    import coq-nix-toolbox {
      src = ./.;
      inherit (pkgs.stdenv.hostPlatform) system;

      nixpkgs = writeText "nixpkgs.nix" nixpkgsEntrypointToolbox;

      # This attribute is set by nix-shell.
      inNixShell = true;
    }
    // args;

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
                escape [ "\"" "\\" ] (escapeShellArg nixpkgsEntrypointToolbox)
              } > /tmp/nixpkgs-toolbox-entry.nix

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
