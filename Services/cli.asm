; ==================================================================
; MikeOS -- The Mike Operating System kernel
; Copyright (C) 2006 - 2019 MikeOS Developers -- see doc/LICENSE.TXT
;
; COMMAND LINE INTERFACE
; ==================================================================


os_command_line:
	call os_clear_screen

	mov si, version_msg
	call os_print_string
	call os_print_newline

	mov bx, tmp_string
	call os_get_date_string
	mov si, bx
	call os_print_string

	empty_space_ db ' ', 0
	mov si, empty_space_
	call os_print_string

	mov bx, tmp_string
	call os_get_time_string
	mov si, bx
	call os_print_string
	call os_print_newline
	call os_print_newline

	mov si, list_text
	call os_print_string

	jmp get_cmd

get_cmd:				; Main processing loop
	mov di, command			; Clear single command buffer
	mov cx, 32
	rep stosb

	mov si, prompt			; Main loop; prompt for input
	call os_print_string

	mov ax, input			; Get command string from user
	mov bx, 64
	call os_input_string

	call os_print_newline

	mov ax, input			; Remove trailing spaces
	call os_string_chomp

	mov si, input			; If just enter pressed, prompt again
	cmp byte [si], 0
	je get_cmd

	mov si, input			; Separate out the individual command
	mov al, ' '
	call os_string_tokenize

	mov word [param_list], di	; Store location of full parameters

	mov si, input			; Store copy of command for later modifications
	mov di, command
	call os_string_copy



	; First, let's check to see if it's an internal command...

	mov ax, input
	call os_string_uppercase

	mov si, input

	mov di, exit_string		; 'EXIT' entered?
	call os_string_compare
	jc near exit

	mov di, list_string		; 'LIST' entered?
	call os_string_compare
	jc near print_list

	mov di, seqlist_string
	call os_string_compare
	jc near print_seqlist

	mov di, help_string 		; 'HELP' entered?
	call os_string_compare
	jc near print_help

	mov di, cls_string		; 'CLS' entered?
	call os_string_compare
	jc near clear_screen

	mov di, clear_string		; 'CLEAR' entered?
	call os_string_compare
	jc near clear_screen

	mov di, dir_string		; 'DIR' entered?
	call os_string_compare
	jc near list_directory

	mov di, ver_string		; 'VER' entered?
	call os_string_compare
	jc near print_ver

	mov di, shellinfo_string
	call os_string_compare
	jc near shell_info

	mov di, osfetch_string
	call os_string_compare
	jc near osfetch_tool

	mov di, diskinfo_string
	call os_string_compare
	jc near diskinfo_tool

	mov di, time_string		; 'TIME' entered?
	call os_string_compare
	jc near print_time

	mov di, date_string		; 'DATE' entered?
	call os_string_compare
	jc near print_date

	mov di, ftime_string		; 'FTIME' entered?
	call os_string_compare
	jc near print_ftime

	mov di, cat_string		; 'CAT' entered?
	call os_string_compare
	jc near cat_file

	mov di, del_string		; 'DEL' entered?
	call os_string_compare
	jc near del_file

	mov di, copy_string		; 'COPY' entered?
	call os_string_compare
	jc near copy_file

	mov di, echo_string
	call os_string_compare
	jc near echo_screen

	mov di, ren_string		; 'REN' entered?
	call os_string_compare
	jc near ren_file

	mov di, size_string		; 'SIZE' entered?
	call os_string_compare
	jc near size_file

	mov di, ls_string		; 'LS' entered?
	call os_string_compare
	jc dir_list


	; If the user hasn't entered any of the above commands, then we
	; need to check for an executable file -- .BIN or .BAS, and the
	; user may not have provided the extension

	mov ax, command
	call os_string_uppercase
	call os_string_length


	; If the user has entered, say, MEGACOOL.BIN, we want to find that .BIN
	; bit, so we get the length of the command, go four characters back to
	; the full stop, and start searching from there

	mov si, command
	add si, ax

	sub si, 4

	mov di, bin_extension		; Is there a .BIN extension?
	call os_string_compare
	jc bin_file

	mov di, bas_extension		; Or is there a .BAS extension?
	call os_string_compare
	jc bas_file

	mov di, pcx_extension		; Or is there a .PCX extension?
	call os_string_compare
	jc total_fail

	jmp no_extension


