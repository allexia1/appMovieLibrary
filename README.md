# MovieLibraryApp

App iOS nativo para explorar filmes: listar populares, buscar por título, favoritar e ver detalhes — com
favoritos persistidos localmente (funcionam até offline). Construído 100% em SwiftUI com Clean Architecture
e MVVM, consumindo a API pública da TMDB (The Movie Database).

## Contexto

O objetivo é oferecer uma experiência simples de "biblioteca de filmes": o usuário abre o app, já vê os
filmes mais populares do momento, pode buscar por título com resposta rápida (busca com debounce, sem
disparar uma requisição a cada tecla digitada), rolar a lista com paginação real (scroll infinito) e marcar
filmes como favoritos tocando num coração — tanto na listagem quanto na tela de detalhes. Os favoritos ficam
salvos no dispositivo (SwiftData) e continuam disponíveis mesmo sem internet.

## Solução Proposta

Principais fluxos do usuário:

1. **Descobrir filmes populares** — ao abrir o app, a aba "Filmes" já carrega a primeira página de filmes
   populares da TMDB, exibidos em uma grade adaptável de pôsteres (`LazyVGrid`, mais colunas em telas
   maiores).
2. **Buscar por título** — o usuário digita na barra de busca nativa (`.searchable`); a busca só é disparada
   300ms depois de parar de digitar (debounce via `Task.sleep` cancelável), cancelando buscas anteriores
   ainda pendentes.
3. **Rolar e carregar mais** — ao chegar perto do fim da lista (últimos 5 itens visíveis), a próxima página é
   carregada automaticamente, com um indicador de carregamento no rodapé da grade.
4. **Favoritar/desfavoritar** — tocar no coração de um pôster (na listagem ou no detalhe) alterna o estado de
   favorito imediatamente na tela, sem precisar recarregar a lista inteira, e persiste a mudança em disco.
5. **Ver detalhes** — tocar em um filme abre uma tela (via `NavigationLink(value:)`) com imagem em destaque,
   ano, nota, gêneros e sinopse (com "ler mais/menos" para textos longos), e o mesmo botão de favoritar.
6. **Consultar favoritos offline** — a aba "Favoritos" mostra os filmes salvos, lidos do banco local
   (SwiftData); funciona mesmo sem conexão com a internet.

## Visão Técnica

O projeto segue Clean Architecture com 4 camadas dentro do target `MovieLibraryApp`, mais um Swift Package
local isolado para a camada de rede:

- **AppSetupFiles** — composição raiz do app: `MovieLibraryAppApp` (entry point `@main`), `RootView`
  (`TabView` com as abas Filmes/Favoritos, cada uma em sua própria `NavigationStack`, e o
  `navigationDestination(for: MovieItem.self)` que abre a tela de detalhes), `AppConfig` (lê as credenciais
  da TMDB do `Info.plist`, `fatalError` se ausentes/placeholder) e `AppDependencyContainer` (injeção de
  dependência manual via `lazy var`, sem framework de DI).
- **Domain** — o núcleo de regras de negócio, sem depender de SwiftUI/UIKit nem de SwiftData: entidades
  imutáveis (`MovieItem`, `MoviesPage`), protocolos de repositório (`MovieRepositoryProtocol`,
  `FavoriteMoviesRepositoryProtocol`), o `ScreenState<T>` genérico usado por todos os ViewModels, o
  `FetchMoviesUseCase` e a `FavoriteMoviesStore` (fonte única de verdade dos favoritos em memória durante a
  sessão do app).
- **Data** — implementações concretas: `TMDBMovieRepository` (consome a TMDB via o pacote `NetworkingKit`,
  mapeando `/movie/popular` ou `/search/movie`), `FavoriteMoviesRepository` (um `actor` que persiste
  favoritos via SwiftData, com `FavoriteMovieObj` como modelo `@Model`) e o mapeamento de erros de rede para
  mensagens localizadas (`MovieListRequestError`).
- **Presentation** — telas 100% em SwiftUI: MVVM com `@Observable` ViewModels (`MovieListViewModel`,
  `FavoritesViewModel`, `MovieDetailViewModel`) publicando um `ScreenState<MovieItem>` único, uma
  `MovieGridView` reutilizável (grade de pôsteres + estados de loading/vazio/erro/paginação) compartilhada
  pelas abas de Filmes e Favoritos, e a tela de detalhes (`MovieDetailScreen`). Helpers de apoio:
  `CachedAsyncImage`/`ImageLoader` (cache de imagens em `NSCache`), `ShimmerView` (skeleton loading) e
  `FeedbackStateView` (estado de tela cheia: loading/vazio/erro com retry).

Decisões de arquitetura mais relevantes:

