{
  config,
  pkgs,
  lib,
  ...
}:
{
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";

  # some tools that might come in handy waiting for the ad-hoc shell build
  environment.systemPackages = with pkgs; [
    git
    btop
    lm_sensors
    age
    fastfetch
    smartmontools
  ];
}
