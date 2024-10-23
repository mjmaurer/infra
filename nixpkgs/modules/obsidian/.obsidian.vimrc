" https://meleu.dev/notes/obcommand-list/

" Yank to system clipboard
set clipboard=unnamed

unmap <Space>

" Search Files
exmap search obcommand switcher:open
nmap <Space>o :search<CR>

" Search Headings
exmap headings obcommand darlal-switcher-plus:switcher-plus:open-symbols-active
nmap <Space>i :headings<CR>

" Search Commands
exmap command obcommand command-palette:open
nmap <Space>p :command<CR>

" Global Text Search
exmap gfind obcommand global-search:open
nmap <Space>/ :gfind<CR>

" Daily Note 
exmap daily obcommand daily-notes 
nmap <Space>d :daily<CR>

" Go back and forward 
exmap back obcommand app:go-back
nmap H :back<CR>
exmap forward obcommand app:go-forward
nmap L :forward<CR>

" Tab navigation
exmap tabnext obcommand workspace:next-tab
nmap J :tabnext<CR>
exmap tabprev obcommand workspace:previous-tab
nmap K :tabprev<CR>