- **Navegação declarativa via `navigationDestination`, sem Coordinators**: cada aba tem sua própria
  `NavigationStack` e a `RootView` registra o destino da tela de detalhes por tipo (`MovieItem`); não há uma
  camada de Coordinator separada — a navegação é resolvida pelas próprias Views SwiftUI.
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
  `content`/`error`), o que permite que a `MovieGridView` seja 100% reutilizada entre a tela de Filmes e a de
  Favoritos.

## Funcionalidades Implementadas

- Listagem de filmes populares da TMDB com scroll infinito (paginação real via múltiplas requisições).
- Busca por título com debounce de 300ms.
- Grade de pôsteres adaptável com badge de nota, botão de favorito animado e skeleton loading (shimmer)
  durante o carregamento.
- Favoritar/desfavoritar na listagem, nos favoritos e na tela de detalhes, com persistência local via
  SwiftData (funciona offline).
- Tela de detalhes com imagem em destaque, gradiente, chips de gênero e sinopse com "ler mais/menos".
- Estados de tela consistentes (carregando, vazio, conteúdo, erro) com "Tentar novamente" quando aplicável.
- Erros de paginação exibidos como alerta, sem descartar os itens já carregados.
- Pull-to-refresh na listagem principal.
- Suporte nativo a Dark Mode (cores semânticas do sistema).
- Acessibilidade básica (labels e ações de acessibilidade nos botões de favoritar e nas células).

## Como Executar o Projeto

### Requisitos

- macOS com Xcode 16 ou mais recente.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) instalado (`brew install xcodegen`) — o projeto não
  versiona o `.xcodeproj` como fonte de verdade, ele é gerado a partir de `project.yml`.
- Uma conta gratuita em [themoviedb.org](https://www.themoviedb.org/) para gerar as credenciais da API.

### 1. Gerar credenciais da TMDB

1. Crie uma conta em themoviedb.org.
2. Acesse **Configurações > API** e solicite uma chave de API.
3. Você vai receber uma **API Key (v3)** e pode gerar também um **Access Token (v4 auth)** — o app usa o
   Access Token (Bearer token) nas requisições (`TMDBMoviesRequest`).

### 2. Configurar as credenciais no projeto

As credenciais ficam em `MovieLibrary/Config.xcconfig`, injetadas no `Info.plist` do app (chaves
`TMDBAPIKey`/`TMDBAccessToken`) e lidas em tempo de execução por `AppConfig`
(`MovieLibraryApp/AppSetupFiles/AppConfig.swift`). Se o app rodar sem credenciais reais configuradas, ele
encerra com um `fatalError` explicando o que fazer — isso é intencional, para deixar claro que a chave está
faltando em vez de falhar silenciosamente nas requisições.

Edite `MovieLibrary/Config.xcconfig` com seus valores:

```
TMDB_API_KEY = sua_api_key_aqui
TMDB_ACCESS_TOKEN = seu_access_token_aqui
```

> **Atenção:** hoje `Config.xcconfig` está versionado no repositório (não está apenas no `.gitignore`
> local). Antes de publicar ou compartilhar este repositório, revogue/gere novas credenciais na TMDB e
> remova o arquivo do controle de versão (`git rm --cached MovieLibrary/Config.xcconfig`), mantendo apenas
> um template sem valores reais.

### 3. Gerar o projeto Xcode e rodar

```bash
brew install xcodegen   # se ainda não tiver
cd MovieLibrary          # pasta raiz do projeto Xcode (dentro do repositório)
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
  - **Domain**: `FetchMoviesUseCase` (delega corretamente, propaga erro), `FavoriteMoviesStore` (carrega
    favoritos uma única vez, atualiza o cache em memória ao salvar/remover sem re-consultar o banco) e
    `MovieItem` (atualização imutável do estado de favorito).
  - **Data**: `FavoriteMoviesRepository` com um `ModelContainer` do SwiftData em memória (salvar, atualizar
    em vez de duplicar, remover, ordenar por data de favoritado); `TMDBMovieRepository` com um dublê de rede
    (mapeamento da resposta, campos ausentes, paginação, mapeamento de erros); `MovieListRequestError`
    (mapeamento de cada caso de erro de rede).
  - **Presentation**: `MovieListViewModel` (todos os estados de tela, busca com debounce e normalização,
    paginação incremental com deduplicação, erro de paginação que não descarta o conteúdo, toggle de
    favorito local, resync de favoritos), `FavoritesViewModel` (estados de tela, toggle removendo/
    adicionando) e `MovieDetailViewModel` (carregamento da imagem de destaque, toggle de favorito).

Para rodar tudo pelo terminal:
```bash
cd MovieLibrary/Packages/NetworkingKit && swift test && cd ../..
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
