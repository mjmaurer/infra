Only packages that are not available in the Nixpkgs channel should be installed via Homebrew.
Possible exceptions for GUI apps heavy on OS calls (e.g. Docker, Alfred, Reaper, etc.)

See README.md for updating homebrew packages.

## Plists

Run the following to export plists to the infra.

```
_APP_PATH=/Applications/superwhisper.app
_DOMAIN=$(mdls -name kMDItemCFBundleIdentifier $_APP_PATH | awk -F'"' '{print $2}')
defaults export $_DOMAIN - >> ~/infra/system/modules/homebrew/initial-plists/$_DOMAIN.xml
# NOTE: Clean XML before committing
```

These will be imported activation if the plist is not present.
