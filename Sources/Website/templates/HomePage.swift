import HTML
import Moon
import Saga
import SagaSwimRenderer

let iconShield = #"<svg class="h-5 w-5 fill-none stroke-2" style="stroke-linecap:round;stroke-linejoin:round" viewBox="0 0 24 24"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>"#

let iconChevrons = #"<svg class="h-5 w-5 fill-none stroke-2" style="stroke-linecap:round;stroke-linejoin:round" viewBox="0 0 24 24"><polyline points="13 17 18 12 13 7"/><polyline points="6 17 11 12 6 7"/></svg>"#

let iconBox = #"<svg class="h-5 w-5 fill-none stroke-2" style="stroke-linecap:round;stroke-linejoin:round" viewBox="0 0 24 24"><path d="M21 16V8a2 2 0 00-1-1.73l-7-4a2 2 0 00-2 0l-7 4A2 2 0 003 8v8a2 2 0 001 1.73l7 4a2 2 0 002 0l7-4A2 2 0 0021 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></svg>"#

let iconRefresh = #"<svg class="h-5 w-5 fill-none stroke-2" style="stroke-linecap:round;stroke-linejoin:round" viewBox="0 0 24 24"><polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/><path d="M3.51 9a9 9 0 0114.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0020.49 15"/></svg>"#

let iconRocket = #"<svg class="h-5 w-5 fill-none stroke-2" style="stroke-linecap:round;stroke-linejoin:round" viewBox="0 0 24 24"><path d="M12 19l7-7 3 3-7 7-3-3z"/><path d="M18 13l-1.5-7.5L2 2l3.5 14.5L13 18l5-5z"/><path d="M2 2l7.586 7.586"/><circle cx="11" cy="11" r="2"/></svg>"#

let iconCode = #"<svg class="h-5 w-5 fill-none stroke-2" style="stroke-linecap:round;stroke-linejoin:round" viewBox="0 0 24 24"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg>"#

let iconLayers = #"<svg class="h-5 w-5 fill-none stroke-2" style="stroke-linecap:round;stroke-linejoin:round" viewBox="0 0 24 24"><polygon points="12 2 2 7 12 12 22 7 12 2"/><polyline points="2 17 12 22 22 17"/><polyline points="2 12 12 17 22 12"/></svg>"#

let iconDatabase = #"<svg class="h-5 w-5 fill-none stroke-2" style="stroke-linecap:round;stroke-linejoin:round" viewBox="0 0 24 24"><ellipse cx="12" cy="5" rx="9" ry="3"/><path d="M21 12c0 1.66-4 3-9 3s-9-1.34-9-3"/><path d="M3 5v14c0 1.66 4 3 9 3s9-1.34 9-3V5"/></svg>"#

let iconSliders = #"<svg class="h-5 w-5 fill-none stroke-2" style="stroke-linecap:round;stroke-linejoin:round" viewBox="0 0 24 24"><line x1="4" y1="21" x2="4" y2="14"/><line x1="4" y1="10" x2="4" y2="3"/><line x1="12" y1="21" x2="12" y2="12"/><line x1="12" y1="8" x2="12" y2="3"/><line x1="20" y1="21" x2="20" y2="16"/><line x1="20" y1="12" x2="20" y2="3"/><line x1="1" y1="14" x2="7" y2="14"/><line x1="9" y1="8" x2="15" y2="8"/><line x1="17" y1="16" x2="23" y2="16"/></svg>"#

let iconGlobe = #"<svg class="h-5 w-5 fill-none stroke-2" style="stroke-linecap:round;stroke-linejoin:round" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 014 10 15.3 15.3 0 01-4 10 15.3 15.3 0 01-4-10 15.3 15.3 0 014-10z"/></svg>"#

