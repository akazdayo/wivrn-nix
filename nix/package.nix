{ pkgs, sources }:
pkgs.wivrn.overrideAttrs (
  finalAttrs: oldAttrs: {
    inherit (sources) version;

    src = pkgs.fetchFromGitHub {
      owner = "WiVRn";
      repo = "WiVRn";
      rev = "v${sources.version}";
      hash = sources.wivrnHash;
    };

    monado = pkgs.applyPatches {
      inherit (oldAttrs.monado) patches postPatch;

      src = pkgs.fetchFromGitLab {
        domain = "gitlab.freedesktop.org";
        owner = "monado";
        repo = "monado";
        rev = sources.monadoRev;
        hash = sources.monadoHash;
      };
    };

    # The nixpkgs updater only knows about the primary source hash. Remove it so
    # it cannot produce an update without refreshing the matching Monado source.
    passthru = builtins.removeAttrs (oldAttrs.passthru or { }) [ "updateScript" ];

    meta = oldAttrs.meta // {
      changelog = "https://github.com/WiVRn/WiVRn/releases/tag/v${finalAttrs.version}";
    };
  }
)
