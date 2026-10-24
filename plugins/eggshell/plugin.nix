{ eggshellPackage }:
{
  packages.eggshell = eggshellPackage;
  # The runner's `program` key names this file.
  files.eggshell = "${eggshellPackage}/bin/eggshell";
}
