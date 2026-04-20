import HTML
import Saga

let searchSVG = #"<svg class="h-5 w-5 fill-none stroke-current stroke-2" viewBox="0 0 24 24" style="stroke-linecap:round;stroke-linejoin:round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>"#

let githubSVG = #"<svg class="h-5 w-5 fill-current" viewBox="0 0 16 16"><path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z"/></svg>"#

enum Page {
  case home
  case docs
  case api
  case other
}

func layout(title pageTitle: String, activePage: Page, @NodeBuilder children: () -> NodeConvertible) -> Node {
  return [
    .documentType("html"),
    html(lang: "en") {
      head {
        meta(charset: "UTF-8")
        meta(content: "width=device-width, initial-scale=1.0", name: "viewport")
        title { "Saga - \(pageTitle)" }
        link(href: Saga.hashed("/static/output.css"), rel: "stylesheet")
        link(href: Saga.hashed("/static/prism.css"), rel: "stylesheet")
        link(href: "/static/favicon-96x96.png", rel: "icon", sizes: "96x96", type: "image/png")
        link(href: "/static/favicon.svg", rel: "icon", type: "image/svg+xml")
        link(href: "/static/favicon.ico", rel: "shortcut icon")
        link(href: "/static/apple-touch-icon.png", rel: "apple-touch-icon", sizes: "180x180")
        meta(content: "Saga", name: "apple-mobile-web-app-title")
        meta(content: "#18181a", name: "theme-color")
        link(href: "/static/site.webmanifest", rel: "manifest")
        if !Saga.isDev {
          script(defer: true, src: "/script.js", customAttributes: ["data-website-id": "695938bd-cbf4-4702-9c0c-0e4e9a619710"])
        }
      }

      body(class: "bg-[#1c1a22] text-zinc-200 font-sans leading-relaxed antialiased \(activePage)") {
        div(class: "fixed inset-x-0 top-0 z-50 h-16 border-b border-zinc-800 bg-zinc-900 sm:bg-zinc-900/80 sm:backdrop-blur-xl") {
          nav(class: "mx-auto flex h-full max-w-5xl items-center justify-between px-8") {
            a(class: "flex items-center", href: "/") {
              img(alt: "Saga", class: "h-4 md:h-6 w-auto mt-1.5", src: "/static/saga_word.svg")
            }
            ul(class: "flex list-none items-center gap-4 md:gap-8") {
              li {
                a(class: "text-sm transition-colors hover:text-zinc-200\(activePage == .docs ? " text-zinc-200" : "")", href: "/docs/") {
                  span(class: "hidden md:inline") {
                    "Documentation"
                  }
                  span(class: "inline md:hidden") {
                    "Docs"
                  }
                }
              }
              li {
                a(class: "text-sm transition-colors hover:text-zinc-200\(activePage == .api ? " text-zinc-200" : "")", href: "/api/") {
                  span(class: "hidden md:inline") {
                    "API reference"
                  }
                  span(class: "inline md:hidden") {
                    "API"
                  }
                }
              }
              li {
                a(class: "text-sm transition-colors hover:text-zinc-200", href: "https://www.loopwerk.io/open-source/support/", target: "_blank") { "Support" }
              }
              li {
                a(class: "flex items-center transition-colors hover:text-zinc-200", href: "/search/", customAttributes: ["aria-label": "Search"]) {
                  Node.raw(searchSVG)
                }
              }
              li {
                a(class: "flex items-center transition-colors hover:text-zinc-200", href: "https://github.com/loopwerk/Saga", target: "_blank", customAttributes: ["aria-label": "GitHub"]) {
                  Node.raw(githubSVG)
                }
              }
            }
          }
        }

        div(class: "background") {
          children()
        }

        footer(class: "pb-12 text-center") {
          p(class: "text-zinc-500 text-sm") {
            "This site is built with"
            a(class: "accent-link", href: "https://github.com/loopwerk/Saga", target: "_blank") { "Saga" }
            %" ("
            %a(class: "accent-link", href: "https://github.com/loopwerk/getsaga.dev", target: "_blank") { "source" }
            %")."
          }
          p(class: "text-zinc-500 text-sm") {
            "©"
            a(class: "hover:underline", href: "https://www.loopwerk.io", target: "_blank") { "Loopwerk" }
            %". All rights reserved."
          }
        }
      }
    },
  ]
}

