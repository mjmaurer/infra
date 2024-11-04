" ------ style ----------"
" set t_Co=256
syntax on
if has('termguicolors')
	set termguicolors
endif
" Causes issues with nix
" let g:gruvbox_material_better_performance = 1 
let g:gruvbox_material_background = 'hard'
set background=light
colorscheme gruvbox-material
"================Spaces and Tabs==========="
set tabstop=4
set softtabstop=4
set expandtab
set shiftwidth=4
"==================UI Config==============="
set number
set showcmd
set cursorline
filetype indent on
set showmatch
set laststatus=2
"-------  normal mappings -------------"
nmap J :bp<cr>
nmap K :bn<cr>
