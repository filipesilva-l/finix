# finix

Ambiente de desenvolvimento padronizado para **Ubuntu**, feito com
[Nix](https://nixos.org) e [home-manager](https://github.com/nix-community/home-manager).

São duas peças:

- **`bootstrap.sh`**: prepara a máquina (instala o Nix e o Docker).
- **`flake.nix`**: um *módulo* do home-manager com as ferramentas e
  configurações padrão. Você monta o **seu** ambiente importando esse módulo e
  ajustando o que quiser.

> **Nunca usou Nix?** Sem problema. Siga o passo a passo abaixo. Em resumo:
> o Nix instala programas de forma reproduzível, e o home-manager descreve em
> um arquivo (`flake.nix`) quais programas e configurações você quer no seu
> usuário. Você edita o arquivo e aplica; para desfazer, remova a linha e
> aplique de novo.

## Passo a passo

### 1. Preparar a máquina

```bash
git clone https://github.com/filipesilva-l/finix ~/finix
cd ~/finix
./bootstrap.sh
```

O script instala o Nix e o Docker (e adiciona você ao grupo `docker`). Pode
rodar de novo quando quiser: ele não repete o que já está feito.

Opcional: `./bootstrap.sh --bashrc` também faz o terminal padrão (bash) iniciar
o **fish**, o shell configurado pelo finix. Faça isso se quiser usar o fish.
(O `chsh` não funciona com o login corporativo, por isso usamos o `.bashrc`.)

Depois, **abra um novo terminal** (e, se o script avisar, faça logout/login
para o grupo `docker` valer).

### 2. Criar a sua configuração

```bash
mkdir -p ~/.config/home-manager
cd ~/.config/home-manager
nix flake init -t github:filipesilva-l/finix
```

Isso cria um `flake.nix` com tudo pronto e, comentadas, as opções que você pode
ajustar. Abra o arquivo (`nano flake.nix`, por exemplo) e descomente o que
quiser. Você **não precisa** mudar nada para começar: usuário e HOME são lidos
do ambiente.

### 3. Aplicar

```bash
nix run github:nix-community/home-manager -- switch --impure -b backup --flake .#default
```

- `--impure` é necessário porque o flake lê o seu usuário e HOME.
- `-b backup` guarda como `<arquivo>.backup` qualquer arquivo seu que seria
  substituído (por exemplo, um `~/.config/fish/config.fish` antigo).

Pronto: abra um novo terminal. A partir daqui o comando `home-manager` existe,
então basta:

```bash
home-manager switch --impure -b backup --flake ~/.config/home-manager#default
```

### 4. Mudar algo depois

1. Edite `~/.config/home-manager/flake.nix`.
2. Rode o `home-manager switch ...` do passo anterior.

### 5. Atualizar para uma versão nova do finix

```bash
cd ~/.config/home-manager
nix flake update finix
home-manager switch --impure -b backup --flake .#default
```

`nix flake update` (sem nome) atualiza também o nixpkgs e o home-manager, ou
seja, todas as versões dos pacotes. O `flake.lock` fixa o que você está usando;
guarde-o junto do `flake.nix` (se usar git, faça commit dos dois).

### Voltando atrás

```bash
home-manager generations      # lista as versões aplicadas
# execute o "activate" da geração que quiser, mostrado na lista
```

Se usou `--bashrc` e quiser desfazer, apague do `~/.bashrc` o trecho entre
`# >>> finix: fish >>>` e `# <<< finix: fish <<<`. O backup do arquivo original
é o `~/.bashrc.finix-backup`.

## O que é instalado

| Ferramenta                                                                                             | Desligável?               |
| ------------------------------------------------------------------------------------------------------ | ------------------------- |
| fish, git, jujutsu, direnv, devenv                                                                     | não                       |
| awscli2, age, tree-sitter, neovim, tmux, btop, fzf, skim, gh, jq, hurl, ripgrep, fd, bat, eza, zoxide | não                       |
| Node.js LTS, pnpm e prettier                                                                           | `finix.node.enable`       |
| kubectl, helm, k9s, argocd e sops                                                                      | `finix.kubernetes.enable` |
| .NET SDK e variáveis `DOTNET_*`                                                                        | `finix.dotnet.enable`     |
| rustup e `~/.cargo/bin` no PATH                                                                        | `finix.rust.enable`       |

Nix e Docker vêm do `bootstrap.sh`, não do módulo.

## Opções

Tudo tem um padrão e pode ser mudado no seu `flake.nix`.

| Opção                      | Padrão              | Descrição                         |
| -------------------------- | ------------------- | --------------------------------- |
| `finix.rust.enable`        | `true`              | rustup e `~/.cargo/bin`           |
| `finix.dotnet.enable`      | `true`              | SDK do .NET e `DOTNET_*`          |
| `finix.node.enable`        | `true`              | Node.js LTS, pnpm e prettier      |
| `finix.kubernetes.enable`  | `true`              | kubectl, helm, k9s, argocd e sops |
| `finix.editor`             | `"code"`            | valor de `$EDITOR`                |
| `finix.fish.viKeyBindings` | `false`             | modo vi no fish                   |
| `finix.aliases`            | aliases do finix    | `nome = "comando"`; `null` remove |
| `finix.fish.plugins`       | `fzf-fish`, `hydro` | `nome = true/false`               |

Exemplo (dentro do bloco de configuração do seu `flake.nix`):

```nix
finix.rust.enable = false;   # não uso Rust
finix.editor = "nvim";

finix.aliases = {
  gs = null;                 # remove um alias padrão
  gc = "git commit -v";      # sobrescreve
  ll = "eza -l";             # adiciona
};

finix.fish.plugins.hydro = false;   # desliga um plugin
home.packages = with pkgs; [ lazygit ];   # pacotes extras
```

Qualquer outra opção do home-manager também funciona (`programs.git`,
`programs.tmux`, ...): veja o
[manual de opções](https://nix-community.github.io/home-manager/options.xhtml).
Para tirar um pacote da base, use `lib.mkForce` na lista `home.packages`.

## Quem já usa home-manager

O flake exporta só `homeManagerModules.default` (sem inputs próprios: usa o
nixpkgs e o home-manager do seu flake). Não define `stateVersion`, usuário nem
HOME. Em uma configuração existente:

```nix
inputs.finix.url = "github:filipesilva-l/finix";
# ...
modules = [ finix.homeManagerModules.default ];
```

## Estrutura

```
bootstrap.sh              Nix, Docker, grupo docker e (opcional) .bashrc
flake.nix                 exporta o módulo e o template
home/
  default.nix             módulo exportado (importa os demais)
  options.nix             opções finix.*
  packages.nix            pacotes, direnv, EDITOR e PATH
  fish.nix                fish, aliases, plugins e funções
  dotnet.nix              SDK e variáveis do .NET
  fish/functions/         funções (up, jet)
templates/default/        flake de partida para quem usa o bootstrap
```

## Funções do fish

- `up`: vai para a raiz do repositório git (ou para `~`, fora de um).
- `jet`: escolhe com `sk` um projeto (`*.csproj`, `package.json`, `go.mod`,
  `Cargo.toml`, ...) dentro do repositório atual e entra nele.

## Mantenedores

- Ao renomear ou remover uma opção `finix.*`, use `lib.mkRenamedOptionModule` /
  `lib.mkRemovedOptionModule`, para não quebrar o flake de ninguém sem explicação.
- Os arquivos precisam estar commitados: o flake só enxerga arquivos
  rastreados pelo git.

## Limitações conhecidas

- Só Ubuntu/Debian (o `bootstrap.sh` usa `apt`).
- Docker instalado por snap ou `docker.io` não é substituído; o script só
  garante o grupo.
