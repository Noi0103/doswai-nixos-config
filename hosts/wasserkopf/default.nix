{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware.nix
    ./misc.nix
    ./raspi-settings.nix
    ./services.nix
  ];

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  # anounces this name to in the network
  networking.hostName = "wasserkopf";

  # sd card should be nixos only and stateful data should reside on another blockdevice
  #fileSystems."/mnt/operation" = {
  #  device = "/dev/disk/by-uuid/<uuid>";
  #  fsType = "ext4";
  #  options = [
  #    "nofail"
  #    "users"
  #  ];
  #};
  #fileSystems."/mnt/backup" = {
  #  device = "/dev/disk/by-uuid/<uuid>";
  #  fsType = "ext4";
  #  options = [
  #    "nofail"
  #    "users"
  #  ];
  #};

  # these were still installed i left this even though it can be deleted as the most important
  # packages (for myself anyways) are provided in misc.nix
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
  ];

  # secret management
  # https://github.com/Mic92/sops-nix
  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    age.keyFile = "/var/lib/sops-nix/key.txt";
    age.generateKey = true;

    defaultSopsFile = ../../secrets/wasserkopf.yaml;
    defaultSopsFormat = "yaml";
    validateSopsFiles = false;

    secrets = {
      "alice-wasserkopf".neededForUsers = true;
      "noi-wasserkopf".neededForUsers = true;
      "nextcloud-admin-init" = { };
    };
  };

  # users
  # declaratively define users and passwords (yes, it includes overwriting)
  # https://github.com/Mic92/sops-nix?tab=readme-ov-file#setting-a-users-password
  users.mutableUsers = false;
  users.users.alice = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    packages = with pkgs; [
      tree
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMYKYFgQUbNK3skwgINa74dKQOa++PcukxFmlRWdhNxw paul"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKPKCP2alzmKEfPdXglFbTwo3SaBZ9ihoFKAiQZumwuq noi"
    ];
    hashedPasswordFile = config.sops.secrets."alice-wasserkopf".path;
  };
  users.users.noi = {
    isNormalUser = true;
    description = "noi";
    extraGroups = [
      "wheel"
      "sudo"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKPKCP2alzmKEfPdXglFbTwo3SaBZ9ihoFKAiQZumwuq noi"
    ];
    hashedPasswordFile = config.sops.secrets."noi-wasserkopf".path;
  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    openFirewall = true;
    banner = "wasserkopf running NixOS.\n";
    settings.PasswordAuthentication = false;
  };

  # bantime increment factor might be unnecess high
  # wrongly configured nixos-rebuild might block because it uses to multiple ssh connections and will trigger multiple failed logins
  services.fail2ban = {
    enable = true;
    bantime = "12h";
    bantime-increment.enable = true;
    bantime-increment.factor = "2";
  };

  # very optional: nix daemon prioritization
  nix.daemonCPUSchedPolicy = "idle";
  nix.daemonIOSchedClass = "idle";

  # nix.conf options
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # auto garbadge collect on full storage
    # this does not remove old links and will only get you so far
    # with the sd card size this should still last quite some time
    # usually a full garbage collect is done for build machines etc
    # i set this mainly to have less storage interactions (not a daily garbage collect)
    # but still have a fallback if storage is nearly full and some stuff is currently building
    min-free = "5G";
    max-free = "25G";

    trusted-users = [
      "root"
      "@wheel"
      "alice"
      "noi"
    ];

    # when building aarch in quemu vm you might need to sign it to be used when using remote deploy features
    # the first time to remote deploy will probably fail as this setting might not yet be set
    # building machine from where you deploy from: https://nix.dev/manual/nix/2.19/command-ref/conf-file#conf-secret-key-files
    # receiving machine running the config: https://search.nixos.org/options?channel=25.05&show=nix.settings.trusted-public-keys
    trusted-public-keys = [
      "noi:33taTR/SUQ4XTTU4TMJG19iSHIXxQzhMn99pqjOjQKA="
    ];
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?
}