bin_file:
	mov ax, command
	mov bx, 0
	mov cx, 32768
	call os_load_file
	jc total_fail

execute_bin:
	mov si, command
	mov di, kern_file_string
	mov cx, 6
	call os_string_strincmp
	jc no_kernel_allowed

	mov ax, 0			; Clear all registers
	mov bx, 0
	mov cx, 0
	mov dx, 0
	mov word si, [param_list]
	mov di, 0

	call 32768			; Call the external program

	jmp get_cmd			; When program has finished, start again



bas_file:
	mov ax, command
	mov bx, 0
	mov cx, 32768
	call os_load_file
	jc total_fail

	mov ax, 32768
	mov word si, [param_list]
	call os_run_basic

	jmp get_cmd



no_extension:
	mov ax, command
	call os_string_length

	mov si, command
	add si, ax

	mov byte [si], '.'
	mov byte [si+1], 'A'
	mov byte [si+2], 'P'
	mov byte [si+3], 'P'
	mov byte [si+4], 0

	mov ax, command
	mov bx, 0
	mov cx, 32768
	call os_load_file
	jc try_bas_ext

	jmp execute_bin


try_bas_ext:
	mov ax, command
	call os_string_length

	mov si, command
	add si, ax
	sub si, 4

	mov byte [si], '.'
	mov byte [si+1], 'B'
	mov byte [si+2], 'A'
	mov byte [si+3], 'S'
	mov byte [si+4], 0

	jmp bas_file



total_fail:
	mov si, invalid_msg
	call os_print_string

	jmp get_cmd


no_kernel_allowed:
	mov si, kern_warn_msg
	call os_print_string

	jmp get_cmd


; ------------------------------------------------------------------

print_list:
	mov si, list_text
	call os_print_string
	jmp get_cmd

; ------------------------------------------------------------------

print_seqlist:
	mov si, seqlist_list_title
	call os_print_string
	call os_print_newline

	mov si, seqlist_dir_text
	call os_print_string

	mov si, seqlist_ls_text
	call os_print_string

	mov si, seqlist_copy_text
	call os_print_string

	mov si, seqlist_ren_text
	call os_print_string

	mov si, seqlist_del_text
	call os_print_string

	mov si, seqlist_cat_text
	call os_print_string

	mov si, seqlist_size_text
	call os_print_string

	mov si, seqlist_seqlist_text
	call os_print_string

	mov si, seqlist_time_text
	call os_print_string

	mov si, seqlist_date_text
	call os_print_string

	mov si, seqlist_ftime_text
	call os_print_string

	mov si, seqlist_ver_text
	call os_print_string

	mov si, seqlist_shellinfo_text
	call os_print_string

	mov si, seqlist_osfetch_text
	call os_print_string

	mov si, seqlist_help_text
	call os_print_string

	mov si, seqlist_exit_text
	call os_print_string

	mov si, seqlist_shutdown_text
	call os_print_string

	mov si, seqlist_reboot_text
	call os_print_string

	mov si, seqlist_sysinfo_text
	call os_print_string

	mov si, seqlist_diskinfo_text
	call os_print_string

	mov si, seqlist_oswcalc_text
	call os_print_string

	jmp get_cmd

; ------------------------------------------------------------------

print_help:
	mov si, dir_help_text
	call os_print_string

	mov si, ls_help_text
	call os_print_string

	mov si, copy_help_text
	call os_print_string

	mov si, ren_help_text
	call os_print_string

	mov si, del_help_text
	call os_print_string

	mov si, cat_help_text
	call os_print_string

	mov si, size_help_text
	call os_print_string

	mov si, echo_help_text
	call os_print_string

	mov si, cls_help_text
	call os_print_string

	mov si, clear_help_text
	call os_print_string

	mov si, list_help_text
	call os_print_string

	mov si, seqlist_hlp_text
	call os_print_string

	mov si, time_help_text
	call os_print_string

	mov si, date_help_text
	call os_print_string
	
	mov si, ftime_help_text
	call os_print_string

	mov si, ver_help_text
	call os_print_string

	mov si, shellinfo_help_text
	call os_print_string

	mov si, osfetch_help_text
	call os_print_string

	mov si, help_help_text
	call os_print_string

	mov si, exit_help_text
	call os_print_string

	mov si, shutdown_help_text
	call os_print_string

	mov si, reboot_help_text
	call os_print_string

	mov si, sysinfo_help_text
	call os_print_string

	mov si, diskinfo_help_text
	call os_print_string

	mov si, oswcalc_help_text
	call os_print_string

	jmp get_cmd

