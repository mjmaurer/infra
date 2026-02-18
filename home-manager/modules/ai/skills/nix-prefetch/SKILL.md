---
name: nix-prefetch
description: Retrieves a hash for use in nix's fetchFromGitHub, fetchurl, fetchzip, etc  
allowed-tools: Bash(nix-prefetch-git*), Bash(nix-prefetch-url *), Bash(nix hash convert *)
disable-model-invocation: false
<!-- Claude -->
model: sonnet
context: fork
---

# nix-prefetch-git


Use nix-prefetch-git when fetching for fetchFromGitHub:


For example, we need the 'hash' value from the following for fetchFromGitHub:

```
> nix-prefetch-git https://github.com/philschmid/mcp-cli --rev v0.3.0

{
  "url": "https://github.com/philschmid/mcp-cli",
  "rev": "5cc5a628a930ded17a6e1fd5a071085c674d4bba",
  "date": "2026-01-23T13:55:36Z",
  "path": "/nix/store/yiwss8h6zid80iaa8i8crai8vxcz4vx3-mcp-cli",
  "sha256": "1pfx4c0g1yx83wlgbyysgaifgdbdp4i0zkdd1w2kaasmm6pbipab",
  "hash": "sha256-S924rqlVKzUFD63NDyK5bbXnonra+/UoH6j78AAj3d0=",
  "fetchLFS": false,
  "fetchSubmodules": false,
  "deepClone": false,
  "fetchTags": false,
  "leaveDotGit": false,
  "rootDir": ""
}
```

We want the 'hash' value.

# nix-prefetch-url

Use nix-prefetch-url when fetching URLs (i.e. for fetchurl, fetchzip, etc):

!`PAGER=cat nix-prefetch-url --help`

For example, we need the 'hash' value from the following for fetchFromGitHub:

```
> nix-prefetch-url https://github.com/pqrs-org/Karabiner-Elements/releases/download/v15.3.0/Karabiner-Elements-15.3.0.dmg --type sha256
path is '/nix/store/lr38q08fvr8a6lsr30m3yah4zc1jvc5c-Karabiner-Elements-15.3.0.dmg'
0480a7crnvhsxlcdsv65yp88k0abxzs41f5cvi084wxw22cgcdsb
```

Also, make sure to use `--unpack` if fetching a zip / other archive:

```
> nix-prefetch-url https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-1.0.2.tgz --unpack --type sha256
path is '/nix/store/cca0kg11xvfjvfv46x80i0d9gjhh8wm0-claude-code-1.0.2.tgz'
0zhkih4ngl5mkb27g22zxxyvmki6maw9h3fr96crhfcsvfizc2wr
```

When using this command, you will have to transform the fetched base32 sha256 hash to base64 sha256 using `nix hash convert`:

```
> nix hash convert --from nix32 --to base64 --hash-algo sha256 0480a7crnvhsxlcdsv65yp88k0abxzs41f5cvi084wxw22cgcdsb

Szf2mBC8c4JA3Ky4QPTvS4GJ0PXFbN0Y7Rpum9lRABE=
```

The final 'hash' attribute value for fetchurl, fetchzip, etc should be that base64 value with 'sha256-' prepended to it. For example:
`sha256-Szf2mBC8c4JA3Ky4QPTvS4GJ0PXFbN0Y7Rpum9lRABE=`

