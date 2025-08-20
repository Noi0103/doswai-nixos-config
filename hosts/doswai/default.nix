{
  config,
  pkgs,
  lib,
  ...
}:
{
  nixpkgs.hostPlatform = "aarch64-linux";
  networking.hostName = "doswai";

  # usb backup drive
  fileSystems."/mnt/drive" = {
    device = "/dev/disk/by-uuid/<uuid>";
    fsType = "ext4";
    options = [
      "nofail"
      "users"
    ];
  };

  # secret management
  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    age.keyFile = "/var/lib/sops-nix/key.txt";
    age.generateKey = true;

    defaultSopsFile = ../../secrets/doswai.yaml;
    defaultSopsFormat = "yaml";
    validateSopsFiles = false;

    secrets = {
      "conrad-visby".neededForUsers = true;
      "nextcloud-admin" = { };
    };
  };

  # users
  users.mutableUsers = false; # declarative define users and passwords
  users.users.conrad = {
    isNormalUser = true;
    description = "conrad";
    extraGroups = [
      "wheel"
      "sudo"
    ];
    openssh.authorizedKeys.keys = [
      # TODO
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKPKCP2alzmKEfPdXglFbTwo3SaBZ9ihoFKAiQZumwuq noi@beba" # beba network entry key
    ];
    hashedPasswordFile = config.sops.secrets.conrad-doswai.path;
    shell = "${pkgs.zsh}/bin/zsh";
  };

  # optional
  nix.daemonCPUSchedPolicy = "idle";
  nix.daemonIOSchedClass = "idle";

  # nix.conf options
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    min-free = "5G";
    max-free = "25G";
    trusted-users = [
      "root"
      "@wheel"
      "conrad"
    ];
    # when building aarch in quemu vm you might need to sign it to be used
    trusted-public-keys = [
      "halland:33taTR/SUQ4XTTU4TMJG19iSHIXxQzhMn99pqjOjQKA="
    ];
  };
}