; ------------------------------------------------------------------

clear_screen:
	call os_clear_screen
	jmp get_cmd


; ------------------------------------------------------------------

print_time:
	mov bx, tmp_string
	call os_get_time_string
	mov si, bx
	call os_print_string
	call os_print_newline
	jmp get_cmd


; ------------------------------------------------------------------

print_date:
	mov bx, tmp_string
	call os_get_date_string
	mov si, bx
	call os_print_string
	call os_print_newline
	jmp get_cmd


; ------------------------------------------------------------------

print_ftime:
	mov bx, tmp_string
	call os_get_date_string
	mov si, bx
	call os_print_string
	
	empty_space db ' ', 0
	mov si, empty_space
	call os_print_string

	mov bx, tmp_string
	call os_get_time_string
	mov si, bx
	call os_print_string
	call os_print_newline
	jmp get_cmd

; ------------------------------------------------------------------

print_ver:
	mov si, version_msg
	call os_print_string
	jmp get_cmd

; ------------------------------------------------------------------

shell_info:
	mov si, shellinfo_msg
	call os_print_string
	jmp get_cmd

; ------------------------------------------------------------------

diskinfo_tool:
	mov si, diskinfo_oemlabel
	call os_print_string

	mov si, diskinfo_volumelabel
	call os_print_string

	mov si, diskinfo_filesystem
	call os_print_string

	jmp get_cmd

; ------------------------------------------------------------------

osfetch_tool:
	mov si, osfetch_1
	call os_print_string
	call os_print_newline

	mov si, osfetch_2
	call os_print_string
	call os_print_newline

	mov si, osfetch_3
	call os_print_string
	call os_print_newline

	mov si, osfetch_4
	call os_print_string
	call os_print_newline

	mov si, osfetch_5
	call os_print_string
	call os_print_newline

	mov si, osfetch_6
	call os_print_string
	call os_print_newline

	mov si, osfetch_7
	call os_print_string
	call os_print_newline

	mov si, osfetch_8
	call os_print_string
	call os_print_newline

	mov si, osfetch_9
	call os_print_string
	call os_print_newline

	jmp get_cmd

; ------------------------------------------------------------------

kern_warning:
	mov si, kern_warn_msg
	call os_print_string
	jmp get_cmd


; ------------------------------------------------------------------

list_directory:
	mov cx,	0			; Counter

	mov ax, dirlist			; Get list of files on disk
	call os_get_file_list

	mov si, dirlist

.set_column:
	; Put the cursor in the correct column.
	call os_get_cursor_pos

	mov ax, cx
	and al, 0x03
	mov bl, 20
	mul bl

	mov dl, al
	call os_move_cursor

	mov ah, 0Eh			; BIOS teletype function
.next_char:
	lodsb

	cmp al, ','
	je .next_filename

	cmp al, 0
	je .done

	int 10h
	jmp .next_char

.next_filename:
	inc cx

	mov ax, cx
	and ax, 03h

	cmp ax, 0			; New line every 4th filename.
	jne .set_column

	call os_print_newline
	jmp .set_column

.done:
	call os_print_newline
	jmp get_cmd


; ------------------------------------------------------------------

cat_file:
	mov word si, [param_list]
	call os_string_parse

	mov di, kern_filename
	call os_string_compare
	call kernel_bin

	cmp ax, 0			; Was a filename provided?
	jne .filename_provided

	mov si, nofilename_msg		; If not, show error message
	call os_print_string
	jmp get_cmd

.filename_provided:
	call os_file_exists		; Check if file exists
	jc .not_found

	mov cx, 32768			; Load file into second 32K
	call os_load_file

	mov word [file_size], bx

	cmp bx, 0			; Nothing in the file?
	je get_cmd

	mov si, 32768
	mov ah, 0Eh			; int 10h teletype function
.loop:
	lodsb				; Get byte from loaded file

	cmp al, 0Ah			; Move to start of line if we get a newline char
	jne .not_newline

	call os_get_cursor_pos
	mov dl, 0
	call os_move_cursor

