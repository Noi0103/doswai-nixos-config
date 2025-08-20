{
  config,
  pkgs,
  lib,
  ...
}:
{
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";

  environment.systemPackages = with pkgs; [
    git
    btop
    lm_sensors
    age
    neofetch
    smartmontools
  ];
}
