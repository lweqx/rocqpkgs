{
  lib,
  stdenv,
  fetchurl,
  fetchzip,
  callPackage,
  newScope,
  ocamlPackages_4_14,
  ocamlPackages_5_5,
  fetchpatch,
  makeWrapper,
  coq2html,
}@args:
let
  lib = import ./build-support/extra-lib.nix { inherit (args) lib; };
in
let
  mkRocqPackages' =
    self: rocq-core:
    let
      callPackage = self.callPackage;
    in
    {
      inherit lib;
      rocqPackages = self // {
        __attrsFailEvaluation = true;
        recurseForDerivations = false;
      };

      metaFetch = import ./build-support/meta-fetch/default.nix {
        inherit
          lib
          stdenv
          fetchzip
          fetchurl
          ;
      };
      mkRocqDerivation = lib.makeOverridable (callPackage ./build-support { });

      coq = callPackage ./coq {
        ocamlPackages_4_09 = null;
        ocamlPackages_4_10 = null;
        ocamlPackages_4_12 = null;
        inherit ocamlPackages_4_14 ocamlPackages_5_5;
        inherit (rocq-core) version;
      };

      mkCoqDerivation =
        args:
        self.mkRocqDerivation (
          {
            useCoq = true;
            namePrefix = [ "coq" ];
          }
          // args
        );

      rocq-core = rocq-core.overrideAttrs (oldAttrs: {
        passthru = (oldAttrs.passthru or { }) // {
          withPackages =
            f:
            (callPackage ../applications/science/logic/coq/with-packages.nix {
              coq = rocq-core;
            })
              (f self);
        };
      });

      contribs = lib.recurseIntoAttrs (callPackage ./pkgs/contribs { });

      aac-tactics = callPackage ./pkgs/aac-tactics { };
      addition-chains = callPackage ./pkgs/addition-chains { };
      async-test = callPackage ./pkgs/async-test { };
      atbr = callPackage ./pkgs/atbr { };
      autosubst = callPackage ./pkgs/autosubst { };
      autosubst-ocaml = callPackage ./pkgs/autosubst-ocaml { };
      bbv = callPackage ./pkgs/bbv { };
      bignums = callPackage ./pkgs/bignums { };
      CakeMLExtraction = callPackage ./pkgs/CakeMLExtraction { };
      category-theory = callPackage ./pkgs/category-theory { };
      ceres = callPackage ./pkgs/ceres { };
      ceres-bs = callPackage ./pkgs/ceres-bs { };
      CertiRocq = callPackage ./pkgs/CertiRocq { };
      Cheerios = callPackage ./pkgs/Cheerios { };
      coinduction = callPackage ./pkgs/coinduction { };
      CoLoR = callPackage ./pkgs/CoLoR { };
      compcert = callPackage ./pkgs/compcert {
        inherit
          fetchpatch
          makeWrapper
          coq2html
          lib
          stdenv
          ;
      };
      ConCert = callPackage ./pkgs/ConCert { };
      coq-bits = callPackage ./pkgs/coq-bits { };
      coq-hammer = callPackage ./pkgs/coq-hammer { };
      coq-hammer-tactics = callPackage ./pkgs/coq-hammer/tactics.nix { };
      CoqMatrix = callPackage ./pkgs/coq-matrix { };
      coq-haskell = callPackage ./pkgs/coq-haskell { };
      coq-lsp = callPackage ./pkgs/coq-lsp { };
      coq-record-update = callPackage ./pkgs/coq-record-update { };
      coq-tactical = callPackage ./pkgs/coq-tactical { };
      coqeal = callPackage ./pkgs/coqeal (
        lib.optionalAttrs (lib.versions.range "8.13" "8.14" self.coq.coq-version) {
          bignums = self.bignums.override { version = "${self.coq.coq-version}.0"; };
        }
      );
      coqhammer = callPackage ./pkgs/coqhammer { };
      coqide = callPackage ./pkgs/coqide { };
      coqprime = callPackage ./pkgs/coqprime { };
      coqtail-math = callPackage ./pkgs/coqtail-math { };
      coquelicot = callPackage ./pkgs/coquelicot { };
      coqutil = callPackage ./pkgs/coqutil { };
      coqfmt = callPackage ./pkgs/coqfmt { };
      corn = callPackage ./pkgs/corn { };
      deriving = callPackage ./pkgs/deriving { };
      dpdgraph = callPackage ./pkgs/dpdgraph { };
      ElmExtraction = callPackage ./pkgs/ElmExtraction { };
      equations = callPackage ./pkgs/equations { };
      ExtLib = callPackage ./pkgs/ExtLib { };
      extructures = callPackage ./pkgs/extructures { };
      fcsl-pcm = callPackage ./pkgs/fcsl-pcm { };
      flocq = callPackage ./pkgs/flocq { };
      fourcolor = callPackage ./pkgs/fourcolor { };
      gaia = callPackage ./pkgs/gaia { };
      gaia-hydras = callPackage ./pkgs/gaia-hydras { };
      gappalib = callPackage ./pkgs/gappalib { };
      goedel = callPackage ./pkgs/goedel { };
      graph-theory = callPackage ./pkgs/graph-theory { };
      heq = callPackage ./pkgs/heq { };
      hierarchy-builder = callPackage ./pkgs/hierarchy-builder { };
      high-school-geometry = callPackage ./pkgs/high-school-geometry { };
      HoTT = callPackage ./pkgs/HoTT { };
      http = callPackage ./pkgs/http { };
      hydra-battles = callPackage ./pkgs/hydra-battles { };
      interval = callPackage ./pkgs/interval { };
      InfSeqExt = callPackage ./pkgs/InfSeqExt { };
      iris = callPackage ./pkgs/iris { };
      iris-named-props = callPackage ./pkgs/iris-named-props { };
      itauto = callPackage ./pkgs/itauto { };
      ITree = callPackage ./pkgs/ITree { };
      itree-io = callPackage ./pkgs/itree-io { };
      jasmin = callPackage ./pkgs/jasmin { };
      json = callPackage ./pkgs/json { };
      lemma-overloading = callPackage ./pkgs/lemma-overloading { };
      LibHyps = callPackage ./pkgs/LibHyps { };
      libvalidsdp = self.validsdp.libvalidsdp;
      ltac2 = callPackage ./pkgs/ltac2 { };
      math-classes = callPackage ./pkgs/math-classes { };
      mathcomp = callPackage ./pkgs/mathcomp { };
      ssreflect = self.mathcomp.ssreflect;
      mathcomp-boot = self.mathcomp.boot;
      mathcomp-order = self.mathcomp.order;
      mathcomp-ssreflect = self.mathcomp.ssreflect;
      mathcomp-finite-group = self.mathcomp.finite-group;
      mathcomp-fingroup = self.mathcomp.finite-group;
      mathcomp-algebra = self.mathcomp.algebra;
      mathcomp-solvable = self.mathcomp.solvable;
      mathcomp-field = self.mathcomp.field;
      mathcomp-group-representation = self.mathcomp.group-representation;
      mathcomp-character = self.mathcomp.group-representation;
      mathcomp-abel = callPackage ./pkgs/mathcomp-abel { };
      mathcomp-algebra-tactics = callPackage ./pkgs/mathcomp-algebra-tactics { };
      mathcomp-analysis = callPackage ./pkgs/mathcomp-analysis { };
      mathcomp-analysis-stdlib = self.mathcomp-analysis.analysis-stdlib;
      mathcomp-apery = callPackage ./pkgs/mathcomp-apery { };
      mathcomp-bigenough = callPackage ./pkgs/mathcomp-bigenough { };
      mathcomp-classical = self.mathcomp-analysis.classical;
      mathcomp-experimental-reals = self.mathcomp-analysis.experimental-reals;
      mathcomp-finmap = callPackage ./pkgs/mathcomp-finmap { };
      mathcomp-infotheo = callPackage ./pkgs/mathcomp-infotheo { };
      mathcomp-real-closed = callPackage ./pkgs/mathcomp-real-closed { };
      mathcomp-reals = self.mathcomp-analysis.reals;
      mathcomp-reals-stdlib = self.mathcomp-analysis.reals-stdlib;
      mathcomp-tarjan = callPackage ./pkgs/mathcomp-tarjan { };
      mathcomp-word = callPackage ./pkgs/mathcomp-word { };
      mathcomp-zify = callPackage ./pkgs/mathcomp-zify { };
      MenhirLib = callPackage ./pkgs/MenhirLib { };
      metacoq = callPackage ./pkgs/metacoq { };
      metacoq-utils = self.metacoq.utils;
      metacoq-common = self.metacoq.common;
      metacoq-template-coq = self.metacoq.template-coq;
      metacoq-pcuic = self.metacoq.pcuic;
      metacoq-safechecker = self.metacoq.safechecker;
      metacoq-template-pcuic = self.metacoq.template-pcuic;
      metacoq-erasure = self.metacoq.erasure;
      metacoq-quotation = self.metacoq.quotation;
      metacoq-safechecker-plugin = self.metacoq.safechecker-plugin;
      metacoq-erasure-plugin = self.metacoq.erasure-plugin;
      metacoq-translations = self.metacoq.translations;
      metalib = callPackage ./pkgs/metalib { };
      metarocq = callPackage ./pkgs/metarocq { };
      metarocq-utils = self.metarocq.utils;
      metarocq-common = self.metarocq.common;
      metarocq-template-rocq = self.metarocq.template-rocq;
      metarocq-pcuic = self.metarocq.pcuic;
      metarocq-safechecker = self.metarocq.safechecker;
      metarocq-template-pcuic = self.metarocq.template-pcuic;
      metarocq-erasure = self.metarocq.erasure;
      metarocq-quotation = self.metarocq.quotation;
      metarocq-safechecker-plugin = self.metarocq.safechecker-plugin;
      metarocq-erasure-plugin = self.metarocq.erasure-plugin;
      metarocq-translations = self.metarocq.translations;
      micromega-plugin = callPackage ./pkgs/micromega-plugin { };
      mtac2 = callPackage ./pkgs/mtac2 { };
      multinomials = callPackage ./pkgs/multinomials { };
      odd-order = callPackage ./pkgs/odd-order { };
      Ordinal = callPackage ./pkgs/Ordinal { };
      paco = callPackage ./pkgs/paco { };
      paramcoq = callPackage ./pkgs/paramcoq { };
      parsec = callPackage ./pkgs/parsec { };
      parseque = callPackage ./pkgs/parseque { };
      pocklington = callPackage ./pkgs/pocklington { };
      QuickChick = callPackage ./pkgs/QuickChick { };
      reglang = callPackage ./pkgs/reglang { };
      relation-algebra = callPackage ./pkgs/relation-algebra { };
      rewriter = callPackage ./pkgs/rewriter { };
      rocq-elpi = callPackage ./pkgs/rocq-elpi { };
      coq-elpi = self.rocq-elpi;
      rocqnavi = callPackage ./pkgs/rocqnavi { };
      RustExtraction = callPackage ./pkgs/RustExtraction { };
      semantics = callPackage ./pkgs/semantics { };
      serapi = callPackage ./pkgs/serapi { };
      simple-io = callPackage ./pkgs/simple-io { };
      smpl = callPackage ./pkgs/smpl { };
      smtcoq = callPackage ./pkgs/smtcoq { };
      ssprove = callPackage ./pkgs/ssprove { };
      stalmarck-tactic = callPackage ./pkgs/stalmarck { };
      stalmarck = self.stalmarck-tactic.stalmarck;
      stdlib = callPackage ./pkgs/stdlib { };
      stdpp = callPackage ./pkgs/stdpp { };
      StructTact = callPackage ./pkgs/StructTact { };
      tlc = callPackage ./pkgs/tlc { };
      topology = callPackage ./pkgs/topology { };
      trakt = callPackage ./pkgs/trakt { };
      TypedExtraction = callPackage ./pkgs/TypedExtraction { };
      TypedExtraction-common = self.TypedExtraction.common;
      TypedExtraction-elm = self.TypedExtraction.elm;
      TypedExtraction-rust = self.TypedExtraction.rust;
      TypedExtraction-plugin = self.TypedExtraction.plugin;
      unicoq = callPackage ./pkgs/unicoq { };
      validsdp = callPackage ./pkgs/validsdp { };
      vcfloat = callPackage ./pkgs/vcfloat (
        lib.optionalAttrs (lib.versions.range "8.16" "8.18" self.coq.version) {
          interval = self.interval.override { version = "4.9.0"; };
        }
      );
      Velisarios = callPackage ./pkgs/Velisarios { };
      Verdi = callPackage ./pkgs/Verdi { };
      verified-extraction = callPackage ./pkgs/verified-extraction { };
      Vpl = callPackage ./pkgs/Vpl { };
      VplTactic = callPackage ./pkgs/VplTactic { };
      vsrocq-language-server = callPackage ./pkgs/vsrocq-language-server { };
      VST = callPackage ./pkgs/VST (
        (lib.optionalAttrs (lib.versionAtLeast self.coq.version "8.14") {
          compcert = self.compcert.override {
            version =
              with lib.versions;
              lib.switch self.coq.version [
                {
                  case = range "8.15" "8.18";
                  out = "3.13.1";
                }
                {
                  case = isEq "8.14";
                  out = "3.11";
                }
              ] null;
          };
        })
        // (lib.optionalAttrs (lib.versions.isEq self.coq.coq-version "8.13") {
          ITree = self.ITree.override {
            version = "4.0.0";
            paco = self.paco.override { version = "4.1.2"; };
          };
        })
      );
      wasmcert = callPackage ./pkgs/wasmcert { };
      waterproof = callPackage ./pkgs/waterproof { };
      zorns-lemma = callPackage ./pkgs/zorns-lemma { };

      filterPackages = doesFilter: if doesFilter then filterRocqPackages self else self;
    };

  filterRocqPackages =
    set:
    lib.listToAttrs (
      lib.concatMap (
        name:
        let
          v = set.${name} or null;
        in
        lib.optional (!v.meta.rocqFilter or false) (
          lib.nameValuePair name (
            if lib.isAttrs v && v.recurseForDerivations or false then filterRocqPackages v else v
          )
        )
      ) (lib.attrNames set)
    );
  mkRocq =
    version:
    callPackage ./rocq-core {
      inherit
        version
        ocamlPackages_4_14
        ocamlPackages_5_5
        ;
    };
