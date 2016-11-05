[ORG 0x7c00]
	xor ax, ax
	mov ds, ax		;datasegment auf 0 setzen
 	jmp main

print_string:
	lodsb			;byte von si in al laden
	or al, al		;prüfen ob al 0 ist
	jz .done		;wenn 0 verlassen
	mov ah, 0x0E		;tty schhreibmodus waehlen
	int 0x10		;bios interrupt Bildschirmzugriffe
	jmp print_string

	.done:
		ret

hang:
	jmp hang		;endlos Schleife

strcmp:
	.loop:
		mov al, [si]
		mov bl, [di]
		cmp al, bl
		jne .notequal

		cmp al, 0
		je .done

		inc di
		inc si
		jmp .loop
	.done:
		stc
		ret

	.notequal:
		clc
		ret

get_String:
	xor cl, cl		;cl wird auf 0 gesetzt. cl ist zum zählen der zeichen da
	.loop:

		mov ah, 0x10	;funktion 0x10 (warten auf tastendruck
		int 0x16	;interrupt starten um auf tastendruck zu warten

		cmp al, 0x0D	;wenn enter(zeilenumbruch \n, 13 oder 0x0D)
		je .done	;springe zu .done um den string abzuschließen

		cmp cl, 64	;wenn der string 64 zeichen lang ist
		je .loop	;beende den string

		mov ah, 0x0E	;wähle die zeichen schreibfunktion aus
		int 0x10	;schreibe das zeichen im register al

		stosb		;speichere das Zeichen im Buffer

		inc cl		;inkrementiere cl
		jmp .loop	;lese den nächsten Buchstaben
	.done:
		mov ah, 0x0E	;wähle die schreib funktion aus
		mov al, 0x0A	;speichere 0x0A => anfang der zeile
		int 0x10	;schreibe den inhalt aus register al

		mov al, 0x0D	;speichere 0x0D => neue Zeile
		int 0x10	;schreibe den Inhalt aus register al
		ret		;kehre zurück

main:
	mov si, prompt		;speichere den text der Variable msg in si
	call print_string	;schreibe den inhalt aus si

	mov di, buffer
	call get_String		;hole einen neuen string ab

	cmp byte [si], 0
	je main

	mov si, buffer
	mov di, reboot_cmd
	call strcmp
	jc .reboot


	jmp main		;wiederhole die hauptschleife


.reboot:
	mov si, reboot_text
	call print_string
	xor ax, ax
	int 16
	jmp 0xffff:0x0000

reboot_text db 'Bootloader wird neu gebootet', 0, 0
reboot_cmd db 'reboot', 0
prompt db '>', 0			;text für den pfeil der prompt
msg   db 'Willkommen!!', 0x0D, 0x0A	;speichere string
buffer times 64 db 0

   times 510-($-$$) db 0
   db 0x55
   db 0xAA
