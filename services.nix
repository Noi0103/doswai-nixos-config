{
  config,
  pkgs,
  lib,
  ...
}:
let
  domain = "doswai.com";
  maxUploadSize = "5G";
in
{
  # services excludes openssh and fail2ban

  ## webserver and proxy
  services.nginx = {
    enable = true;

    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    clientMaxBodySize = "${maxUploadSize}"; # when uploading large files on nextcloud

    virtualHosts."${domain}" = {
      forceSSL = false;
      enableACME = false;
      globalRedirect = "www.${domain}";
    };
    virtualHosts."www.${domain}" = {
      forceSSL = true;
      enableACME = true;
      root = "/var/www/${domain}";
    };
    virtualHosts."cloud.${domain}" = {
      forceSSL = true;
      enableACME = true;
    };
  };
  networking.firewall.allowedTCPPorts = [
    80 # nginx
    443 # nginx
  ];

  # letsencrypt certificate
  security.acme = {
    acceptTerms = true;
    defaults.email = ""; # notification when cert threatens to expire
  };

  ## nextcloud
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud31;
    https = true;
    hostName = "cloud.${domain}";
    settings = {
      trusted_domain = [ "cloud.${domain}" ];
      trusted_proxies = [ "127.0.0.1" ];
    };

    home = "/path/to/datadir/nextcloud"; # create folder nextcloud >  chown it to nextcloud:nextcloud > chmod it to 777
    maxUploadSize = "${maxUploadSize}"; # this is a per file and the other setting besides nginx clientMaxBodySize

    database.createLocally = true;
    config = {
      adminuser = "alice";
      adminpassFile = config.sops.secrets."nextcloud-admin-init".path;
      dbtype = "pgsql";
    };

    extraAppsEnable = true;
    autoUpdateApps.enable = true;
    autoUpdateApps.startAt = "05:00:00";
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) ; # contacts calendar tasks; # the default stuff can be expanded
    };
  };

  ## gitlab
  services.gitlab = {
    port = 8080;
    # TODO
  };
}
