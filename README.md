# doswai-nixos-config
nixos configuration for doswai infrastructure

# inputs for this config
nixpkgs: your usual nix package repo
nixos-hardware: is always included when searching for nixos on raspi stuff
sops-nix: secret files management
pre-commit-hooks: in this case only nixfmt lint checker

# initial setup
because of sops-nix a specific host key is expected on the deployed machine (in this case a rpi4)
- an age key will be used to edit and encrypt
- the deployed machines only use their host key to decrypt the secrets in order to use them
- there won't be any modification done unless the standalone age key is present on the current system
- to avoid frustration read this: https://github.com/Mic92/sops-nix


- install nixos
- add ssh access and enable flakes (this can be done by rebuilding locally with a local copy of the config `sudo nixos-rebuild test --accept-flake-config --flake /home/alice/nixos/#wasserkopf`)


- deploy modifications remote
  - since x86 will use quemu to build an aarch architecture, sign your nix paths with a key
  - `wasserkopf` in its _currently running_ config will need to accept this signature
  - with `ssh wasserkopf` as working login ssh command `nixos-rebuild switch --flake /home/noi/git/doswai-nixos-config/#wasserkopf --target-host wasserkopf --use-remote-sudo` will remote deploy the config


when the sd card eventually dies the setup steps will be the same: install nixos, make a initial rebuild to allow flakes and ssh, make remote deploy iterations (e.g. install updates)

# tips
- update the lock file with `nix flake update` (https://nixos-and-flakes.thiscute.world/nixos-with-flakes/update-the-system)

- if some path are missing when deploying run `nix flake check` (usually used to run lint tests, integration tests, ... but it will also evaluate the config and find syntax errors) (https://nix.dev/manual/nix/2.28/command-ref/new-cli/nix3-flake-check)

# other sources
https://nixos.org/manual/nixos/stable/
https://nix.dev/
https://nixos-and-flakes.thiscute.world/introduction/
