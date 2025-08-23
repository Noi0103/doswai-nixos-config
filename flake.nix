{
  description = "nixos-config for doswai infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";

    doswai-frontend.url = "git+ssh://git@github.com/Noi0103/doswai-frontend";
    doswai-backend.url = "git+ssh://git@github.com/Noi0103/doswai-backend";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-hardware,
      sops-nix,
      pre-commit-hooks,
      doswai-frontend,
      doswai-backend,
    }@inputs:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      system = "x86_64-linux";
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      nixosConfigurations = {
        wasserkopf = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
          };
          modules = [
            ./hosts/wasserkopf
            sops-nix.nixosModules.sops
            doswai-backend.nixosModules.backend
            {
              services.backend = {
                enable = true;
                port = 20001;
                socket-ip = "0.0.0.0";
                openFirewall = false;
              };
            }
          ];
        };
      };

      # the direnv shell addon to automatically activate devShells when entering the dir is nice to have
      devShells.${system}.default = pkgs.mkShell {
        inherit (self.checks.${system}.pre-commit-check) shellHook;
        buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
        packages = with pkgs; [
          nixpkgs-fmt
        ];
      };

      # check config without making changes `nix flake check`
      # check config and change formatting `nix develop -c pre-commit run --all-files`
      checks = forAllSystems (system: {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks.nixfmt-rfc-style.enable = true;
        };
      });
    };
}
