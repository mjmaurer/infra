" https://meleu.dev/notes/obcommand-list/

" Yank to system clipboard
set clipboard=unnamed

unmap <Space>

" Search
exmap search obcommand switcher:open
nmap <Space>o :search

" Command
exmap command obcommand command-palette:open
nmap <Space>p :command

" Global Find
exmap gfind obcommand global-search:open
nmap <Space>/ :gfind

" Daily Note 
exmap daily obcommand daily-notes 
nmap <Space>d :daily

" Go back and forward 
exmap back obcommand app:go-back
nmap H :back
exmap forward obcommand app:go-forward
nmap L :forward

# Tab navigation
exmap tabnext obcommand workspace:next-tab
nmap J :tabnext
exmap tabprev obcommand workspace:previous-tab
nmap K :tabprev
