{ pkgs, lib, config, ... }:
let
  cfg = config.finix;
  enabledPlugins = lib.filterAttrs (_: enabled: enabled) cfg.fish.plugins;
in
{
  # Padrões do finix. Cada chave é sobrescritível (ou removível com null)
  # na configuração de quem importa o módulo.
  finix.aliases = lib.mapAttrs (_: lib.mkDefault) {
    ls = "eza";
    cat = "bat";

    g = "git";
    gs = "git status -s";
    gsh = "git switch";
    gc = "git commit -m";
    gpl = "git pull";
    gps = "git push";

    jjbl = "jj bookmark list";
    jjbs = "jj bookmark set";
    jjf = "jj git fetch";
    jjp = "jj git push";

    k = "kubectl";
    kgp = "kubectl get pods";
    klg = "kubectl logs";
    kcx = "kubectl config use-context";
    kex = "kubectl exec";
  };

  finix.fish.plugins = lib.mapAttrs (_: lib.mkDefault) {
    fzf-fish = true;
    hydro = true;
  };

  # O fish é instalado pelo Nix. Para iniciá-lo no lugar do bash, rode
  # o bootstrap.sh com --bashrc (o chsh não funciona com o authd).
  programs.fish = {
    enable = true;

    plugins = lib.mapAttrsToList (name: _: {
      inherit name;
      src = pkgs.fishPlugins.${name}.src;
    }) enabledPlugins;

    shellAliases = lib.filterAttrs (_: v: v != null) cfg.aliases;

    functions = {
      fish_greeting = "";
      fish_title = ''
        echo (basename $PWD | sed 's/@.\+//')
      '';
    };

    interactiveShellInit = ''
      # Completions do jujutsu
      COMPLETE=fish jj | source
    '' + lib.optionalString cfg.fish.viKeyBindings ''

      # Atalhos estilo vi
      fish_vi_key_bindings
    '';
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  # Funções do finix (home/fish/functions/*.fish)
  xdg.configFile."fish/functions/up.fish".source = ./fish/functions/up.fish;
  xdg.configFile."fish/functions/jet.fish".source = ./fish/functions/jet.fish;
}