func renderReleaseNotesRedirect(context: PageRenderingContext) -> String {
  let major = context.allItems.compactMap { $0 as? Item<ReleaseMetadata> }.sorted { $0.date > $1.date }.first?.metadata.major ?? 3
  return Saga.redirectHTML(to: "/docs/releasenotes/\(major).x/")
}

func render404Page(context: PageRenderingContext) -> Node {
  layout(title: "Page not found", activePage: .other) {
    section(class: "mx-auto max-w-5xl px-6 pt-32 pb-24 text-center") {
      img(alt: "Saga", class: "mx-auto mb-10 block w-32 md:w-48", src: "/static/saga_ship.svg")
      h1(class: "mb-4 text-4xl font-bold text-zinc-200") { "404 Lost at Sea" }
      p(class: "mb-8 text-lg") { "The page you're looking for doesn't exist." }
      a(class: "inline-flex items-center gap-2 rounded-lg bg-accent px-7 py-3 text-sm font-semibold text-white transition-all hover:-translate-y-px hover:bg-accent-hover hover:shadow-lg", href: "/") {
        "Back to home"
      }
    }
  }
}

func renderSearch(context: PageRenderingContext) -> Node {
  layout(title: "Search", activePage: .other) {
    script(src: Saga.hashed("/static/prism.js"))
    script {
      Node.raw(
        """
        async function initSearch() {
          const pagefind = await import("/pagefind/pagefind.js");
          await pagefind.init();

          const input = document.getElementById("search");
          const summary = document.getElementById("summary");
          const results = document.getElementById("results");
          let debounce = null;

          async function doSearch(query) {
            if (!query) {
              summary.textContent = "";
              results.innerHTML = "";
              return;
            }
            const search = await pagefind.search(query);
            summary.textContent = search.results.length + " result" + (search.results.length !== 1 ? "s" : "") + " for \\u201c" + query + "\\u201d";

            results.innerHTML = "";
            const loaded = await Promise.all(search.results.slice(0, 20).map(r => r.data()));
            loaded.sort((a, b) => (a.meta.kind === "Topic" ? 0 : 1) - (b.meta.kind === "Topic" ? 0 : 1));
            for (const result of loaded) {
              const item = document.createElement("a");
              item.href = result.url;
              item.className = "search-result";

              const kind = result.meta.kind;
              const declaration = result.meta.declaration;

              let header = '<span class="text-lg font-bold">' + result.meta.title + '</span>';
              if (kind) {
                header = '<span class="text-xs font-semibold uppercase tracking-wide text-zinc-400 mr-2">' + kind + '</span>' + header;
              }
              item.innerHTML = '<div class="search-result-header">' + header + '</div>';

              if (declaration) {
                const pre = document.createElement("pre");
                pre.className = "search-result-declaration";
                const code = document.createElement("code");
                code.className = "language-swift";
                code.textContent = declaration;
                pre.appendChild(code);
                item.appendChild(pre);
                if (typeof Prism !== "undefined") {
                  Prism.highlightElement(code);
                }
              }

              if (result.excerpt) {
                const excerpt = document.createElement("p");
                excerpt.className = "search-result-excerpt";
                excerpt.innerHTML = result.excerpt;
                item.appendChild(excerpt);
              }

              results.appendChild(item);
            }
          }

          input.addEventListener("input", () => {
            clearTimeout(debounce);
            debounce = setTimeout(() => {
              const q = input.value;
              const url = new URL(window.location);
              url.searchParams.set("q", q);
              history.replaceState(null, "", url);
              doSearch(q);
            }, 200);
          });

          const q = new URLSearchParams(window.location.search).get("q");
          if (q) {
            input.value = q;
            doSearch(q);
          }

          input.focus();
        }
        initSearch();
        """
      )
    }

    section(class: "mx-auto max-w-5xl px-6 pt-32 pb-24") {
      form(action: "/search/", class: "relative mb-8", id: "search-form") {
        Node.raw(#"<div class="search-icon">\#(searchSVG)</div>"#)
        input(class: "w-full rounded-xl border border-zinc-800 bg-zinc-950 py-3 pr-4 pl-12 text-base text-zinc-200 placeholder-zinc-500 outline-none transition-colors focus:border-zinc-600", id: "search", name: "q", placeholder: "Search documentation...", type: "text", customAttributes: ["autocomplete": "off"])
      }

      p(class: "text-sm text-zinc-400 mb-8", id: "summary")
      div(id: "results")
    }
  }
}
