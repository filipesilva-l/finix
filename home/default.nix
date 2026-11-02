# Módulo do home-manager com os padrões do finix. Não define stateVersion,
# usuário nem HOME: essas decisões são de quem importa.
{
  imports = [
    ./options.nix
    ./packages.nix
    ./fish.nix
    ./dotnet.nix
  ];
}
