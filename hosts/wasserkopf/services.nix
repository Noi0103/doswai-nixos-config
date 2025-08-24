{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
let
  maxUploadSize = "5G";
  domain = "crabdance.com";
  statefulDir = "/mnt/operation";
  backupDir = "/mnt/backup";
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

    virtualHosts."dummkopf.${domain}" = {
      forceSSL = true;
      enableACME = true;
      root = "${inputs.doswai-frontend.packages."x86_64-linux".frontend}/";
      locations."/test".return = "200";
    };
    virtualHosts."cybernetic.crabdance.com" = {
      forceSSL = true;
      enableACME = true;
      locations."/".proxyPass = "http://127.0.0.1:20001";
    };

    #virtualHosts."${config.services.nextcloud.hostName}" = {
    #  forceSSL = true;
    #  enableACME = true;
    # nextcloud module configures this virtualHost
    #};
    #virtualHosts."${config.services.gitlab.host}" = {
    #  forceSSL = true;
    #  enableACME = true;
    #  locations."/".proxyPass = "http://127.0.0.1:8080";
    #};
    #virtualHosts."${config.services.cryptpad.settings.httpSafeOrigin}" = {
    #  forceSSL = true;
    #  enableACME = true;
    #  locations."/".proxyPass = "http://127.0.0.1:3000";
    #};
  };
  networking.firewall.allowedTCPPorts = [
    80 # nginx
    443 # nginx
  ];

  # letsencrypt certificate
  security.acme = {
    acceptTerms = true;
    defaults.email = "paul.dennis2@proton.me"; # notification when cert threatens to expire
  };

  ## nextcloud
  services.nextcloud = {
    enable = false;
    package = pkgs.nextcloud31;
    https = true;
    hostName = "nextcloud.wasserkopf.${domain}";
    settings = {
      trusted_domain = [ "${config.services.nextcloud.hostName}" ];
      trusted_proxies = [ "127.0.0.1" ];
    };

    home = "${statefulDir}/nextcloud"; # create folder nextcloud >  chown it to nextcloud:nextcloud > chmod it to 777
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
      inherit (config.services.nextcloud.package.packages.apps) calendar; # the default stuff can be expanded
    };
  };

  ## gitlab
  services.gitlab = {
    enable = false;
    port = 8080;
    statePath = "${statefulDir}/gitlab";
    initialRootEmail = "alice@local.host";
    initialRootPasswordFile = config.sops.secrets."gitlab-admin-init".path;
    host = "gitlab.wasserkopf.${domain}";
    databaseCreateLocally = true;
    # https://docs.gitlab.com/administration/backup_restore/backup_gitlab/
    backup = {
      startAt = "03:00";
      skip = [ "artifacts" ];
      path = /mnt/backup;
      keepTime = 24 * 7;
    };
  };

  ## cryptpad
  services.cryptpad = {
    enable = false;
    settings = {
      httpPort = 3000;
      httpUnsafeOrigin = "http://127.0.0.1";
      httpSafeOrigin = "https://cryptpad.wasserkopf.${domain}";
      adminKeys = [ ];
    };
    # TODO missing backups
  };
}