.not_newline:
	int 10h				; Display it
	dec bx				; Count down file size
	cmp bx, 0			; End of file?
	jne .loop

	jmp get_cmd

.not_found:
	mov si, notfound_msg
	call os_print_string
	jmp get_cmd


; ------------------------------------------------------------------

del_file:
	mov word si, [param_list]
	call os_string_parse

	mov di, kern_filename
	call os_string_compare
	jc kernel_bin

	cmp ax, 0			; Was a filename provided?
	jne .filename_provided

	mov si, nofilename_msg		; If not, show error message
	call os_print_string
	jmp get_cmd

.filename_provided:
	call os_remove_file
	jc .failure

	mov si, .success_msg
	call os_print_string
	mov si, ax
	call os_print_string
	call os_print_newline
	jmp get_cmd

.failure:
	mov si, .failure_msg
	call os_print_string
	jmp get_cmd


	.success_msg	db 'Deleted file: ', 0
	.failure_msg	db 'Could not delete file - does not exist or write protected', 13, 10, 0


; ------------------------------------------------------------------

size_file:
	mov word si, [param_list]
	call os_string_parse
	cmp ax, 0			; Was a filename provided?
	jne .filename_provided

	mov si, nofilename_msg		; If not, show error message
	call os_print_string
	jmp get_cmd

.filename_provided:
	call os_get_file_size
	jc .failure

	mov si, .size_msg
	call os_print_string

	mov ax, bx
	call os_int_to_string
	mov si, ax
	call os_print_string
	call os_print_newline
	jmp get_cmd


.failure:
	mov si, notfound_msg
	call os_print_string
	jmp get_cmd


	.size_msg	db 'Size (in bytes) is: ', 0


; ------------------------------------------------------------------

kernel_bin:
	mov si, kernel_change_error
	call os_print_string
	jmp get_cmd

echo_screen:
	mov word si, [param_list]

	cmp si, 0
	je .no_param

	call os_print_string
	call os_print_newline
	jmp get_cmd

.no_param:
	call os_print_newline
	jmp get_cmd

copy_file:
	mov word si, [param_list]
	call os_string_parse
	mov word [.tmp], bx

	mov di, kern_filename
	call os_string_compare
	jc kernel_bin

	cmp bx, 0			; Were two filenames provided?
	jne .filename_provided

	mov si, nofilename_msg		; If not, show error message
	call os_print_string
	jmp get_cmd

.filename_provided:
	mov dx, ax			; Store first filename temporarily
	mov ax, bx
	call os_file_exists
	jnc .already_exists

	mov ax, dx
	mov cx, 32768
	call os_load_file
	jc .load_fail

	mov cx, bx
	mov bx, 32768
	mov word ax, [.tmp]
	call os_write_file
	jc .write_fail

	mov si, .success_msg
	call os_print_string
	jmp get_cmd

.load_fail:
	mov si, notfound_msg
	call os_print_string
	jmp get_cmd

.write_fail:
	mov si, writefail_msg
	call os_print_string
	jmp get_cmd

.already_exists:
	mov si, exists_msg
	call os_print_string
	jmp get_cmd


	.tmp		dw 0
	.success_msg	db 'File copied successfully', 13, 10, 0


; ------------------------------------------------------------------

ren_file:
	mov word si, [param_list]
	call os_string_parse

	mov di, kern_filename
	call os_string_compare
	jc kernel_bin

	cmp bx, 0			; Were two filenames provided?
	jne .filename_provided

	mov si, nofilename_msg		; If not, show error message
	call os_print_string
	jmp get_cmd

.filename_provided:
	mov cx, ax			; Store first filename temporarily
	mov ax, bx			; Get destination
	call os_file_exists		; Check to see if it exists
	jnc .already_exists

	mov ax, cx			; Get first filename back
	call os_rename_file
	jc .failure

	mov si, .success_msg
	call os_print_string
	jmp get_cmd

.already_exists:
	mov si, exists_msg
	call os_print_string
	jmp get_cmd

.failure:
	mov si, .failure_msg
	call os_print_string
	jmp get_cmd


	.success_msg	db 'File renamed successfully', 13, 10, 0
	.failure_msg	db 'Operation failed - file not found or invalid filename', 13, 10, 0


; =====================================================================

