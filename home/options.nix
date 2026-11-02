{ lib, ... }:
{
  options.finix = {
    rust.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Ambiente Rust (rustup e ~/.cargo/bin no PATH).";
    };

    dotnet.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "SDK do dotnet e variáveis DOTNET_*.";
    };

    node.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Node.js (LTS), pnpm e prettier.";
    };

    kubernetes.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Ferramentas de Kubernetes: kubectl, helm, k9s, argocd e sops.";
    };

    editor = lib.mkOption {
      type = lib.types.str;
      default = "code";
      example = "nvim";
      description = "Valor de $EDITOR.";
    };

    aliases = lib.mkOption {
      type = lib.types.attrsOf (lib.types.nullOr lib.types.str);
      default = { };
      example = lib.literalExpression ''{ gs = null; ll = "eza -l"; }'';
      description = ''
        Aliases do fish. Os do finix vêm por padrão; defina um nome para
        sobrescrever, ou use null para remover.
      '';
    };

    fish.viKeyBindings = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Habilita fish_vi_key_bindings (modo vi no fish).";
    };

    fish.plugins = lib.mkOption {
      type = lib.types.attrsOf lib.types.bool;
      default = { };
      example = lib.literalExpression ''{ hydro = false; done = true; }'';
      description = ''
        Plugins do fish (nome em pkgs.fishPlugins). false desativa um plugin
        do finix; true ativa qualquer outro.
      '';
    };
  };
}
