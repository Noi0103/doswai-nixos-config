{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    openFirewall = true;
    banner = "doswai running NixOS.\n";
    settings.PasswordAuthentication = false;
  };

  # this is set rather extreme; wrongly configured nixos-rebuild will block long
  services.fail2ban = {
    enable = true;
    bantime = "12h";
    bantime-increment.enable = true;
    bantime-increment.factor = "4";
  };

  # webserver
  services.nginx = {
    enable = true;

    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    clientMaxBodySize = "5G"; # when uploading large files on nextcloud

    virtualHosts."doswai.com" = {
      forceSSL = false;
      enableACME = false;
      globalRedirect = "www.doswai.com";
    };
    virtualHosts."www.doswai.com" = {
      forceSSL = true;
      enableACME = true;
      root = "/var/www/doswai.com";
    };
  };
  networking.firewall.allowedTCPPorts = [
    80 # nginx
    443 # nginx
  ];

  # letsencrypt certificate
  security.acme = {
    acceptTerms = true;
    defaults.email = "<doswai@gmail.com>"; # notification when threatens to expire
  };

  # multi-purpose cloud solution
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud31;
    https = true;
    hostName = "cloud.doswai.com";
    settings = {
      trusted_domain = [ "cloud.doswai.com" ];
      trusted_proxies = [ "127.0.0.1" ];
    };

    home = "/path/to/datadir/nextcloud"; # create folder nextcloud >  chown it to nextcloud:nextcloud > chmod it to 777
    maxUploadSize = "10G"; # this is a per file and the other setting besides nginx clientMaxBodySize

    database.createLocally = true;
    config = {
      adminuser = "doswai";
      adminpassFile = config.sops.secrets.nextcloud-admin.path;
      dbtype = "pgsql";
    };

    extraAppsEnable = true;
    autoUpdateApps.enable = true;
    autoUpdateApps.startAt = "05:00:00";
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) contacts calendar tasks; # TODO
    };
  };

  services.gitlab = {
    port = 8080;
    # TODO
  };
}
