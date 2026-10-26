# Linux packaging for the existing public Rot and Light source tree.
# Keep its native godot/ + target/{debug,release} layout; change no game data.
{ source, system }:
let
  pkgs = source.inputs.nixpkgs.legacyPackages.${system};
  buildPkgs = source.inputs.nixpkgs.legacyPackages.x86_64-linux;
  lib = pkgs.lib;
  sourceRoot = /. + builtins.unsafeDiscardStringContext source.outPath;
  rustSource = lib.fileset.toSource {
    root = sourceRoot;
    fileset = lib.fileset.unions [
      (sourceRoot + "/Cargo.toml")
      (sourceRoot + "/Cargo.lock")
      (sourceRoot + "/crates")
    ];
  };
  bindingFor =
    packages:
    packages.rustPlatform.buildRustPackage {
      pname = "rot-and-light-godot";
      version = "0.0.0";
      src = rustSource;
      cargoLock.lockFile = sourceRoot + "/Cargo.lock";
      cargoBuildFlags = [
        "-p"
        "rot-and-light-godot"
      ];
      doCheck = false;
    };
  binding = bindingFor pkgs;
  importBinding = bindingFor buildPkgs;
  godotSource = lib.fileset.toSource {
    root = sourceRoot + "/godot";
    fileset = lib.fileset.difference (sourceRoot + "/godot") (
      lib.fileset.maybeMissing (sourceRoot + "/godot/.godot")
    );
  };
  editorSettings = buildPkgs.writeText "rot-and-light-editor-settings.tres" ''
    [gd_resource type="EditorSettings" format=3]
    [resource]
    export/android/shutdown_adb_on_exit = false
  '';
  imported =
    buildPkgs.runCommand "rot-and-light-imported-project"
      {
        nativeBuildInputs = [ buildPkgs.godot_4 ];
      }
      ''
        export HOME="$TMPDIR/home"
        export XDG_CONFIG_HOME="$HOME/config"
        export XDG_DATA_HOME="$HOME/data"
        export XDG_CACHE_HOME="$HOME/cache"
        mkdir -p "$XDG_CONFIG_HOME/godot" "$XDG_DATA_HOME" "$XDG_CACHE_HOME"
        cp ${editorSettings} "$XDG_CONFIG_HOME/godot/editor_settings-4.7.tres"
        mkdir -p source/godot source/target/debug source/target/release
        cp -r ${godotSource}/. source/godot/
        chmod -R u+w source
        cp ${importBinding}/lib/librot_and_light_godot.so source/target/debug/
        cp ${importBinding}/lib/librot_and_light_godot.so source/target/release/
        godot --headless --editor --path source/godot --import --quit > import.log 2>&1
        cat import.log
        if grep -E 'SCRIPT ERROR:|^ERROR:' import.log; then exit 1; fi
        test -f source/godot/.godot/global_script_class_cache.cfg
        cp -r source/godot "$out"
      '';
  game =
    pkgs.runCommand "rot-and-light"
      {
        meta.mainProgram = "rot-and-light";
        passthru = {
          inherit binding imported;
          runtime = pkgs.godot_4;
        };
      }
      ''
        mkdir -p "$out/share/rot-and-light/target/debug" "$out/share/rot-and-light/target/release"
        cp -r ${imported} "$out/share/rot-and-light/godot"
        chmod -R u+w "$out/share/rot-and-light"
        cp ${binding}/lib/librot_and_light_godot.so "$out/share/rot-and-light/target/debug/"
        cp ${binding}/lib/librot_and_light_godot.so "$out/share/rot-and-light/target/release/"
        mkdir -p "$out/share/doc/rot-and-light" "$out/bin"
        cp ${sourceRoot + "/LICENSE"} "$out/share/doc/rot-and-light/LICENSE"
        cp ${sourceRoot + "/THIRD_PARTY_NOTICES.md"} "$out/share/doc/rot-and-light/THIRD_PARTY_NOTICES.md"
        printf '%s\n' '#!${pkgs.runtimeShell}' \
          'exec ${pkgs.godot_4}/bin/godot --path '"$out"'/share/rot-and-light/godot "$@"' \
          > "$out/bin/rot-and-light"
        chmod +x "$out/bin/rot-and-light"
      '';
in
game
