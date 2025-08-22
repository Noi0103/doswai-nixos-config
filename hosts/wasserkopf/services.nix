{
  config,
  pkgs,
  lib,
  ...
}:
let
  maxUploadSize = "5G";
  domain = "doswai.com";
in
{
  # services excludes openssh and fail2ban

  ## webserver and proxy
  services.nginx = {
    enable = false;

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
    virtualHosts."${config.services.nextcloud.hostName}" = {
      forceSSL = true;
      enableACME = true;
      # nextcloud module configures this virtualHost
    };
    virtualHosts."${config.services.gitlab.host}" = {
      forceSSL = true;
      enableACME = true;
      locations."/".proxyPass = "http://127.0.0.1:8080";
    };
  };
  networking.firewall.allowedTCPPorts = [
    80 # nginx
    443 # nginx
  ];

  # letsencrypt certificate
  security.acme = {
    acceptTerms = true;
    # TODO
    defaults.email = ""; # notification when cert threatens to expire
  };

  ## nextcloud
  services.nextcloud = {
    enable = false;
    package = pkgs.nextcloud31;
    https = true;
    hostName = "cloud.doswai.com";
    settings = {
      trusted_domain = [ "${config.services.nextcloud.hostName}" ];
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
    enable = false;
    port = 8080;
    statePath = "/var/gitlab/state";
    initialRootEmail = "alice@local.host";
    initialRootPasswordFile = config.sops.secrets."gitlab-admin-init".path;
    host = "git.${domain}";
    databaseCreateLocally = true;
    # https://docs.gitlab.com/administration/backup_restore/backup_gitlab/
    backup = {
      startAt = "03:00";
      skip = [ "artifacts" ];
      path = /mnt/backup;
      keepTime = 24 * 7;
    };
  };
}
