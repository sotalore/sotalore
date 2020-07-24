PgSearch.multisearch_options = {
  using: {
    tsearch: { prefix: true, normalization: 2 },
    trigram: { threshold: 0.2 }
  }
}
