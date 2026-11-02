{
  description = "finix: módulo do home-manager com o ambiente de desenvolvimento padrão";

  # Sem inputs: o módulo usa o nixpkgs e o home-manager de quem o importa.
  outputs = { self }: {
    homeManagerModules.default = ./home;

    templates.default = {
      path = ./templates/default;
      description = "Home-manager pessoal importando o módulo do finix";
    };
  };
}
