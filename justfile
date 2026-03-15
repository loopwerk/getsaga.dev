# Development: watch and rebuild on changes
run: clean copy-docs symbol-graph
  saga dev --ignore output.css --ignore "content/docs/*"

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
  cp -r .build/checkouts/Saga/Sources/Saga/Saga.docc/* content/docs/
  mv content/docs/Saga.md content/docs/index.md
  [ -d content/docs/Guides ] && mv content/docs/Guides content/docs/guides || true

# Generate symbol graph from the Saga library
symbol-graph:
  swift package --package-path .build/checkouts/Saga dump-symbol-graph --emit-extension-block-symbols 2>/dev/null || true
  mkdir -p .build/symbolgraph
  cp .build/checkouts/Saga/.build/*/symbolgraph/Saga.symbols.json .build/symbolgraph/
  cp .build/checkouts/Saga/.build/*/symbolgraph/Saga@*.symbols.json .build/symbolgraph/ 2>/dev/null || true

# Clean build artifacts
clean:
  rm -rf deploy .build/symbolgraph content/docs

format:
  swiftformat -swift-version 6 .
