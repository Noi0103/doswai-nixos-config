{
  config,
  pkgs,
  lib,
  ...
}:
{
  # sections from here are copied from the wiki and a c3d2 config template i once received
  # https://wiki.nixos.org/wiki/NixOS_on_ARM/Raspberry_Pi_4

  hardware.enableRedistributableFirmware = true;

  # do not log to sd flash storage
  services.journald.extraConfig = ''
    Storage=volatile
  '';

  # 4GB is not much and large fileuploads might be an issue (e.g. services.nextcloud.maxUploadSize)
  zramSwap = {
    enable = true;
  };
  boot = {
    kernelParams = lib.mkForce [
      "panic=5"
      "oops=panic"
    ];
  };
  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];
}
