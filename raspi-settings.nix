{
  config,
  pkgs,
  lib,
  ...
}:
{
  hardware.enableRedistributableFirmware = true;
  services.journald.extraConfig = ''
    Storage=volatile
  ''; # Do not log to sd flash storage:
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
