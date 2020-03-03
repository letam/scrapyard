

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
" Note: WIP! There may be more special characters that must be substituted.
" NOTE: Borks up when faced with an inline '\n', such as in regex and commands
" like `tr` and `sed`.
fun! ExecuteBufferAndRead0(...)
	let commander = a:0 > 0 ? join(a:000, ' ') : 'bash'

	" Get row number of last line containing executable code
	let last_line_num = line('$')
	let i = 1
	while i <= last_line_num
		let line = getline(i)
		" Don't include content after this line as input code
		if line =~ "^############ CODE OUTPUT"
			let last_line_num = i - 1
			break
		endif
		let i += 1
	endw

	" Gather code contents into a string
	" Note: Use single quoted '\n' to not interpret it in vim prematurely
	let script_content = join(getline(1, last_line_num), '\n')

	" Escape special vimscript string characters before writing to file
	let script_content = substitute(script_content, '%', '\\%', 'g')
	let script_content = substitute(script_content, '!', '\\!', 'g')
	let script_content = substitute(script_content, '#', '\\#', 'g')
	let script_content = substitute(script_content, '\\n', '\\\n', 'g')

	" Create temporary script file to be executed by commander
	call system('mkdir -vp /tmp/vim/$USER')
	let tmst = Tmst()
	let filepath = system('echo "/tmp/vim/$USER/buffer-code-"')[:-2] . tmst
	exe 'silent !echo -e ' . shellescape(script_content) . ' > ' . filepath

	" DEBUG
	"exe '!cat ' . filepath
	"return

	" Position cursor to place output
	exe 'normal ' . last_line_num . 'G'
	let l = line(".")
	let c = col(".")

	" Insert label for output
	exe 'normal o############ CODE OUTPUT ' . tmst
	" Remove any indentation from previous line
	exe 'normal k^d0'

	" Execute file and read its contents
	exe "read !" . commander . " " . filepath

	" Reposition cursor
	call cursor(l+1, c)
	exe 'normal zt'

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
        if line =~ "^exit.*############"
            let last_line_num = i - 1
            break
        endif
        let i += 1
    endw

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

