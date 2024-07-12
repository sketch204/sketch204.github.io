# Personal Webpage

This repository contains my personal website hosted under [inalgotov.com](https://inalgotov.com). It is built with [Rocket](https://github.com/sketch204/rocket) and hosted using GitHub pages.

## Building locally

Use the local config file for building the site for local testing

```sh
./scripts/rocket -c rocket.local.toml
```

## FAQ

#### How to link to site resources, such as images or other pages.
Define the full output path to the resource as it would appear in the built site and pass that through the `site_url` filter. For example, to link to a page which would be built from `posts/blog.md`, I would use the following reference on my page:

```markdown
{{ "/posts/blog.html"|site_url }}
```

This will be expanded into a complete URL that you can use as an `href` for an anchor tag or as the URL for a markdown link.
