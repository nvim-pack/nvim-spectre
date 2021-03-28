set rtp +=.
set rtp +=../plenary.nvim/
set rtp +=../popup.nvim

runtime! plugin/plenary.vim

set nowritebackup
set noswapfile
set nobackup


lua << EOF
require('spectre.init')
EOF

