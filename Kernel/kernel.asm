; ==================================================================
; MikeOS -- The Mike Operating System kernel
; Copyright (C) 2006 - 2022 MikeOS Developers -- see doc/LICENSE.TXT
;
; This is loaded from the drive by BOOTLOAD.BIN, as KERNEL.BIN.
; First we have the system call vectors, which start at a static point
; for programs to use. Following that is the main kernel code and
; then additional system call code is included.
; ==================================================================


	BITS 16
	CPU 386				; pusha offsets depends on a 386 or better
					; FS and GS require a 386 or better

	%DEFINE MIKEOS_VER '1.4'	; OS version number
	%DEFINE MIKEOS_API_VER 18	; API version for programs to check


	; This is the location in RAM for kernel disk operations, 24K
	; after the point where the kernel has loaded; it's 8K in size,
	; because external programs load after it at the 32K point:

	disk_buffer	equ	24576


%INCLUDE "../Kernel/Calls/calls.asm"

; ------------------------------------------------------------------
; START OF MAIN KERNEL CODE

os_main:
	cli				; Clear interrupts
	mov ax, 0
	mov ss, ax			; Set stack segment and pointer
	mov sp, 0FFFFh
	sti				; Restore interrupts

	cld				; The default direction for string operations
					; will be 'up' - incrementing address in RAM

	mov ax, 2000h			; Set all segments to match where kernel is loaded
	mov ds, ax			; After this, we don't need to bother with
	mov es, ax			; segments ever again, as MikeOS and its programs
	mov fs, ax			; live entirely in 64K
	mov gs, ax

	cmp dl, 0
	je no_change
	mov [bootdev], dl		; Save boot device number
	push es
	mov ah, 8			; Get drive parameters
	int 13h
	pop es
	and cx, 3Fh			; Maximum sector number
	mov [SecsPerTrack], cx		; Sector numbers start at 1
	movzx dx, dh			; Maximum head number
	add dx, 1			; Head numbers start at 0 - add 1 for total
	mov [Sides], dx

no_change:
	mov ax, 1003h			; Set text output with certain attributes
	mov bx, 0			; to be bright, and not blinking
	int 10h

	call os_seed_random		; Seed random number generator


	; Let's see if there's a file called AUTORUN.BIN and execute
	; it if so, before going to the program launcher menu

	mov ax, autorun_bin_file_name
	call os_file_exists
	jc no_autorun_bin		; Skip next three lines if AUTORUN.BIN doesn't exist

	mov cx, 32768			; Otherwise load the program into RAM...
	call os_load_file
	jmp execute_bin_program		; ...and move on to the executing part


	; Or perhaps there's an AUTORUN.BAS file?

no_autorun_bin:
	mov ax, autorun_bas_file_name
	call os_file_exists
	jc option_screen		; Skip next section if AUTORUN.BAS doesn't exist

	mov cx, 32768			; Otherwise load the program into RAM
	call os_load_file
	call os_clear_screen
	mov ax, 32768
	call os_run_basic		; Run the kernel's BASIC interpreter

	jmp app_selector		; And go to the app selector menu when BASIC ends


	; Now we display a dialog box offering the user a choice of
	; a menu-driven program selector, or a command-line interface

option_screen:
	mov ax, os_init_msg		; Set up the welcome screen
	mov bx, os_version_msg
	mov cx, 00111111b		; Colour: white text on light blue Açık Mavi (Cyan) Zemin + Beyaz Yazı (Daha Canlı)
	call os_draw_background

	mov ax, dialog_string_1		; Ask if user wants app selector or command-line
	mov bx, dialog_string_2
	mov cx, dialog_string_3
	mov dx, 1			; We want a two-option dialog box (OK or Cancel)
	call os_dialog_box

	cmp ax, 1			; If OK (option 0) chosen, start app selector
	jne near app_selector

	call os_clear_screen		; Otherwise clean screen and start the CLI
	call os_command_line

	jmp option_screen		; Offer menu/CLI choice after CLI has exited


	; Data for the above code...

	os_init_msg		db 'OpenSoftware-World OS 1.4 (Based on MikeOS v4.7.0)', 0
	os_version_msg		db 'Version ', MIKEOS_VER, 0

	dialog_string_1		db 'Thanks for trying out OpenSoftware-World OS!', 0
	dialog_string_2		db 'Please select an interface: OK for the', 0
	dialog_string_3		db 'program menu, Cancel for command line.', 0



