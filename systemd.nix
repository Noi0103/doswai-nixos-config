{
  config,
  pkgs,
  lib,
  ...
}:
{
  # TODO set paths
  # nextcloud folders
  # nextcloud database
  # nginx website
  # gitlab folders
  # gitlab database

  # nextcloud
  systemd.timers."backup-routine-nextcloud" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      Unit = "backup-nextcloud-maintenance-on.service";
      OnCalendar = "Wed *-*-* 23:59:00";
      Persistent = true;
    };
  };
  # start maintenance mode
  systemd.services."backup-nextcloud-maintenance-on" = {
    script = ''
      set -eu
      nextcloud-occ maintenance:mode --on
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "nextcloud";
    };
    onSuccess = [ "backup-nextcloud-files.service" ];
    path = [ config.services.nextcloud.occ ];
  };
  # nextcloud dir rsync
  systemd.services."backup-nextcloud-files" = {
    script = ''
      set -eu  
      rsync --delete-after -Aavx /mnt/main/nextcloud /mnt/backup/nextcloud
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    onSuccess = [ "backup-nextcloud-database.service" ];
    path = [ pkgs.rsync ];
  };
  # databse dump
  systemd.services."backup-nextcloud-database" = {
    script = ''
      set -eu  
      pg_dump nextcloud -U postgres -f /var/lib/postgresql/nextcloud-database.sql
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
    };
    onSuccess = [ "backup-nextcloud-mv-pg_dump.service" ];
    path = [ config.services.postgresql.package ];
  };
  # moving dump into backup folder
  systemd.services."backup-nextcloud-mv-pg_dump" = {
    script = ''
      set -eu  
      mv /var/lib/postgresql/nextcloud-database.sql /mnt/wd5/WD5/100-Backup/140-Nextcloud/nextcloud-database.sql
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    onSuccess = [ "backup-nextcloud-maintenance-off.service" ];
    path = [ config.services.postgresql.package ];
  };
  # stop maintenance mode
  systemd.services."backup-nextcloud-maintenance-off" = {
    script = ''
      set -eu
      nextcloud-occ maintenance:mode --off
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "nextcloud";
    };
    path = [ config.services.nextcloud.occ ];
  };

  # gitlab
  systemd.timers."backup-routine-gitlab" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      Unit = "<gitlab maintenance mode>.service";
      OnCalendar = "Tue *-*-* 23:59:00";
      Persistent = true;
    };
  };

}
