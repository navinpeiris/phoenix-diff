# Phoenix Diff

[![Build Status](https://travis-ci.org/navinpeiris/phoenix-diff.svg?branch=master)](https://travis-ci.org/navinpeiris/phoenix-diff)

A phoenix application to show the changes between different versions of generated phoenix apps, which makes it easy to upgrade an existing app with latest changes.

Currently hosted at [http://www.phoenixdiff.org](http://www.phoenixdiff.org)

## Set up

PhoenixDiff uses [Earthly](https://earthly.dev) to be generate sample projects to use with diffs:

### OS X
1. Install Docker for Mac
1. Install Earthly (`brew install earthly`)

### Linux

1. Install Docker
1. Add yourself to the `docker` group so you don't have to use sudo to run docker. `sudo usermod -aG docker <your-user>`
1. Install Earthly
1. Create the follow earthly config file (`~/.earthly/config.yml`) so it works without having to use sudo

    ```yaml
    global:
      buildkit_additional_args: ["--userns", "host"]
    ```

## Adding a new version of phoenix

To add a new version of phoenix, run the following mix command

```
mix phx_diff.add <phoenix-version>
```

The above mix task uses the following two tasks behind the hood:

- `mix phx_diff.gen.sample` - Generates a sample app for the given version
- `mix phx_diff.gen.diffs` - Generates the diff files between all the different versions
