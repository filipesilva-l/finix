{ pkgs, lib, config, ... }:
let
  cfg = config.finix;
in
{
  # Obrigatórios (não desligáveis): git, jujutsu, direnv, devenv, fish (fish.nix)
  home.packages =
    with pkgs;
    [
      git
      jujutsu
      devenv

      # Cloud / infra
      awscli2

      # Terminal / editor
      neovim
      tmux
      btop
      fzf
      skim

      # Utilitários
      gh
      jq
      hurl
      age
      tree-sitter
      ripgrep
      fd
      bat
      eza
      curl
      wget
      unzip
    ]
    ++ lib.optionals cfg.node.enable [
      nodejs_24 # LTS atual
      pnpm
      prettier
    ]
    ++ lib.optionals cfg.kubernetes.enable [
      kubectl
      kubernetes-helm
      k9s
      argocd
      sops
    ]
    ++ lib.optionals cfg.rust.enable [ rustup ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.sessionPath = [
    "$HOME/.local/bin"
  ] ++ lib.optional cfg.rust.enable "$HOME/.cargo/bin";

  home.sessionVariables.EDITOR = lib.mkDefault cfg.editor;
}
