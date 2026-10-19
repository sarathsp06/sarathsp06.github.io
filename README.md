# well-known root files for GitHub Pages

The files that have to sit at the root of `https://<you>.github.io/`, generated from one
config file and kept current by CI. Project sites (`<you>.github.io/<repo>/`) cannot publish
these themselves: crawlers and scanners only look at the origin root, and only the
`<you>.github.io` repository can write there.

| File | Standard | What it is for |
|------|----------|----------------|
| `/.well-known/security.txt` | [RFC 9116](https://www.rfc-editor.org/rfc/rfc9116) | Where to report a vulnerability in any of your sites. `Expires` is renewed on every build |
| `/robots.txt` | [RFC 9309](https://www.rfc-editor.org/rfc/rfc9309) | Crawl rules; lists your project sitemaps (a `/<repo>/robots.txt` is never read) |
| `/sitemap.xml` | [sitemaps.org](https://www.sitemaps.org/protocol.html) | Sitemap index pointing at each project's sitemap |
| `/llms.txt` | [llmstxt.org](https://llmstxt.org/) | Short Markdown index of your projects for LLM tools (optional) |
| `/404.html` | GitHub Pages | Shown for paths that belong to no project |

Live example: <https://sarathsp06.github.io/.well-known/security.txt>.

## Use it for your own site

1. **Use this template** (green button) and name the new repository `<your-user>.github.io`.
   A fork works too, but GitHub turns off Actions on forks until you enable them.
2. In the new repository: **Settings → Pages → Source: GitHub Actions**.
3. Clone it and set your details:

   ```sh
   make configure SECURITY_CONTACTS="you@example.org https://github.com/<you>/<repo>/security/advisories/new" \
     SITEMAPS="https://<you>.github.io/<repo>/sitemap-index.xml" SECURITY_NOTES="" PROJECTS=""
   ```

   `OWNER` is taken from your git remote. Every setting is documented in [`site.conf`](site.conf);
   edit it directly for multi-line values such as `PROJECTS`.
4. `make check` to build into `_site/` and validate, then commit `site.conf` and push.

Until `site.conf` names your account, CI refuses to deploy, so a new copy never goes live with
someone else's contact details.

## Make targets

```text
make configure KEY=value ...  write settings to site.conf
make build                    render into _site/
make check                    build, then validate (RFC 9116 checks, plus sectxt if installed)
make check-live               validate what GitHub Pages is serving
make serve                    preview _site/ on http://localhost:8000
```

`sectxt` is the validator behind [internet.nl](https://internet.nl): `pip install sectxt`.

## CI/CD

[`.github/workflows/pages.yml`](.github/workflows/pages.yml) runs on every push, on pull requests
(build and validate only), on the 1st of each month, and on demand:

1. **build**: `make check`, failing on an invalid security.txt or a near or too-distant `Expires`.
2. **deploy**: publishes `_site/` to GitHub Pages.
3. **verify**: `make check-live` against the real URLs (status, `text/plain; charset=utf-8`,
   sectxt). On the monthly run it also re-enables the workflow, because GitHub disables
   schedules after 60 days without repository activity, and a stopped schedule would let
   security.txt expire.

With the default `EXPIRES_DAYS=180` and a monthly rebuild, the file always has 150+ days left.

## Adding more files

Anything in [`static/`](static/) is published as-is and overrides a generated file of the same
name: a `favicon.ico`, an `index.html`, or other `/.well-known/` entries. GitHub Pages picks the
`Content-Type` from the file extension, so files without one (some `.well-known` names) are
served as `application/octet-stream`; check with `curl -sI` before relying on them.

Deliberately left out: `change-password` and `webfinger` (they need redirects or
query-dependent answers, which static hosting cannot do), `gpc.json` and `dnt-policy.txt`
(nothing to opt out of on a static site), and OpenPGP signing of security.txt (worth it only
if you maintain a key; add `SECURITY_ENCRYPTION` when you do).

## License

[MIT-0](LICENSE): copy it without attribution.
