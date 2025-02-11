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
    nixpkgs-darwin.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable&shallow=1";
    home-manager.url = "github:nix-community/home-manager";
    # nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-23.11-darwin";
    roc.url = "github:roc-lang/roc";
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
    roc,
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
    username = "joe";
    system = "aarch64-darwin"; # aarch64-darwin or x86_64-darwin
    # hostname = "${username}-macbook";
    hostname = "macbook-pro-1";

    specialArgs =
      inputs
      // {
        inherit username hostname mkApp mkDarwinApps home-manager roc system;
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
        home-manager.darwinModules.home-manager
        ({pkgs, ...}: {
          environment.systemPackages = with pkgs; [
            darwin
          ];
          home-manager.backupFileExtension = "backup";
          home-manager.users.joe = {
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

                if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
                  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
                fi

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
                export PATH="/run/current-system/sw/bin:$PATH"
                export PATH="/usr/local/bin:$PATH"
                export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
                export DISABLE_SPRING=true
                fastfetch
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
                ];
              };
            };
            home.stateVersion = "23.11";
            home.packages = with pkgs; [
              vim
              git
              keychain
              fastfetch
              direnv
              darwin
            ];
            home.file = {
              ".tool-versions" = {
                enable = true;
                recursive = true;
                text = let
                  versions = [
                    {
                      tool = "bun";
                      version = "1.1.20";
                    }
                    {
                      tool = "elixir";
                      version = "1.17.2-otp-27";
                    }
                    {
                      tool = "erlang";
                      version = "27.0.1";
                    }
                    {
                      tool = "golang";
                      version = "1.22.5";
                    }
                    {
                      tool = "nodejs";
                      version = "22.5.1";
                    }
                    {
                      tool = "ruby";
                      version = "3.2.1";
                    }
                    {
                      tool = "zig";
                      version = "0.13.0";
                    }
                    {
                      tool = "gleam";
                      version = "1.3.2";
                    }
                  ];
                in
                  builtins.concatStringsSep "\n" (builtins.map (v: "${v.tool} ${v.version}") versions);
              };
            };
          };
        })
      ];
    };
    # nix code formatter
    formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;
  };
}
