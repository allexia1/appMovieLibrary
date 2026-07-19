# MovieLibraryApp

App iOS nativo para explorar filmes: listar populares, buscar por título, favoritar e ver detalhes — com
favoritos persistidos localmente (funcionam até offline). Construído em Swift/UIKit com Clean Architecture,
MVVM e Coordinators, consumindo a API pública da TMDB (The Movie Database).

## Contexto

O objetivo é oferecer uma experiência simples de "biblioteca de filmes": o usuário abre o app, já vê os
filmes mais populares do momento, pode buscar por título com resposta rápida (busca com debounce, sem
disparar uma requisição a cada tecla digitada), rolar a lista com paginação real (scroll infinito) e marcar
filmes como favoritos tocando num coração — tanto na listagem quanto na tela de detalhes. Os favoritos ficam
salvos no dispositivo (SwiftData) e continuam disponíveis mesmo sem internet.

## Solução Proposta

Principais fluxos do usuário:

1. **Descobrir filmes populares** — ao abrir o app, a aba "Filmes" já carrega a primeira página de filmes
   populares da TMDB, exibidos em uma grade de pôsteres (2 colunas no iPhone, mais colunas no iPad).
2. **Buscar por título** — o usuário digita na barra de busca; a busca só é disparada 300ms depois de parar
   de digitar (debounce), cancelando buscas anteriores ainda pendentes.
3. **Rolar e carregar mais** — ao chegar perto do fim da lista (últimos 5 itens visíveis), a próxima página é
   carregada automaticamente, com um indicador de carregamento no rodapé da grade.
4. **Favoritar/desfavoritar** — tocar no coração de um pôster (na listagem ou no detalhe) alterna o estado de
   favorito imediatamente na tela, sem precisar recarregar a lista inteira, e persiste a mudança em disco.
5. **Ver detalhes** — tocar em um filme abre uma tela com imagem em destaque, ano, nota, gêneros e sinopse
   (com "ler mais/menos" para textos longos), e o mesmo botão de favoritar.
6. **Consultar favoritos offline** — a aba "Favoritos" mostra os filmes salvos, lidos do banco local
   (SwiftData); funciona mesmo sem conexão com a internet.

## Visão Técnica

O projeto segue Clean Architecture com 4 camadas dentro do target `MovieLibraryApp`, mais um Swift Package
local isolado para a camada de rede:

- **AppSetupFiles** — composição raiz do app: `AppConfig` (lê as credenciais da TMDB do `Info.plist`,
  `fatalError` se ausentes), `AppDependencyContainer` (injeção de dependência manual, sem framework de DI),
  `Coordinators` (`AppCoordinator` → `MoviesCoordinator`, responsáveis pela navegação), `AppDelegate` e
  `SceneDelegate`.
- **Domain** — o núcleo de regras de negócio, sem depender de UIKit nem de SwiftData: entidades imutáveis
  (`MovieItem`, `MoviesPage`), protocolos de repositório, o `ScreenState<T>` genérico usado por todos os
  ViewModels, o `FetchMoviesUseCase` e a `FavoriteMoviesStore` (fonte única de verdade dos favoritos em
  memória durante a sessão do app).
- **Data** — implementações concretas: `TMDBMovieRepository` (consome a TMDB via o pacote `NetworkingKit`),
  `FavoriteMoviesRepository` (um `actor` que persiste favoritos via SwiftData) e o mapeamento de erros de
  rede para mensagens localizadas (`MovieListRequestError`).
- **Presentation** — telas em UIKit 100% via código (sem Storyboards, exceto a tela de lançamento): MVVM com
  `MovieListViewModel`/`FavoritesViewModel` publicando um `ScreenState<MovieItem>` único, uma
  `MovieListScreenView` reutilizável (grade de pôsteres com `UICollectionViewDiffableDataSource`) para as
  abas de Filmes e Favoritos, e a tela de detalhes (`MovieDetailView`).

Decisões de arquitetura mais relevantes:

- **Coordinator em vez de navegação direta entre telas**: as `ViewController`s não conhecem umas às outras
  nem decidem para onde navegar — isso fica centralizado no `MoviesCoordinator`, o que facilita testar/trocar
  fluxos de navegação sem tocar nas telas.
- **DI manual via `AppDependencyContainer`**: sem frameworks de terceiros, apenas `lazy var` — cada
  dependência é criada uma única vez e reaproveitada, incluindo a `FavoriteMoviesStore` compartilhada entre
  as abas de Filmes e Favoritos, mantendo os dois lados sempre sincronizados.
- **`FavoriteMoviesStore` além do `FavoriteMoviesRepository`**: o repositório fala com o SwiftData; a store é
  um cache em memória, único durante a sessão do app, que evita reconsultar o banco a cada toque no coração e
  garante que a aba de Filmes e a aba de Favoritos vejam sempre o mesmo estado.
- **Pacote de rede isolado (`Packages/NetworkingKit`)**: protocolos `Request`/`Networking` e o
  `URLSessionClient` vivem em um Swift Package próprio, com testes que não dependem do restante do app —
  facilita reuso e mantém a camada de rede testável isoladamente.
- **`ScreenState<T>` genérico**: todo ViewModel de listagem expõe o mesmo enum (`loading`/`empty`/
  `content`/`error`), o que permite que a `MovieListScreenView` seja 100% reutilizada entre a tela de Filmes
  e a de Favoritos.

## Funcionalidades Implementadas

