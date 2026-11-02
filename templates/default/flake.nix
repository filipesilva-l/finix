{
  description = "Meu ambiente de desenvolvimento (home-manager + finix)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    finix.url = "github:filipesilva-l/finix";
  };

  # Usuário, HOME e arquitetura vêm do ambiente, por isso o comando de
  # aplicação usa --impure (veja o README do finix).
  outputs = { nixpkgs, home-manager, finix, ... }:
    let
      user = builtins.getEnv "USER";
      home = builtins.getEnv "HOME";
    in {
      homeConfigurations.default = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${builtins.currentSystem};
        modules = [
          finix.homeManagerModules.default
          ({ pkgs, ... }: {
            home.username = user;
            home.homeDirectory = home;
            home.stateVersion = "25.05";

            programs.home-manager.enable = true;
            # Necessário fora do NixOS (Ubuntu)
            targets.genericLinux.enable = true;

            # --- Suas escolhas: descomente e ajuste ---------------------

            # Ligar/desligar ferramentas (todas vêm ligadas por padrão)
            # finix.rust.enable = false;
            # finix.dotnet.enable = false;
            # finix.node.enable = false;
            # finix.kubernetes.enable = false;

            # finix.editor = "nvim";           # padrão: "code"
            # finix.fish.viKeyBindings = true; # modo vi no fish

            # Aliases: sobrescreva, adicione ou remova (null)
            # finix.aliases = {
            #   gs = null;                 # remove
            #   gc = "git commit -v";      # sobrescreve
            #   ll = "eza -l";             # adiciona
            # };

            # Plugins do fish (nomes de pkgs.fishPlugins)
            # finix.fish.plugins = {
            #   hydro = false;
            #   done = true;
            # };

            # Pacotes extras
            # home.packages = with pkgs; [ lazygit ];
          })
        ];
      };
    };
}
