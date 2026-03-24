# Path to the Saga library (local path dependency or SPM checkout)
saga_path := if path_exists("../Saga/Sources/Saga") == "true" { "../Saga" } else { ".build/checkouts/Saga" }

# Development: watch and rebuild on changes
run: clean resolve copy-docs symbol-graph
  saga dev

# Resolve SPM dependencies
resolve:
  swift package resolve

# Compile without running
compile:
  swift build --product Website -j 2

# Full build
build: copy-docs symbol-graph
  swift run

# Copy DocC guide markdown files into content/docs/
copy-docs:
  rm -rf content/docs
  mkdir -p content/docs
  cp -r {{saga_path}}/Sources/Saga/Saga.docc/* content/docs/
  mv content/docs/Saga.md content/docs/index.md
  [ -d content/docs/Guides ] && mv content/docs/Guides content/docs/guides || true

# Generate symbol graph from the Saga library
symbol-graph:
  swift package --package-path {{saga_path}} dump-symbol-graph --emit-extension-block-symbols 2>/dev/null || true
  mkdir -p .build/symbolgraph
  cp {{saga_path}}/.build/*/symbolgraph/Saga.symbols.json .build/symbolgraph/
  cp {{saga_path}}/.build/*/symbolgraph/Saga@*.symbols.json .build/symbolgraph/ 2>/dev/null || true

# Clean build artifacts
clean:
  rm -rf deploy .build/symbolgraph .build/checkouts/Saga content/docs

format:
  swiftformat -swift-version 6 .
