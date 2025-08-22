{
  config,
  pkgs,
  lib,
  ...
}:
{
  # TODO nginx website files if not flake input via git repo
  # TODO backend executable file if not flake input via git repo

  # nextcloud
  # will alert the maintenance mode as on in the browser (or be unable to sync as client)
  # if any part of this sequence failed, that will be the signal to action
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
      mkdir -p /mnt/backup/nextcloud/home
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
      rsync --delete-after -Aavx /mnt/operation/nextcloud/home /mnt/backup/nextcloud/home
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    onSuccess = [ "backup-nextcloud-database.service" ];
    path = [ pkgs.rsync ];
  };
  # databse dump
  systemd.services."backup-nextcloud-create-pg_dump" = {
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
      mv /var/lib/postgresql/nextcloud-database.sql /mnt/backup/nextcloud/database.sql
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
}
