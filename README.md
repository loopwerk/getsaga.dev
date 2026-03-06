<p align="center">
  <img src="logo.png" width="200" alt="Saga" />
</p>

# getsaga.dev

The source code of [getsaga.dev](https://getsaga.dev), the website for [Saga](https://github.com/loopwerk/Saga) — a code-first static site generator in Swift.

## What's in here

- **Documentation** — Saga's DocC guide files, rendered as browsable HTML pages
- **API reference** — generated from Saga's symbol graph, covering every public type, method, and property
- **Landing page** — feature overview, code examples, and links to the plugin ecosystem

The site is itself built with Saga: it parses Saga's own source code and DocC files to produce its documentation. Saga documenting Saga.

## Tech stack

- [Saga](https://github.com/loopwerk/Saga) — static site generation
- [SagaSwimRenderer](https://github.com/loopwerk/SagaSwimRenderer) — type-safe HTML templates
- [SagaParsleyMarkdownReader](https://github.com/loopwerk/SagaParsleyMarkdownReader) — Markdown parsing
- [Moon](https://github.com/loopwerk/Moon) — syntax highlighting
- [Bonsai](https://github.com/loopwerk/Bonsai) — HTML minification
- [SwiftTailwind](https://github.com/loopwerk/SwiftTailwind) — Tailwind CSS
- [SymbolKit](https://github.com/swiftlang/swift-docc-symbolkit) — symbol graph parsing for the API reference

## Development

```shell
brew install loopwerk/tap/saga just
just run
```

## Building for production

```shell
just build
```

The output is written to `deploy/`.