ParaPerEntry	equ 2			; 32 bytes/entry => 2 paragraphs

dir_list:
	push es
	pusha

	call disk_read_root_dir
	jnc .cont1
	mov si, .readfail_msg
	call os_print_string
	jmp short .done

  .cont1:
;	mov di, bx			; ES:DI points to directory buffer
	mov di, disk_buffer		; ES:DI points to directory buffer

  .outer_loop:
	mov si, .header_msg
	call os_print_string
	mov cx, 20

  .page_loop:
	mov al, [es:di+11]		; get attributes
	cmp al, 0x0f			; Win marker
	je .next_entry

	test al, 0x18			; directory or volume label => skip
	jnz .next_entry

	mov al, [es:di]			; first char of name
	cmp al, 0			; first unused, should be unused here to end
	je .done

	cmp al, 0x5e			; skip deleted
	je .next_entry

	cmp al, ' '			; skip if starts with space or control (Win UTF-8?)
	jle .next_entry

	cmp al, '~'			; skip if not normal 7-bit ASCII
	jae .next_entry

	cmp al, '.'			; skip if '.' or '..'
	je .next_entry

	call dir_entry_dump		; ES:DI points to entry
	dec cx

  .next_entry:
	mov dx, es
	add dx, ParaPerEntry
	mov es, dx

	cmp cx, 0
	jne .page_loop

  .cont2:
	mov si, .footer_msg
	call os_print_string
	call os_wait_for_key
	cmp al, 27			; was key <esc>?
	je .done
	call os_clear_screen
	jmp .outer_loop

  .done:
	call os_print_newline
	popa
	pop es
	jmp get_cmd


	.readfail_msg	db 'Unable to read disk directory', 0
	.header_msg	db '    Name         attr         created          last write      first     bytes', 13, 10, 0
	.footer_msg	db 'Press key for next page', 0


; ---------------------------------------------------------------------
; listing helper subroutines

; ------------------------------------------------------------------
; dir_entry_dump -- print out the contents of a directory entry
;   output must correspond to header (above)
; IN: ES:DI = points to directory entry
; OUT: no changes

dir_entry_dump:
	pusha

	call type_name
	call os_get_cursor_pos		; line up columns
	mov dl, 15
	call os_move_cursor

	mov bh, [es:di+11]		; display attributes
	mov ax, 0x0e2e			; '.'
	test bh, 0x80			; reserved (should not be set)
	jz .attr1
	mov al, '*'
  .attr1:
	int 10h
	mov ax, 0x0e2e
	test bh, 0x40			; internal only (should not be set)
	jz .attr2
	mov al, '*'
  .attr2:
	int 10h
	mov ax, 0x0e2e
	test bh, 0x20
	jz .attr3
	mov al, 'A'			; archive
  .attr3:
	int 10h
	mov ax, 0x0e2e
	test bh, 0x10
	jz .attr4
	mov al, 'D'			; subdirectory
  .attr4:
	int 10h
	mov ax, 0x0e2e
	test bh, 8
	jz .attr5
	mov al, 'V'			; volume ID
  .attr5:
	int 10h
	mov ax, 0x0e2e
	test bh, 4
	jz .attr6
	mov al, 'S'			; system
  .attr6:
	int 10h
	mov ax, 0x0e2e
	test bh, 2
	jz .attr7
	mov al, 'H'			; hidden
  .attr7:
	int 10h
	mov ax, 0x0e2e
	test bh, 1
	jz .attr8
	mov al, 'R'			; read only
  .attr8:
	int 10h
	call os_print_space
	call os_print_space		; at column 25?

	mov dx, [es:di+16]		; created date & time (US and 24-hr format)
	call type_date
	call os_print_space
	mov dx, [es:di+14]
	call type_time
	call os_print_space
	call os_print_space		; at column 44?

	mov dx, [es:di+24]		; last written date & time (US and 24-hr format)
	call type_date
	call os_print_space
	mov dx, [es:di+22]
	call type_time			; at column 61?

	mov ax, [es:di+26]		; starting cluster
	call os_int_to_string
	mov si, ax
	call os_string_length
	neg ax
	add ax, 7			; 2 space separation + 5 characters, max.
	mov cx, ax
	jle .cluster_left
  .loop1:
	call os_print_space
	loop .loop1
  .cluster_left:
	call os_print_string

	mov dx, [es:di+30]		; file size (bytes)
	mov ax, [es:di+28]
	push es
	push ds
	pop es				; ES = DS = program seg
	push di
	mov bx, 10
	mov di, .number
	call os_long_int_to_string
	mov si, di
	mov ax, di
	call os_string_length
	neg ax
	add ax, 10			; 2 space separation + 8 characters, max.
	mov cx, ax
	jle .size_left
  .loop2:
	call os_print_space
	loop .loop2
  .size_left:
	call os_print_string
	call os_print_newline
	pop di
	pop es				; ES = directory seg

	popa
	ret

	.number		times 13 db 0

