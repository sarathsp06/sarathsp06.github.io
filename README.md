# sarathsp06.github.io

User site for the `sarathsp06.github.io` origin. It holds only the files that must sit at the
origin root, which project sites like [Sparrow's docs](https://sarathsp06.github.io/sparrow/)
(served under `/sparrow/`) cannot publish:

- `.well-known/security.txt` ([RFC 9116](https://www.rfc-editor.org/rfc/rfc9116)): the security
  contact for every project site on this origin, not only Sparrow. Renew `Expires` before
  2027-10-01: an expired file counts as stale.
- `robots.txt`: crawlers only read it from the root, so it lists the docs sitemap.
- `.nojekyll`: Jekyll skips dot-directories, which would drop `.well-known/`.

Pages source: `main` branch, `/` (root).
