#!/bin/bash

_fzf_search_alias() {
    alias | sed 's/^alias //' | \
        fzf --prompt="Search aliases: " \
            --preview="echo {}" \
            --preview-window=down:3:wrap | \
        awk -F= '{print $1}'
}