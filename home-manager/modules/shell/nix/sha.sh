
get_archive_sha() {
    echo "Should be archive path (.tar.gz / .zip)"
    archive = $1
    nix hash to-sri --type sha256 $(nix-prefetch-url --unpack $archive)
}