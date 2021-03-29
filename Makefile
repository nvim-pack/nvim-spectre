test:
	nvim --headless --noplugin -u tests/minimal.vim -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal.vim'}"

	nvim --headless --noplugin -u tests/minimal.vim -c "PlenaryBustedFile tests/ui_spec {minimal_init = 'tests/minimal.vim'}"