in
rec {

  /*
    The function `mkRocqPackages` takes as input a derivation for Rocq and produces
    a set of libraries built with that specific Rocq. More libraries are known to
    this function than what is compatible with that version of Rocq. Therefore,
    libraries that are not known to be compatible are removed (filtered out) from
    the resulting set. For meta-programming purposes (inspecting the derivations
    rather than building the libraries) this filtering can be disabled by setting
    a `dontFilter` attribute into the Rocq derivation.
  */
  mkRocqPackages =
    rocq-core:
    let
      self = lib.makeScope newScope (lib.flip mkRocqPackages' rocq-core);
    in
    self.filterPackages (!rocq-core.dontFilter or false);

  rocq-core_9_0 = mkRocq "9.0";
  rocq-core_9_1 = mkRocq "9.1";
  rocq-core_9_2 = mkRocq "9.2";
  rocq-core_9_3 = mkRocq "9.3";

  rocqPackages_9_0 = mkRocqPackages rocq-core_9_0;
  rocqPackages_9_1 = mkRocqPackages rocq-core_9_1;
  rocqPackages_9_2 = mkRocqPackages rocq-core_9_2;
  rocqPackages_9_3 = mkRocqPackages rocq-core_9_3;

  rocqPackages = lib.recurseIntoAttrs rocqPackages_9_1;
  rocq-core = rocqPackages.rocq-core;
}
