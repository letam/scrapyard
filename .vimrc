

" Check if version of this vim instance supports features in this .vimrc
if 0 == has("syntax") | echo 'Does not support syntax in .vimrc file. Please use full version of vim.' | exit | endif


syntax on

set ignorecase " search will be case-insentive
set smartcase  " search will be case-sensitive if term contains an uppercase letter

"filetype plugin on
"filetype indent on

"set ruler

" Display line numbers
set number
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
  autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
augroup END

" Use tab for indents (default)
set noexpandtab

" Set tab size to 4
set tabstop=4
"set softtabstop=4
set shiftwidth=4

" Research shows that ~89 characters is optimal for reading
set colorcolumn=89

"set mouse=a

" Hide buffer of previous file instead of closing it.
" - Allow opening of another file without having t osace current one
" - Retain undo history of previous file
set hidden

" Cursor shape
" - sets the cursor to a vertical line for insert mode, underline for replace mode, and block for normal mode
let &t_SI = "\<Esc>[6 q"
let &t_SR = "\<Esc>[4 q"
let &t_EI = "\<Esc>[2 q"


"""""" maps

" Make <Esc> more accessible
inoremap jk <Esc>
vnoremap jk <Esc>

" Use space as leader key
nmap <space> <Leader>
vmap <space> <Leader>

" Shortcut to command mode (:)
nmap <leader><space> :
vmap <leader><space> :
nnoremap lk :
vnoremap lk :

" Shortcut to exit command mode
cnoremap lh <c-u><Esc>

" buffer shortcuts
map <leader>ls :ls<CR>
map <leader>bn :bnext<CR>
map <leader>bp :bprev<CR>
map <leader>bm :bprev<CR>
map <leader>bl :blast<CR>
map <leader>bf :bfirst<CR>
" Go back to the most recently used buffer in list
map <leader>bb <C-^>

" clear search highlights
map <leader>nh :nohl<CR>

" display message history
map <leader>mh :messages<CR>

" clear message history
map <leader>mc :messages clear<CR>

""""""/

"""""" set some commands

" Trim trailing spaces
fun! TrimTrailingSpaces()
	let l = line(".")
	let c = col(".")
	keeppatterns %s/\s\+$//e
	call cursor(l, c)
	"" Alternative implementation:
	"let view = winsaveview()
	"keeppatterns %s/\s\+$//e
	"call winrestview(view)
endf
command TrimTrailingSpaces call TrimTrailingSpaces()
map <leader>tw :TrimTrailingSpaces<CR>

" Toggle for "TrimTrailingSpaces on save"
let trimtrailingspaces_value = 0
fun! TrimTrailingSpacesToggle()
	augroup trimtrailingspacestoggle
		autocmd!
		if g:trimtrailingspaces_value == 0
			echom 'Turned on "TrimTrailingSpaces on save".'
			autocmd BufWrite * :call TrimTrailingSpaces()
			let g:trimtrailingspaces_value = 1
		else
			echom 'Turned off "TrimTrailingSpaces on save".'
			let g:trimtrailingspaces_value = 0
		endif
	augroup END
endf
map <leader>tat :call TrimTrailingSpacesToggle()<CR>


" Change current directory of all files to that of the active file
command CDF cd %:p:h
" Change directory to that of the active file
command LCDF lcd %:p:h


""""
" Code execution

" Execute command on current line
command Exel execute "!" . getline(".")
" Execute command on current line and insert into file
command Rexel execute "read !" . getline(".")
" Execute command in default register and insert into file at cursor
command Rexer execute "read !" . getreg("")

" Set current file to be executable by current user
command SetExecutable exe '!chmod u+x ' . expand('%')

" Execute file, and read into end of file
fun! ExecuteFileAndRead()
	exe 'normal G'
	let l = line(".")
	let c = col(".")
	execute 'normal o############ CODE OUTPUT ############'
	exe "read !" . expand("%")
	call cursor(l, c)
endf
command ExecuteFileAndRead call ExecuteFileAndRead()
command Efr call ExecuteFileAndRead()

" " quick and dirty version
command Rexef
	\ exe "normal Go############ CODE OUTPUT ############"
	\ | exe "read !" . expand("%")


fun! Tmst()
	return system('date -u +%Y-%m-%d-%H%M%S')
endf


" Execute the (code/script) contents of buffer, and read into file
" Warning: Be careful with this shit. Don't mess up your system.
fun! ExecuteBufferAndRead(...)
	let commander = a:0 > 0 ? join(a:000, ' ') : 'bash'

	 " Get row number of last line containing executable code
    let last_line_num = line('$')
    let i = 1
    while i <= last_line_num
        let line = getline(i)
        " Don't include content after this line as input code
        if line =~ "^exit.*############"
            let last_line_num = i - 1
            break
        endif
        let i += 1
    endw

	" Create temporary script file to be executed by commander
	call system('mkdir -vp /tmp/vim/$USER')
	let tmst = Tmst()
	let filepath = system('echo "/tmp/vim/$USER/buffer-"')[:-2] . tmst
	exe "normal :w " . filepath

	" Position cursor to place output
	exe 'normal ' . last_line_num . 'G'
	let l = line(".")
	let c = col(".")

	" Insert exit statement along with label for output
	exe 'normal o'
	if commander == 'bash'
		exe 'normal iexit '
	else
		exe 'normal iexit() '
	endif
	exe 'normal a############ OUTPUT ' . tmst
	" Remove any indentation from previous line
	exe 'normal k^d0'

	" Execute file and read output
	exe "read !" . commander . " " . filepath

	" Reposition cursor
	call cursor(l+1, c)
	exe 'normal zt'

endf
command -nargs=* ExecuteBufferAndRead call ExecuteBufferAndRead(<f-args>)
command -nargs=* Ebr call ExecuteBufferAndRead(<f-args>)
map <leader>exe :call ExecuteBufferAndRead()<CR>


""""/