; ---------------------------------------------------------------------
; Type directory format time and print in 24-hr format (hh:mm:ss)
; There is a normal 2 second granularity
; IN: DX = time number
type_time:
	pusha

	mov ax, dx
	shr ax, 11			; 11 (start in word)
	cmp al, 10			; always 'hh'
	jae .hh
	push ax
	mov ax, 0x0e30			; '0'
	int 10h
	pop ax
  .hh:
	call os_int_to_string
	mov si, ax
	call os_print_string
	mov ax, 0x0e3a			; ':'
	int 10h

	mov ax, dx
	shr ax, 5			; 5 bits for seconds/2
	and ax, 0x3f			; 6 bits for minutes
	cmp al, 10
	jae .mm
	push ax
	mov ax, 0x0e30
	int 10h
	pop ax
  .mm:
	call os_int_to_string
	mov si, ax
	call os_print_string
	mov ax, 0x0e3a
	int 10h

	mov ax, dx
	and ax, 0x1f			; 5 bits for seconds/2
	shl ax, 1
	cmp al, 10
	jae .ss
	push ax
	mov ax, 0x0e30
	int 10h
	pop ax
  .ss:
	call os_int_to_string
	mov si, ax
	call os_print_string

	popa
	ret

; DOS format directory entry
; IN: DX = date number
; Uses USA date output format mm/dd/yy
type_date:
	pusha
	mov ax, dx		; separate out month
	shr ax, 5
	and ax, 0x0F
	cmp al, 1
	jl .mon_00
	cmp al, 12
	jbe .month
  .mon_00:
	mov al, 0
  .month:
	cmp al,10		; always 'mm'
	jge .mm
	push ax
	mov ax, 0x0e30
	int 10h
	pop ax
  .mm:
	call os_int_to_string
	mov si, ax
	call os_print_string
	mov ax, 0x0e2f		; '/'
	int 10h

	mov ax,dx		; separate out day
	and ax,0x1F
	cmp al, 10		; always 'dd'
	jae .dd
	push ax
	mov ax, 0x0e30
	int 10h
	pop ax
  .dd:
	call os_int_to_string
	mov si, ax
	call os_print_string
	mov ax, 0x0e2f
	int 10h

	mov ax,dx		; separate out year
	shr ax,9
	and ax,0x3F
	add ax,1980
	xor dx, dx
	mov bx, 100
	div bx
	mov ax, dx
	cmp al, 10
	jae .yy
	push ax
	mov ax, 0x0e30
	int 10h
	pop ax
  .yy:
	call os_int_to_string
	mov si, ax
	call os_print_string

	popa
	ret

; type a DOS format (short, 8.3) file name
; based on ASCII-7 file string (no UTF)
; allows a few more characters then PCDOS (ignores control, space, <del> and graphics)
; IN: ES:DI points to name in directory entry
type_name:
	pusha
	mov bx, di
	mov cx, 8
	add bx, cx		; point to extension

  .name_str1:
	mov al, [es:di]
	inc di
	cmp al,' '		; must be between '!' and '~'
	je .q_extend		; <space> is an unused slot
	jle .name_end		; 0 = entry not used, control not allowed
	cmp al,'~'		; no <del>, bit 8 set on delete (should be ASCII-7)
	ja .name_end
	mov ah, 0x0e
	int 10h
	loop .name_str1

  .q_extend:
	mov al,'.'		; output only if valid extension
	cmp byte [es:bx],' '	; space => no extension
	jle .name_end
	mov ah, 0x0e
	int 10h
	mov di, bx
	mov cx,3

  .name_str2:
	mov al, [es:di]
	inc di
	cmp al,' '		; must be between '!' and '~'
	jle .name_end
	cmp al,'~'		; no <del> or above
	ja .name_end
	mov ah, 0x0e
	int 10h
	loop .name_str2

  .name_end:
	popa
	ret


