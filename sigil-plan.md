# What to extract

Layer 1: Pure SymbolKit utilities (no dependencies beyond SymbolKit)
- renderFragment() / renderDeclaration() — fragment → syntax-highlighted HTML with multi-line formatting
- checkDeprecation() — availability → (isDeprecated, message)
- SymbolKind enum — kind identifier → display names, plural forms, ordering, top-level classification
- escapeHTML() — used throughout

Layer 2: Symbol graph traversal
- groupMembersByParent() — relationship graph → parent-to-member ID mapping
- collectConformances() — relationship graph → conformance mapping (with pluggable URL generation)
- resolveMembers() — symbol IDs → filtered, sorted public member structs
- Extension symbol graph merging logic — aggregate multiple Module@Ext.symbols.json files by type

Layer 3: Doc comment processing
- renderDocComment() — extract and join doc comment lines (the markdown→HTML step stays in getsaga.dev since it depends on Parsley/Moon)
- rewriteMarkdown() — DocC syntax (Symbol, <doc:File>) → standard markdown links (with pluggable URL builder)
- extractSymbolMentions() — find DocC symbol references in markdown
- Parameter/return value rendering from Utils.swift

# What stays in getsaga.dev

- Saga Item<APIMetadata> construction
- Templates (Swim/HTML)
- Moon/Parsley integration
- Site-specific URL patterns and slugs
