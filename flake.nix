{
  description = "Nix for macOS configuration";

  ##################################################################################################################
  #
  # Want to know Nix in details? Looking for a beginner-friendly tutorial?
  # Check out https://github.com/ryan4yin/nixos-and-flakes-book !
  #
  ##################################################################################################################

  # the nixConfig here only affects the flake itself, not the system configuration!
  nixConfig = {
    substituters = [
      # Query the mirror of USTC first, and then the official cache.
      # "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];
  };

  # This is the standard format for flake.nix. `inputs` are the dependencies of the flake,
  # Each item in `inputs` will be passed as a parameter to the `outputs` function after being pulled and built.
  inputs = {
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    # nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-23.11-darwin";
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
  };

  # The `outputs` function will return all the build results of the flake.
  # A flake can have many use cases and different types of outputs,
  # parameters in `outputs` are defined in `inputs` and can be referenced by their names.
  # However, `self` is an exception, this special parameter points to the `outputs` itself (self-reference)
  # The `@` syntax here is used to alias the attribute set of the inputs's parameter, making it convenient to use inside the function.
  outputs = inputs @ {
    self,
    nixpkgs,
    darwin,
    home-manager,
    ...
  }: let
    mkApp = scriptName: system: {
      type = "app";
      program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin scriptName ''
        #!/usr/bin/env zsh
        PATH=${nixpkgs.legacyPackages.${system}.git}/bin:$PATH
        echo "Running ${scriptName} for ${system}"
        exec ${self}/apps/${system}/${scriptName}
      '')}/bin/${scriptName}";
    };

    mkDarwinApps = system: {
      "apply" = mkApp "apply" system;
      "build" = mkApp "build" system;
      "build-switch" = mkApp "build-switch" system;
      "copy-keys" = mkApp "copy-keys" system;
      "create-keys" = mkApp "create-keys" system;
      "check-keys" = mkApp "check-keys" system;
      "rollback" = mkApp "rollback" system;
    };
    # TODO replace with your own username and system
    username = "josephgiralt";
    system = "aarch64-darwin"; # aarch64-darwin or x86_64-darwin
    # hostname = "${username}-macbook";
    hostname = "macbook-pro-1";



    specialArgs =
      inputs
      // {
        inherit username hostname mkApp mkDarwinApps home-manager;
      };
  in {
    nixpkgs.config.allowUnfree = true;

    programs.direnv.enable = true;
    programs.direnv.enableZshIntegration = true;
    programs.direnv.nix-direnv.enable = true;

    darwinConfigurations."${hostname}" = darwin.lib.darwinSystem {
      inherit system specialArgs;
      modules = [
        ./modules/nix-core.nix
        ./modules/system.nix
        ./modules/apps.nix
        ./modules/host-users.nix
        # ./modules/home-manager.nix
        home-manager.darwinModules.home-manager
        ({ pkgs, ... }: {
        environment.systemPackages = with pkgs; [
          darwin
        ];
        home-manager.backupFileExtension = "backup";
        home-manager.users.josephgiralt = {
          programs.atuin = {
            enable = true;
            settings = {
              # Set your preferences here
              history = {
                path = "/Users/${username}/.local/share/atuin/history.db";
              };
              sync = {
                # Configure automatic synchronization
                enabled = false;
                # address = "https://sync.youratuinserver.com"; # Change this to your Atuin server address
                # auth_key = "your-auth-key-here"; # Your authentication key
              };
            };
          };
          programs.wezterm = {
            enable = true;
            enableZshIntegration = true;
          };
          programs.zsh = {
            enable = true;
            autosuggestion.enable = true;
            enableCompletion = true;
            history = {
              ignoreDups = true;
              save = 1000000;
              size = 1000000;
            };
            shellAliases = {
              v = "vim";
            };
            initExtra = ''
              unalias 9
              autoload -U down-line-or-beginning-search
              autoload -U up-line-or-beginning-search
              bindkey '^[[A' down-line-or-beginning-search
              bindkey '^[[A' up-line-or-beginning-search
              zle -N down-line-or-beginning-search
              zle -N up-line-or-beginning-search

              . "${pkgs.asdf-vm}/share/asdf-vm/asdf.sh"
              # . "${pkgs.asdf-vm}/share/asdf-vm/completions/asdf.zsh"

              eval "$(direnv hook zsh)"
              if [ -f .envrc ]; then
                  direnv allow
              fi
              eval "$(keychain --eval --quiet --noask ssh id_ed25519)"
              eval $(/opt/homebrew/bin/brew shellenv)
              autoload -Uz compinit && compinit
              export PATH="/opt/homebrew/opt/openssl@1.1/bin:$PATH"

              export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
              export DISABLE_SPRING=true
              neofetch
            '';
            oh-my-zsh = {
              enable = true;
              theme = "flazz";
              plugins = [
                "brew"
                "direnv"
                "docker"
                "encode64"
                "git"
                "git-extras"
                "man"
                "nmap"
                "ssh-agent"
                "sudo"
                "tig"
                "vi-mode"
                "yarn"
                "zsh-navigation-tools"
                "systemd"
              ];
            };
          };
          home.stateVersion = "23.11";
          home.packages = with pkgs; [
            vim
            git
            keychain
            neofetch
            direnv
            darwin
          ];
        };
      })
      ];
    };
    # nix code formatter
    formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;
  };
}