; =====================================================================

exit:
	ret


; =====================================================================

	input			times 64 db 0
	command			times 32 db 0

	dirlist			times 1024 db 0
	tmp_string		times 15 db 0

	file_size		dw 0
	param_list		dw 0

	bin_extension		db '.APP', 0
	bas_extension		db '.BAS', 0
	pcx_extension		db '.PCX', 0

	prompt			db 'root@shell> ', 0

	list_text		db 'Commands: DIR, LS, COPY, REN, DEL, CAT, SIZE, ECHO, CLS, CLEAR, LIST, SEQLIST, TIME, DATE, FTIME, VER, SHELLINFO, OSFETCH, HELP, EXIT, SHUTDOWN, REBOOT, SYSINFO, DISKINFO, OSWCALC', 13, 10, 0
	dir_help_text		db 'DIR: It displays all files on your hard drive.', 13, 10, 0
	ls_help_text		db 'LS: Provides detailed information about all files on your hard drive.', 13, 10, 0
	copy_help_text		db 'COPY: Allows you to copy a specified file from your hard drive with a new name.', 13, 10, 0
	ren_help_text		db 'REN: Allows you to rename a file installed on your hard drive.', 13, 10, 0
	del_help_text		db 'DEL: It allows you to delete any file installed on your hard drive.', 13, 10, 0
	cat_help_text		db 'CAT: It allows you to display the contents of a file installed on your hard drive.', 13, 10, 0
	size_help_text		db 'SIZE: It allows you to display the size of a file installed on your hard drive.', 13, 10, 0
	echo_help_text		db 'ECHO: Allows you to print any text you want on the terminal screen.', 13, 10, 0
	cls_help_text		db 'CLS: It allows you to clear the screen.', 13, 10, 0
	clear_help_text		db 'CLEAR: It allows you to clear the screen.', 13, 10, 0
	list_help_text		db 'LIST: It displays a list of all available commands.', 13, 10, 0
	seqlist_hlp_text 	db 'SEQLIST: Displays a sequential list of all available commands.', 13, 10, 0
	time_help_text		db 'TIME: It allows you to display the current system time.', 13, 10, 0
	date_help_text		db 'DATE: It allows you to display the current system date.', 13, 10, 0
	ftime_help_text		db 'FTIME: It allows you to display the current system date and time.', 13, 10, 0
	ver_help_text		db 'VER: It allows you to display the current version of OpenSoftware-World OS.', 13, 10, 0
	shellinfo_help_text	db 'SHELLINFO: Displays the shell version information in the operating system.', 13, 10, 0
	osfetch_help_text	db 'OSFETCH: It displays more detailed information about the operating system.', 13, 10, 0
	help_help_text		db 'HELP: It allows you to display a list of all available commands and their descriptions.', 13, 10, 0
	exit_help_text		db 'EXIT: It allows you to exit the command line interface and return to the main menu.', 13, 10, 0
	shutdown_help_text	db 'SHUTDOWN: It allows you to shut down your computer.', 13, 10, 0
	reboot_help_text	db 'REBOOT: It allows you to reboot your computer.', 13, 10, 0
	sysinfo_help_text	db 'SYSINFO: It allows you to display information about your system.', 13, 10, 0
	diskinfo_help_text	db 'DISKINFO: Displays the partition information loaded on your system.', 13, 10, 0
	oswcalc_help_text	db 'OSWCALC: It allows you to open the OSWCalc calculator application.', 13, 10, 0
	invalid_msg		db 'The command you entered could not be found. Please type list for a list of all commands.', 13, 10, 0

	osfetch_1 db "  ____   _____        root@shell", 0
	osfetch_2 db " / __ \\ / ___/       ----------", 0
	osfetch_3 db "| |  | | \\__ \\      OS: OpenSoftware-World OS 1.3 (Redesign)", 0
	osfetch_4 db "| |  | |___/  /       Kernel: MikeOS-based (4.7.0)", 0
	osfetch_5 db "| |  | |___/  /       Bootloader Name: MikeOS Bootloader", 0
	osfetch_6 db "| |   | ___/  /       Bootloader version: 1.0", 0
	osfetch_7 db " \\____/|_____/       Architecture: x86 (32-bit)", 0
	osfetch_8 db "                      MikeOS API Version: 18", 0
	osfetch_9 db "                      Shell: OpenSoftware-World Shell 1.2", 0

	nofilename_msg		db 'No filename or not enough filenames', 13, 10, 0
	notfound_msg		db 'File not found', 13, 10, 0
	writefail_msg		db 'Could not write file. Write protected or invalid filename?', 13, 10, 

	exists_msg		db 'Target file already exists!', 13, 10, 0
	shellinfo_msg	db 'OpenSoftware-World Shell 1.2', 13, 10, 0
	diskinfo_oemlabel db 'OEM Label: MIKEBOOT', 13, 10, 0
	diskinfo_volumelabel db 'Volume Label: OS-WOS', 13, 10, 0
	diskinfo_filesystem db 'Disk File System: FAT12', 13, 10, 0
	seqlist_list_title db 'Commands:', 13, 10, 0
	seqlist_dir_text	db 'DIR', 13, 10, 0
	seqlist_ls_text		db 'LS', 13, 10, 0
	seqlist_copy_text	db 'COPY', 13, 10, 0
	seqlist_ren_text	db 'REN', 13, 10, 0
	seqlist_del_text	db 'DEL', 13, 10, 0
	seqlist_cat_text	db 'CAT', 13, 10, 0
	seqlist_size_text	db 'SIZE', 13, 10, 0
	seqlist_echo_text	db 'ECHO', 13, 10, 0
	seqlist_cls_text	db 'CLS', 13, 10, 0
	seqlist_clear_text	db 'CLEAR', 13, 10, 0
	seqlist_list_text	db 'LIST', 13, 10, 0
	seqlist_seqlist_text	db 'SEQLIST', 13, 10, 0
	seqlist_time_text	db 'TIME', 13, 10, 0
	seqlist_date_text	db 'DATE', 13, 10, 0
	seqlist_ftime_text db 'FTIME', 13, 10, 0
	seqlist_ver_text	db 'VER', 13, 10, 0
	seqlist_shellinfo_text	db 'SHELLINFO', 13, 10, 0
	seqlist_osfetch_text	db 'OSFETCH', 13, 10, 0
	seqlist_help_text	db 'HELP', 13, 10, 0
	seqlist_exit_text	db 'EXIT', 13, 10, 0
	seqlist_shutdown_text	db 'SHUTDOWN', 13, 10, 0
	seqlist_reboot_text	db 'REBOOT', 13, 10, 0
	seqlist_sysinfo_text	db 'SYSINFO', 13, 10, 0
	seqlist_diskinfo_text	db 'DISKINFO', 13, 10, 0
	seqlist_oswcalc_text	db 'OSWCALC', 13, 10, 0
	finished_msg		db '> This program has been successfully run -- press any key to return to the main menu...', 0

	version_msg		db 'OpenSoftware-World OS ', MIKEOS_VER, ' (Redesign)', 13, 10, 0

	exit_string		db 'EXIT', 0
	list_string		db 'LIST', 0
	seqlist_string	db 'SEQLIST', 0
	echo_string     db 'ECHO', 0
	help_string 		db 'HELP', 0
	cls_string		db 'CLS', 0
	clear_string    db 'CLEAR', 0
	dir_string		db 'DIR', 0
	time_string		db 'TIME', 0
	date_string		db 'DATE', 0
	ftime_string		db 'FTIME', 0
	ver_string		db 'VER', 0
    shellinfo_string db 'SHELLINFO', 0
	osfetch_string db 'OSFETCH', 0
	cat_string		db 'CAT', 0
	del_string		db 'DEL', 0
	ren_string		db 'REN', 0
	copy_string		db 'COPY', 0
	size_string		db 'SIZE', 0
	diskinfo_string db 'DISKINFO', 0
	ls_string		db 'LS', 0

	kern_file_string	db 'KERNEL', 0
	kern_warn_msg		db 'Cannot execute kernel file!', 13, 10, 0
	kernel_change_error db 'This command is disabled for the KERNEL.BIN file.', 13, 10, 0
	kern_filename db 'KERNEL.BIN', 0


; ==================================================================

