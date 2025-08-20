{
  config,
  pkgs,
  lib,
  ...
}:
{
  # TODO
  # nextcloud folders
  # nextcloud database
  # nginx website
  # gitlab folders
  # gitlab database
  systemd.timers."backup-routine" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      Unit = "backup-nextcloud-maintenance-on.service";
      OnCalendar = "Wed *-*-* 23:59:00";
      Persistent = true;
    };
  };
  systemd.services."backup-nextcloud-files" = {
    script = ''
      set -eu  
      rsync --delete-after -Aavx /mnt/sandisk/nextcloud /mnt/wd5/WD5/100-Backup/140-Nextcloud/
      rsync --delete-after -Aavx /var/lib/calibre-server /mnt/wd5/WD5/100-Backup/141-Calibre-Library/
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    onSuccess = [ "backup-nextcloud-database.service" ];
    path = [ pkgs.rsync ];
  };
}
