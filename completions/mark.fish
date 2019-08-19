function __mark_no_command
	set cmd (commandline -opc)
	test (count $cmd) -eq 1
	return
end

#Commands
complete -c mark -n '__mark_no_command' -x -d "open the mark store file" -a "edit"
complete -c mark -n '__mark_no_command' -x -d "print marks" -a "print"