" ctags generation
command CtagsGen !ctags --exclude=node_modules --exclude='*.min.*' --recurse .
command CtagsAppend !ctags --exclude=node_modules --exclude='*.min.*' --recurse --append .


" ctags shortcut
map <leader>ct :tag<space>


" `tail -f` function for reading a live-updated log feed
	" Thanks:
	" https://unix.stackexchange.com/questions/82058/how-do-i-make-vim-behave-like-tail-f/527916#527916
exe ":function Tail(timer) \n :exe 'normal :e!\<ENTER>G' \n endfunction"
command Tail exe timer_start(2000, 'Tail', {'repeat':-1})

command TimeStopAll exe timer_stopall()


""""""/


"""""" Colorscheme
" Good base color scheme
color elflord


" set color column color
let columnColor = "darkgray"
"let columnColor = "darkcyan"
"let columnColor = "magenta"
au VimEnter * execute "highlight ColorColumn ctermbg=" . columnColor
"call matchadd('ColorColumn', '\%81v', 100)


fun! Color(...)
	" Set color scheme and column color
	" Usage: Color elflord darkgray

	"let color = a:0 >= 1 ? a:1 : "elflord"
	let color = get(a:, 1, "elflord")
	"let columnColor = a:0 >= 2 ? a:2 : g:columnColor
	let columnColor = get(a:, 2, g:columnColor)

	try
		execute "color " . color
	catch /.*/
		echo 'ERROR: ' . v:exception
		return
	endtry
	execute "highlight ColorColumn ctermbg=" . columnColor
endf
command -nargs=* Color call Color(<f-args>)

""""""/


"""""" Python support for neovim
if has('nvim')
	let g:python3_host_prog = '~/.vim/venv/bin/python'
	"let g:black_skip_string_normalization = 1
elseif has('unix') && !has('mac')
	command Black !~/.vim/venv/bin/black -S %:p
endif
""""""/


"""""" Editor behavior stuff

au VimEnter * call TrimTrailingSpacesToggle()


""""""/


"""""" Plugins with vim-plug

" Install vim-plug if not found
"if has('nvim') && empty(glob('~/.config/nvim/site/autoload/plug.vim'))
"    silent !curl -fLo ~/.config/nvim/site/autoload/plug.vim --create-dirs
if has('nvim') && empty(glob('~/.vim/autoload/plug.vim'))
	silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
		\ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
elseif !has('nvim') && empty(glob('~/.vim/autoload/plug.vim'))
	silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
		\ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	autocmd VimEnter * PlugInstall --sync | exe ':qa'
endif

" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
if has('nvim')
	call plug#begin('~/.config/nvim/plugged')
else
	call plug#begin('~/.vim/plugged')
endif

" Unmanaged plugin (manually installed and updated)
""Plug '~/my-prototype-plugin'

"""
" NERDTree
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }

" open automatically if no files were specified
"autocmd StdinReadPre * let s:std_in=1
"autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" open automatically if opening a dir
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | endif

" open with CTRL+n
map <C-n> :NERDTreeToggle<CR>

"""/

" Display file type icons
Plug 'ryanoasis/vim-devicons'
if !has('nvim')
	set encoding=UTF-8
endif

" Git status in the gutter
Plug 'airblade/vim-gitgutter'
set updatetime=100

" Plugin outside ~/.vim/plugged with post-update hook
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
map <leader>ff :FZF<CR>
map <leader>ft :Tags<CR>
map <leader>fb :BTags<CR>

" powerline
Plug 'vim-airline/vim-airline'

" Startscreen dashboard
Plug 'mhinz/vim-startify'

" NERDTree git status
Plug 'Xuyuanp/nerdtree-git-plugin'

" WakaTime time tracking
Plug 'wakatime/vim-wakatime'