- Listagem de filmes populares da TMDB com scroll infinito (paginação real via múltiplas requisições).
- Busca por título com debounce de 300ms.
- Grade de pôsteres (2 colunas no iPhone, mais no iPad) com badge de nota, botão de favorito animado e
  skeleton loading (shimmer) durante o carregamento.
- Favoritar/desfavoritar na listagem, nos favoritos e na tela de detalhes, com persistência local via
  SwiftData (funciona offline).
- Tela de detalhes com imagem em destaque, gradiente, chips de gênero e sinopse com "ler mais/menos".
- Estados de tela consistentes (carregando, vazio, conteúdo, erro) com "Tentar novamente" quando aplicável.
- Erros de paginação exibidos como alerta, sem descartar os itens já carregados.
- Pull-to-refresh na listagem principal.
- Suporte nativo a Dark Mode (cores semânticas do sistema).
- Acessibilidade básica (labels em botões de favoritar e nas células).

## Como Executar o Projeto

### Requisitos

- macOS com Xcode 16 ou mais recente (testado com Xcode 26.6).
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) instalado (`brew install xcodegen`) — o projeto não
  versiona o `.xcodeproj`, ele é gerado a partir de `project.yml`.
- Uma conta gratuita em [themoviedb.org](https://www.themoviedb.org/) para gerar as credenciais da API.

### 1. Gerar credenciais da TMDB

1. Crie uma conta em themoviedb.org.
2. Acesse **Configurações > API** e solicite uma chave de API.
3. Você vai receber uma **API Key (v3)** e pode gerar também um **Access Token (v4 auth)** — o app usa o
   Access Token (Bearer token) nas requisições.

### 2. Configurar as credenciais no projeto

`Config.xcconfig` contém suas credenciais reais e **não é versionado** (está no `.gitignore`), para evitar
que uma chave real seja commitada por engano. O repositório versiona apenas `Config.xcconfig.example`, um
template com valores placeholder.

Copie o template para o arquivo local e edite-o com seus valores:

```bash
cp Config.xcconfig.example Config.xcconfig
```

Edite o `Config.xcconfig` recém-criado na raiz do projeto e substitua os valores placeholder:

```
TMDB_API_KEY = sua_api_key_aqui
TMDB_ACCESS_TOKEN = seu_access_token_aqui
```

Esses valores são injetados no `Info.plist` do app (chaves `TMDBAPIKey`/`TMDBAccessToken`) e lidos em tempo de
execução por `AppConfig` (`MovieLibraryApp/AppSetupFiles/AppConfig.swift`). Se você rodar o app sem configurar
credenciais reais, ele encerra com um `fatalError` explicando o que fazer — isso é intencional, para deixar
claro que a chave está faltando em vez de falhar silenciosamente nas requisições.

### 3. Gerar o projeto Xcode e rodar

```bash
brew install xcodegen   # se ainda não tiver
cd MovieLibraryApp       # pasta raiz do repositório
xcodegen generate
open MovieLibraryApp.xcodeproj
```

No Xcode, selecione o scheme `MovieLibraryApp`, escolha um simulador de iPhone (iOS 17+) e rode com
`Cmd+R`. Sempre que adicionar/remover arquivos ou alterar `project.yml`, rode `xcodegen generate` de novo
antes de abrir o Xcode.

## Testes

- **`Packages/NetworkingKit`** tem sua própria suíte de testes, independente do app (`swift test` dentro da
  pasta do pacote): cobre sucesso, erro HTTP, timeout, decodificação inválida e cancelamento, usando um
  `URLProtocol` de teste (sem rede real).
- **`MovieLibraryAppTests`** (Swift Testing) cobre:
  - **Domain**: `FetchMoviesUseCase` (delega corretamente, propaga erro) e `FavoriteMoviesStore` (carrega
    favoritos uma única vez, atualiza o cache em memória ao salvar/remover sem re-consultar o banco).
  - **Data**: `FavoriteMoviesRepository` com um `ModelContainer` do SwiftData em memória (salvar, atualizar
    em vez de duplicar, remover, ordenar por data de favoritado); `TMDBMovieRepository` com um dublê de rede
    (mapeamento da resposta, campos ausentes, paginação, mapeamento de erros); `MovieListRequestError`
    (mapeamento de cada caso de erro de rede).
  - **Presentation**: `MovieListViewModel` (todos os estados de tela, busca com debounce e normalização,
    paginação incremental com deduplicação, erro de paginação que não descarta o conteúdo, toggle de
    favorito local, resync de favoritos) e `FavoritesViewModel` (estados de tela, toggle removendo/
    adicionando).

Para rodar tudo pelo terminal:
```bash
cd Packages/NetworkingKit && swift test && cd ../..
xcodegen generate
xcodebuild test -project MovieLibraryApp.xcodeproj -scheme MovieLibraryApp -destination "platform=iOS Simulator,name=iPhone 16"
```

## Evoluções Futuras

- Adicionar uma segunda chamada à TMDB (`/genre/movie/list`) para manter o catálogo de gêneros sempre
  atualizado, em vez do mapeamento estático usado hoje (`TMDBGenreCatalog`).
- Exibir provedores de streaming disponíveis por filme (endpoint `/movie/{id}/watch/providers` da TMDB).
- Cache offline também para a listagem/busca (não só para favoritos), permitindo rever os últimos resultados
  sem internet.
- Suporte a múltiplos idiomas de interface (hoje há só `pt-BR` em `Localizable.strings`).
- Testes de snapshot para as células e telas principais, cobrindo estados visuais (skeleton, badge de nota,
  chips de gênero).
- Widget de iOS mostrando os favoritos mais recentes na tela de início.