let iconGitBranch = #"<svg class="h-5 w-5 fill-none stroke-2" style="stroke-linecap:round;stroke-linejoin:round" viewBox="0 0 24 24"><line x1="6" y1="3" x2="6" y2="15"/><circle cx="18" cy="6" r="3"/><circle cx="6" cy="18" r="3"/><path d="M18 9a9 9 0 01-9 9"/></svg>"#

let iconMap = #"<svg class="h-5 w-5 fill-none stroke-2" style="stroke-linecap:round;stroke-linejoin:round" viewBox="0 0 24 24"><polygon points="1 6 1 22 8 18 16 22 23 18 23 2 16 6 8 2 1 6"/><line x1="8" y1="2" x2="8" y2="18"/><line x1="16" y1="6" x2="16" y2="22"/></svg>"#

let featureColors = ["#fb94ff", "#ff618c", "#a5ff90", "#fad000", "#b362ff", "#ff9d00"]

// MARK: - Home page template

func renderHomePage(context: PageRenderingContext) -> Node {
  return layout(title: "A static site generator, written in Swift", activePage: .home) {
    // Hero with buttons
    section(class: "mx-auto max-w-5xl px-6 pt-32 pb-24 text-center md:px-8") {
      img(alt: "logo", class: "mx-auto mb-10 block w-32 md:w-48", src: "/static/saga_ship.svg")

      h1(class: "mb-5 text-5xl font-extrabold leading-tight tracking-tight text-zinc-200 md:text-6xl") {
        "Set sail with"
        span(class: "text-accent") { "Saga" }
        %","
        br()
        "a static site generator in Swift"
      }

      p(class: "mx-auto mb-10 max-w-xl text-lg leading-relaxed") {
        "Type-safe, extensible, and fast. Build your site with Swift's compile-time safety, from metadata to markup."
      }

      div(class: "flex flex-wrap justify-center gap-4") {
        a(class: "inline-flex items-center gap-2 rounded-lg bg-accent px-7 py-3 text-sm font-semibold text-white transition-all hover:-translate-y-px hover:bg-accent-hover hover:shadow-lg", href: "/docs/") {
          "Get Started"
        }
        a(class: "inline-flex items-center gap-2 rounded-lg border border-zinc-800 px-7 py-3 text-sm font-semibold text-zinc-200 transition-all hover:-translate-y-px hover:border-zinc-600 hover:bg-zinc-900", href: "https://github.com/loopwerk/Saga", target: "_blank") {
          "View on GitHub"
        }
      }
    }

    // Getting Started
    section(class: "mx-auto max-w-5xl px-8 pt-16 pb-24", id: "getting-started") {
      div(class: "grid items-center gap-12 md:grid-cols-2") {
        div {
          h2(class: "mb-3 text-3xl font-bold tracking-tight text-zinc-200") { "Up and running in seconds" }
          p(class: "mb-6 leading-relaxed") { "Install the CLI, scaffold a project, and start a dev server with auto-reload. Your site is a Swift program, ready to build and serve." }
          div(class: "flex flex-col gap-3") {
            div(class: "flex items-center gap-4") {
              span(class: "min-w-18 text-xs font-semibold uppercase tracking-widest text-zinc-500") { "Homebrew" }
              code(class: "rounded-md border border-zinc-800 bg-zinc-900 px-3 py-1.5 font-mono text-sm") { "brew install loopwerk/tap/saga" }
            }
            div(class: "flex items-center gap-4") {
              span(class: "min-w-18 text-xs font-semibold uppercase tracking-widest text-zinc-500") { "Mint" }
              code(class: "rounded-md border border-zinc-800 bg-zinc-900 px-3 py-1.5 font-mono text-sm") { "mint install loopwerk/saga-cli" }
            }
          }
        }

        // Terminal
        Node.raw(Moon.shared.highlightCodeBlocks(in: """
        <pre><code class="language-shell-session">$ saga init mysite
        $ cd mysite
        $ saga dev</code></pre>
        """))
      }
    }

    // Features
    section(class: "mx-auto max-w-5xl px-8 pt-16 pb-24", id: "features") {
      div(class: "mb-12 md:text-center") {
        h2(class: "mb-2 text-3xl font-bold tracking-tight text-zinc-200") { "Built for developers who love Swift" }
        p { "Everything you need to build fast, type-safe static sites." }
      }

      div(class: "grid gap-5 md:grid-cols-2 lg:grid-cols-3") {
        featureCard(icon: iconCode, title: "Code over Configuration", color: featureColors[0], description: "No YAML, no magic. Your site is a Swift program: explicit, readable, debuggable. Discoverable methods with auto-complete versus a hundred config options.")

        featureCard(icon: iconShield, title: "Type-Safe From Top To Bottom", color: featureColors[1], description: "Strongly typed metadata in your Markdown and type-safe HTML templates. Everything is checked by the compiler, from your data to your markup.")

        featureCard(icon: iconGlobe, title: "Internationalization", color: featureColors[2], description: "Built-in support for multilingual sites. Fully localized URLs, automatic translation linking, and a locale-aware sitemap generator.")

        featureCard(icon: iconDatabase, title: "Programmatic Content", color: featureColors[3], description: "Not everything lives on disk. Load items from APIs, databases, or any async source and run them through the same rendering pipeline.")

        featureCard(icon: iconRefresh, title: "CLI & Dev Server", color: featureColors[4], description: [
          %"A full toolchain: ",
          code(class: "font-mono [word-spacing:-0.4ch]") { "saga init" },
          %", ",
          code(class: "font-mono [word-spacing:-0.4ch]") { "saga dev" },
          %", ",
          code(class: "font-mono [word-spacing:-0.4ch]") { "saga build" },
          %". Incremental builds and live reload included.",
        ] as [Node])

        featureCard(icon: iconChevrons, title: "Extensible Pipeline", color: featureColors[5], description: "Pluggable readers, processors, and writers. Swap Markdown parsers, add syntax highlighting, chain HTML transforms. Compose your build from modular steps.")
      }
    }

    // Code Example
    section(class: "mx-auto max-w-5xl px-8 pt-8 pb-24", id: "code") {
      div(class: "mb-10 md:text-center") {
        h2(class: "mb-2 text-3xl font-bold tracking-tight text-zinc-200") { "Everything is Swift, everything is typed" }
        p(class: "text-base") { "Define your entire pipeline in Swift. From a simple blog..." }
      }
      div(class: "mx-auto max-w-3xl") {
        Node.raw(Moon.shared.highlightCodeBlocks(in: """
        <pre><code class="language-swift">struct ArticleMetadata: Metadata {
          let tags: [String]
          let summary: String
          var public: Bool = true
        }

        try await Saga(input: "articles", output: "deploy")
          .register(
            metadata: ArticleMetadata.self,
            readers: [.parsleyMarkdownReader],
            writers: [
              .itemWriter(swim(renderArticle)),
              .listWriter(swim(renderArticles), paginate: 20),
              .tagWriter(swim(renderTag), tags: \\.metadata.tags),
              .listWriter(atomFeed(
                title: "My Blog", 
                baseURL: URL(string: "https://www.example.com")
              ), output: "feed.xml"),
            ]
          )
          .run()</code></pre>
        """))
      }

      div(class: "my-10 md:text-center") {
        p(class: "text-base") { "...to a complex documentation site with API references, syntax highlighting, and HTML minification." }
      }
      div(class: "mx-auto max-w-3xl") {
        Node.raw(Moon.shared.highlightCodeBlocks(in: """
        <pre><code class="language-swift">let saga = try Saga(input: "content", output: "deploy")

        try await saga
          // Guide documentation (from DocC Markdown files)
          .register(
            folder: "docs",
            metadata: DocMetadata.self,
            readers: [.parsleyMarkdownReader],
            itemProcessor: sequence(
              processDocItem,
              syntaxHighlight,
              swiftSoupProcessor(processExternalLinks, renderToc)
            ),
            sorting: docSorting,
            writers: [.itemWriter(swim(renderDocPage))]
          )
          
          // API Reference (from symbol graph)
          .register(
            metadata: APIMetadata.self,
            fetch: { try loadSymbolGraph(rootPath: saga.rootPath) },
            writers: [
              .itemWriter(swim(renderAPIPage)),
              .listWriter(swim(renderAPIIndex), output: "api/index.html"),
            ]
          )
          
          // Landing page
          .createPage("index.html", using: swim(renderHomePage))
          
          // Minify all HTML output (prod only)
          .postProcess { html, _ in
            guard !Saga.isDev else { return html }
            return Bonsai.minifyHTML(html)
          }
          
          // Run everything!
          .run()</code></pre>
        """))
      }
    }

    // Growing Beyond
    section(class: "mx-auto max-w-5xl px-8 pt-16 pb-24", id: "beyond") {
      div(class: "mb-12 md:text-center") {
        h2(class: "mb-2 text-3xl font-bold tracking-tight text-zinc-200") { "Grows with your site" }
        p(class: "text-base") { "From a simple blog to a complex multi-content site, Saga scales with you." }
      }
      div(class: "mx-auto flex max-w-2xl flex-col gap-8", style: "--card-accent: var(--color-accent)") {
        growsWithCard(icon: iconLayers, title: "Typed metadata", description: "A single site can include blog articles with tags, a project portfolio with App Store links, movie reviews with ratings. Each with their own strongly typed metadata, indexed, paginated, or grouped independently.")
        
        growsWithCard(icon: iconDatabase, title: "Programmatic content", description: "Not all content lives on disk. Fetch items from APIs, databases, or any async data source and feed them through the same writer pipeline. Generate pages from code: landing pages, sitemaps, search indexes, 404 pages. No content file on disk needed.")
        
        growsWithCard(icon: iconGitBranch, title: "Nested processing", description: "Chain processing steps hierarchically to render complex content. Photos in albums in folders? No problem, use Saga to build your photo gallery.")

        growsWithCard(icon: iconMap, title: "Tags, feeds, and sitemaps", description: "Generate tag pages, Atom feeds, and XML sitemaps with dedicated writers. Help your visitors and search engines discover your content.")

        growsWithCard(icon: iconGlobe, title: "Internationalization", description: "Build multilingual sites with fully localized URLs, automatic translation linking, and locale-aware sitemaps.")

        growsWithCard(icon: iconChevrons, title: "Markdown attributes", description: "Add CSS classes, IDs, and custom attributes directly in your Markdown. Style content without leaving your prose.")

        growsWithCard(icon: iconSliders, title: "Your build, your rules", description: "Pre- and post-build hooks, custom processing steps, HTML transforms: generate images, build a search index, or minify output. If Swift can do it, your build can too.")
      }
    }

    // Plugins
    section(class: "mx-auto max-w-5xl px-8 pt-16 pb-24", id: "plugins") {
      div(class: "mb-12 md:text-center") {
        h2(class: "mb-2 text-3xl font-bold tracking-tight text-zinc-200") { "Modular by design" }
        p(class: "text-base") { "Compose your site with readers, renderers, and plugins that fit your needs." }
      }
      div(class: "grid gap-8 md:grid-cols-2 lg:grid-cols-3") {
        div {
          h3(class: "mb-4 text-xs font-semibold uppercase tracking-widest text-zinc-400") { "Markdown readers" }
          ul(class: "flex list-none flex-col gap-5") {
            pluginLink(name: "SagaParsleyMarkdownReader", url: "https://github.com/loopwerk/SagaParsleyMarkdownReader", detail: "Parsley")
            pluginLink(name: "SagaInkMarkdownReader", url: "https://github.com/loopwerk/SagaInkMarkdownReader", detail: "Ink + Splash")
            pluginLink(name: "SagaPythonMarkdownReader", url: "https://github.com/loopwerk/SagaPythonMarkdownReader", detail: "Python-Markdown + Pygments")
          }
        }
        div {
          h3(class: "mb-4 text-xs font-semibold uppercase tracking-widest text-zinc-400") { "Renderers" }
          ul(class: "flex list-none flex-col gap-5") {
            pluginLink(name: "SagaSwimRenderer", url: "https://github.com/loopwerk/SagaSwimRenderer", detail: "type-safe HTML with Swim")
            pluginLink(name: "SagaStencilRenderer", url: "https://github.com/loopwerk/SagaStencilRenderer", detail: "Stencil templates")
          }
        }
        div {
          h3(class: "mb-4 text-xs font-semibold uppercase tracking-widest text-zinc-400") { "Utilities" }
          ul(class: "flex list-none flex-col gap-5") {
            pluginLink(name: "SagaUtils", url: "https://github.com/loopwerk/SagaUtils", detail: "HTML transforms via SwiftSoup + String extensions")
            pluginLink(name: "SagaImageReader", url: "https://github.com/loopwerk/SagaImageReader", detail: "An image reader for Saga")
          }
        }
      }
    }

    // Ecosystem
    section(class: "mx-auto max-w-5xl px-8 pt-16 pb-24", id: "ecosystem") {
      div(class: "mb-12 md:text-center") {
        h2(class: "mb-2 text-3xl font-bold tracking-tight text-zinc-200") { "Tap into an ecosystem of Swift packages" }
        p { "Use these packages directly in your build pipeline for syntax highlighting, HTML transforms, and more." }
      }
      ul(class: "mx-auto grid max-w-2xl list-none gap-5 md:grid-cols-2") {
        pluginLink(name: "Moon", url: "https://github.com/loopwerk/Moon", detail: "Multi-language syntax highlighting")
        pluginLink(name: "Bonsai", url: "https://github.com/loopwerk/Bonsai", detail: "HTML minification")
        pluginLink(name: "SwiftSoup", url: "https://github.com/scinfu/SwiftSoup", detail: "HTML parsing, manipulation, and extraction")
        pluginLink(name: "SwiftGD", url: "https://github.com/twostraws/SwiftGD", detail: "Image generation")
        pluginLink(name: "SwiftPlot", url: "https://github.com/KarthikRIyer/swiftplot", detail: "Data visualization")
        pluginLink(name: "SwiftDate", url: "https://github.com/malcommac/SwiftDate", detail: "Easy date manipulation and formatting")
        pluginLink(name: "SwiftTailwind", url: "https://github.com/loopwerk/SwiftTailwind", detail: "TailwindCSS for Swift")
        pluginLink(name: "Sigil", url: "https://github.com/loopwerk/Sigil", detail: "SymbolKit to syntax-highlighted HTML")
      }
    }
  }
}

// MARK: - Helpers

func featureCard(icon: String, title: String, color: String, description: NodeConvertible) -> Node {
  div(class: "feature-card rounded-xl border border-zinc-800 p-7 transition-colors", style: "--card-accent: \(color)") {
    div(class: "feature-icon mb-3 flex h-9 w-9 items-center justify-center rounded-lg") {
      Node.raw(icon)
    }
    h3(class: "mb-1 font-semibold text-zinc-200") { title }
    p(class: "text-base leading-normal max-w-2xl") { description }
  }
}

func pluginLink(name: String, url: String, detail: String) -> Node {
  li(class: "flex flex-col") {
    a(class: "accent-link", href: url, target: "_blank") { name }
    span(class: "text-sm text-zinc-500") { detail }
  }
}

func growsWithCard(icon: String, title: String, description: String) -> Node {
  div(class: "flex gap-4") {
    div(class: "feature-icon flex h-9 w-9 shrink-0 items-center justify-center rounded-lg") {
      Node.raw(icon)
    }
    div {
      h3(class: "mb-1 text-lg font-bold text-zinc-200") { title }
      p(class: "text-base leading-relaxed") { description }
    }
  }
}