" Comment functions
Plug 'scrooloose/nerdcommenter'

" editorconfig
Plug 'editorconfig/editorconfig-vim'

" enhanced in-buffer search
Plug 'junegunn/vim-slash'

" sneak motion/navigation
Plug 'justinmk/vim-sneak'

" colorschemes
Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'romainl/Apprentice'
Plug 'cormacrelf/vim-colors-github'
Plug 'nightsense/cosmic_latte'

" surround.vim: quoting/parenthesizing made simple
Plug 'tpope/vim-surround'

" unimpaired.vim: keyboard shortcutes
Plug 'tpope/vim-unimpaireD'

" repeat.vim: repeat last plugin action
Plug 'tpope/vim-repeat'

" DB Interaction
Plug 'tpope/vim-dadbod'

" Fish shell
Plug 'dag/vim-fish'

" Nginx
Plug 'chr4/nginx.vim'

" Python Syntax
Plug 'vim-python/python-syntax'
let g:python_highlight_all = 1

" JavaScript Syntax
Plug 'pangloss/vim-javascript'
Plug 'MaxMEllon/vim-jsx-pretty'
let g:vim_jsx_pretty_colorful_config = 1

" TypeScript Syntax
Plug 'leafgarland/typescript-vim'
Plug 'peitalin/vim-jsx-typescript'

" YouCompleteMe Autocompletion and intellisense
"Plug 'Valloric/YouCompleteMe'

""""--
if $USER != 'root' " Ignore if $USER is root

" expand abberviations
Plug 'mattn/emmet-vim'

"Plug 'sheerun/vim-polyglot'

"""
" Snippets with ultisnips
" Track the engine.
Plug 'SirVer/ultisnips'

" Snippets are separated from the engine. Add this if you want them:
Plug 'honza/vim-snippets'

" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-g>"
let g:UltiSnipsJumpBackwardTrigger="<c-b>"

" If you want :UltiSnipsEdit to split your window.
let g:UltiSnipsEditSplit="vertical"
map <leader>ss :UltiSnipsEdit<CR>

"""/

"""
" Tagbar
Plug 'majutsushi/tagbar'
map <leader>tb :TagbarToggle<CR>
"""/

"""
" gutentags for efficient ctag updates
if !has('nvim')
	Plug 'ludovicchabant/vim-gutentags'
endif

"""
" CtrlP
Plug 'ctrlpvim/ctrlp.vim'
let g:ctrlp_map = '<c-p>'
set wildignore+=*.pyc,
let g:ctrlp_custom_ignore = {
	\ 'dir':  '\v[\/]\.(git|hg|svn)$',
	\ 'file': '\v\.(exe|so|dll)$',
	\ 'link': 'some_bad_symbolic_links',
	\ }

map <leader>cp :CtrlPMixed<CR>
map <leader>cpx :CtrlPMixed<CR>
map <leader>cpb :CtrlPBuffer<CR>
map <leader>cpr :CtrlPMRU<CR>
map <leader>cpp :CtrlP<CR>
"""/

"""
" Distraction-free writing in vim
Plug 'junegunn/goyo.vim'
"""/

"""
" hyperfocus-writing in vim
Plug 'junegunn/limelight.vim'
	" Color name (:help cterm-colors) or ANSI code
let g:limelight_conceal_ctermfg = 'gray'
"let g:limelight_conceal_ctermfg = 240
"""/

"""
" Python formatter
if has('nvim') || has('mac')
	"let g:black_virtualenv = '~/.vim/venv'
	Plug 'psf/black'
endif
"""/

"""
" Text outlining and Task management
Plug 'jceb/vim-orgmode'
"""/

"""
" Plain Tasks
Plug 'elentok/plaintasks.vim'
"""/


endif " Ignore as root
""""--


" Initialize plugin system
call plug#end()

"""""/



""""" set colorscheme

" Function for additional settings needed for dracula theme on macOS
fun! ColorDracula()
	let g:dracula_italic = 0
	color dracula
	highlight Normal ctermbg=None
endf
command ColorDracula call ColorDracula()

fun! ColorGithub()
	color github

	" if you use airline / lightline
	"let g:airline_theme = "github"
	"let g:lightline = { 'colorscheme': 'github' }
endf
command ColorGithub call ColorGithub()

"color apprentice

fun! ColorCosmic()
	set termguicolors
	if strftime('%H') >= 7 && strftime('%H') < 19
	  set background=light
	  let g:lightline = { 'colorscheme': 'cosmic_latte_light' }
	else
	  set background=dark
	  let g:lightline = { 'colorscheme': 'cosmic_latte_dark' }
	endif
	colorscheme cosmic_latte
endf
command ColorCosmic call ColorCosmic()


" Activate theme
if has('mac') || system('uname -a') =~ 'Ubuntu'
	ColorDracula
else
	ColorCosmic
endif

"""""/


""""""/
