# The website

The [website](https://ssc-ng.net/archive/) is a Jekyll site (just-the-docs theme, with the look shared across SSC-NG sites from [ssc-ng-theme](https://github.com/ssc-ng/theme)) in this directory. Its package browser loads data asynchronously from static JSON files generated at build time by [`build_data.py`](build_data.py); pull requests get a Cloudflare Pages preview (see [`DEPLOY-PREVIEW.md`](DEPLOY-PREVIEW.md)).
