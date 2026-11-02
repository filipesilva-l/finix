{ pkgs, lib, config, ... }:
let
  sdk = pkgs.dotnetCorePackages.sdk_10_0;
in
{
  config = lib.mkIf config.finix.dotnet.enable {
    home.packages = [ sdk ];

    home.sessionVariables = {
      DOTNET_ROOT = "${sdk}/share/dotnet";
      DOTNET_CLI_TELEMETRY_OPTOUT = "1";
      DOTNET_NOLOGO = "1";
      DOTNET_ENVIRONMENT = "Development";
    };

    # Ferramentas globais (dotnet tool install -g)
    home.sessionPath = [ "$HOME/.dotnet/tools" ];
  };
}