app_selector:
	mov ax, os_init_msg		; Draw main screen layout
	mov bx, os_version_msg
	mov cx, 00111111b		; Colour: white text on light blue Açık Mavi (Cyan) Zemin + Beyaz Yazı (Daha Canlı)
	call os_draw_background

	call os_file_selector		; Get user to select a file, and store
					; the resulting string location in AX
					; (other registers are undetermined)

	jc option_screen		; Return to the CLI/menu choice screen if Esc pressed

	mov si, ax			; Did the user try to run 'KERNEL.BIN'?
	mov di, kern_file_name
	call os_string_compare
	jc no_kernel_execute		; Show an error message if so


	; Next, we need to check that the program we're attempting to run is
	; valid -- in other words, that it has a .BIN extension

	push si				; Save filename temporarily

	mov bx, si
	mov ax, si
	call os_string_length

	mov si, bx
	add si, ax			; SI now points to end of filename...

	dec si
	dec si
	dec si				; ...and now to start of extension!

	mov di, bin_ext
	mov cx, 3
	rep cmpsb			; Are final 3 chars 'BIN'?
	jne not_bin_extension		; If not, it might be a '.BAS'

	pop si				; Restore filename


	mov ax, si
	mov cx, 32768			; Where to load the program file
	call os_load_file		; Load filename pointed to by AX


execute_bin_program:
	call os_clear_screen		; Clear screen before running

	mov ax, 0			; Clear all registers
	mov bx, 0
	mov cx, 0
	mov dx, 0
	mov si, 0
	mov di, 0

	call 32768			; Call the external program code,
					; loaded at second 32K of segment
					; (program must end with 'ret')

	mov si, program_finished_msg	; Give the program a chance to display
	call os_print_string		; any output before clearing the screen
	call os_wait_for_key

	call os_clear_screen		; When finished, clear screen
	jmp app_selector		; and go back to the program list


no_kernel_execute:			; Warn about trying to executing kernel!
	mov ax, kerndlg_string_1
	mov bx, kerndlg_string_2
	mov cx, kerndlg_string_3
	mov dx, 0			; One button for dialog box
	call os_dialog_box

	jmp app_selector		; Start over again...


not_bin_extension:
	pop si				; We pushed during the .BIN extension check

	push si				; Save it again in case of error...

	mov bx, si
	mov ax, si
	call os_string_length

	mov si, bx
	add si, ax			; SI now points to end of filename...

	dec si
	dec si
	dec si				; ...and now to start of extension!

	mov di, bas_ext
	mov cx, 3
	rep cmpsb			; Are final 3 chars 'BAS'?
	jne not_bas_extension		; If not, error out


	pop si

	mov ax, si
	mov cx, 32768			; Where to load the program file
	call os_load_file		; Load filename pointed to by AX

	call os_clear_screen		; Clear screen before running

	mov ax, 32768
	mov si, 0			; No params to pass
	call os_run_basic		; And run our BASIC interpreter on the code!

	mov si, program_finished_msg
	call os_print_string
	call os_wait_for_key

	call os_clear_screen
	jmp app_selector		; and go back to the program list


not_bas_extension:
	pop si

	mov ax, ext_string_1
	mov bx, ext_string_2
	mov cx, 0
	mov dx, 0			; One button for dialog box
	call os_dialog_box

	jmp app_selector		; Start over again...


	; And now data for the above code...

	kern_file_name		db 'KERNEL.BIN', 0

	autorun_bin_file_name	db 'AUTORUN.APP', 0
	autorun_bas_file_name	db 'AUTORUN.BAS', 0

	bin_ext			db 'APP'
	bas_ext			db 'BAS'

	kerndlg_string_1	db 'Cannot load and execute OpenSoftware-World OS kernel!', 0
	kerndlg_string_2	db 'KERNEL.BIN is the core of OpenSoftware-World OS, and', 0
	kerndlg_string_3	db 'is not a normal program.', 0

	ext_string_1		db 'Invalid filename extension! You can', 0
	ext_string_2		db 'only execute .APP or .BAS programs.', 0

	program_finished_msg	db '> This program has been successfully run -- press any key to return to the main menu...', 0


; ------------------------------------------------------------------
; SYSTEM VARIABLES -- Settings for programs and system calls


	; Time and date formatting

	fmt_12_24	db 0		; Non-zero = 24-hr format

	fmt_date	db 0, '/'	; 0, 1, 2 = M/D/Y, D/M/Y or Y/M/D
					; Bit 7 = use name for months
					; If bit 7 = 0, second byte = separator character


; ------------------------------------------------------------------
; FEATURES -- Code to pull into the kernel


	%INCLUDE "../Services/cli.asm" ; It enables the terminal screen and the execution of terminal commands.
 	%INCLUDE "../Services/disk.asm" ; MikeOS provides disk drive and disk functions.
	%INCLUDE "../Services/keyboard.asm" ; MikeOS provides keyboard drivers and keyboard functions.
	%INCLUDE "../Services/math.asm" ; Provides mathematical functions for MikeOS.
	%INCLUDE "../Services/misc.asm" ; Provides an error screen for MikeOS.
	%INCLUDE "../Services/ports.asm" ; Provides I/O port operation functions for MikeOS.
	%INCLUDE "../Services/screen.asm" ; MikeOS provides screen functionality.
	%INCLUDE "../Services/sound.asm" ; MikeOS provides the audio driver and audio functions.
	%INCLUDE "../Services/string.asm" ; MikeOS provides string functionality.
	%INCLUDE "../Services/basic.asm" ; MikeOS is a BASIC interpreter developed for the OS.


; ==================================================================
; END OF KERNEL
; ==================================================================

