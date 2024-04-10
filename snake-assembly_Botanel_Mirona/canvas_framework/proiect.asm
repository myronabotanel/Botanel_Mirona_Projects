.386
.586
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Exemplu proiect desenare",0
area_width EQU 640 ;zona desenata
area_height EQU 480 ;zona desenata
area DD 0
segmente_sarpe db 4 
x_cap dd 0
y_cap dd 0
x_cpy dd 0
y_cpy dd 0
x_coada dd 0
y_coada dd 0
aux dd 0
x_mancare dd 0
y_mancare dd 0
x_mancare1 dd 0
y_mancare1 dd 0
aux_game dd 0

desen_width dd 24
desen_height dd 24

counter DD 0 ; numara evenimentele de tip timer
;pozitiile pe stiva relative la ebp unde se afla argumentele:
arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc
include download.inc
buton_x EQU 100
buton_y EQU 90
buton_size EQU 60

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

desen proc
    push ebp   ;salvam ebp pe stiva
	mov ebp, esp
	pusha    ;salvam valorile tuturor registrilor pe stiva
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, '^'
	je make_face
make_face:  ;desenam simbolul
	mov eax, 0
	lea esi, var_0   
	jmp draw_text
draw_text:
	mov ebx, desen_width
	mul ebx
	mov ebx, desen_height
	mul ebx
	add esi, eax
	mov ecx, desen_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, desen_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, desen_width
bucla_simbol_coloane:
	mov ebx, [esi]
	mov ebx, [esi]
	mov [edi], ebx
	add esi, 4
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
desen endp
; un macro ca sa apelam mai usor desenarea 
make_desen_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call desen
	add esp, 16
endm



linie_orizontala macro x, y, lungime, color ;macro ul primeste pe x, y: coordonatele de unde incepe, lungimea liniei si culoarea
local bucla_linie
	mov eax, y ;citim ce e in memorie la adresa ebp+arg3 si asa il obtinem pe y =>eax=y
	mov ebx, area_width ;deoarece e o constanta   
	mul ebx ;=>eax=y*area_width (nr col)
	add eax, x ;=>eax=(y*area_width)+x;
	shl eax, 2 ;practic inmultim eax cu 4, deoarece fiecare pixel e dubleword 
	;eax-pozitia in vectorul de pixel numita area. ca sa scriem ceva acolo, trebuie sa i adunam val de inceput. (pointerul de inceput. a[0][0])
	add eax, area 
	mov ecx, lungime 
bucla_linie: 
mov dword ptr[eax], color
add eax, 4
loop bucla_linie
endm

linie_verticala macro x, y, lungime, color ;macro ul primeste pe x, y: coordonatele de unde incepe, lungimea liniei si culoarea
local bucla_linie
	mov eax, y ;citim ce e in memorie la adresa ebp+arg3 si asa il obtinem pe y =>eax=y
	mov ebx, area_width ;deoarece e o constanta   
	mul ebx ;=>eax=y*area_width (nr col)
	add eax, x ;=>eax=(y*area_width)+x;
	shl eax, 2 ;practic inmultim eax cu 4, deoarece fiecare pixel e dubleword 
	;eax-pozitia in vectorul de pixel numita area. ca sa scriem ceva acolo, trebuie sa i adunam val de inceput. (pointerul de inceput. a[0][0])
	add eax, area 
	mov ecx, lungime 
bucla_linie: 
mov dword ptr[eax], color
add eax, 4*area_width
loop bucla_linie
endm



; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc 
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ;verifica argumentul 1- tipul de eveniment
	cmp eax, 1 ;<=> daca e argumentul 1 => click => sarim la evt_click
	jz evt_click
	cmp eax, 2; analog
	jz evt_timer ; nu s-a efectuat click pe nimic
	
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	jmp afisare_litere
	
	
evt_click: ;aici se vine cand s a dat click
	
	; mov eax, [ebp+arg3] ;citim ce e in memorie la adresa ebp+arg3 si asa il obtinem pe y =>eax=y
	; mov ebx, area_width ;deoarece e o constanta   
	; mul ebx ;=>eax=y*area_width (nr col)
	; add eax, [ebp+arg2] ;=>eax=(y*area_width)+x;
	; shl eax, 2 ;practic inmultim eax cu 4, deoarece fiecare pixel e dubleword 
	;;eax-pozitia in vectorul de pixel numita area. ca sa scriem ceva acolo, trebuie sa i adunam val de inceput. (pointerul de inceput. a[0][0])
	; add eax, area 
	;urmeaza sa scriem la aceste coordonate un pixel rosu

	;linie_verticala [ebp+arg2], [ebp+arg3], 40, 00FF0F0h
	
	mov eax, [ebp+arg2]
	cmp eax, buton_x   
	jl button_fail
	cmp eax, buton_x+buton_size
	jg button_fail
	mov eax, [ebp+arg3]
	cmp eax, buton_y
	jl button_fail
	cmp eax, buton_y+buton_size
	jg button_fail
	;=>s a dat click in buton
	jmp deseneaza_jocul;
	
	
	
	
	;jmp final_draw ;sa sara peste button_fail si taimer
	
	button_fail:
	;make_text_macro ' ', area, buton_x+buton_size/2-5, buton_y+buton_size/2+10
	;make_text_macro ' ', area, buton_x+buton_size/2+5, buton_y+buton_size/2+10
	;jmp afisare_litere ;se sare la ultima parte
	
	jmp final_draw

deseneaza_jocul:
	mov aux_game, 1   ; a inceput jocul
	mov aux, 0 
	make_text_macro ' ', area, 110, 100 ;x, y, x->coloane, y->linii
	make_text_macro ' ', area, 120, 100
	make_text_macro ' ', area, 130, 100
	make_text_macro ' ', area, 140, 100
	make_text_macro ' ', area, 150, 100
	make_text_macro ' ', area, 160, 100
	;;desenam labirintul
	;coordonate random mancare initiala
	rdtsc      ;returneaza valoarea curenta a registrelor tsc, registre care numara ciclurile de ceas pe procesor. utilizat pt a masura intervalul de timp scurs de la o referinta
	xor edx, edx   ;initializam edx la 0
	mov ecx, 640	;in ecx punem 620-marginea inf 
	sub ecx, 20  ;scadem 24-inaltimea simbolului
	add ecx, 1   ;adaugam 1
	div ecx   ;impartim edx:eax, rezultatul fiind stocat catul in eax, restul in edx
	add edx, 20 ;adaugam 24. pt a compensa scaderea initiala 
	mov x_mancare, edx    ;x random mancare
	
	xor edx, edx
	mov ecx, 460
	sub ecx, 20
	add ecx, 1
	div ecx
	add edx, 20
	mov y_mancare, edx    ;y random mancare   
	
	linie_verticala 320, 90, 200, 0008000h
	linie_verticala 321, 90, 200, 0008000h
	linie_verticala 322, 90, 200, 0008000h
	linie_verticala 323, 90, 200, 0008000h
	linie_verticala 324, 90, 200, 0008000h
	linie_verticala 325, 90, 200, 0008000h
	linie_verticala 326, 90, 200, 0008000h
	linie_verticala 327, 90, 200, 0008000h
	linie_verticala 328, 90, 200, 0008000h
	linie_verticala 329, 90, 200, 0008000h
	linie_verticala 330, 90, 200, 0008000h
	linie_verticala 330, 90, 200, 0008000h
	linie_verticala 331, 90, 200, 0008000h
	linie_verticala 332, 90, 200, 0008000h
	linie_verticala 333, 90, 200, 0008000h
	linie_verticala 334, 90, 200, 0008000h
	linie_verticala 335, 90, 200, 0008000h
	linie_verticala 336, 90, 200, 0008000h
	linie_verticala 337, 90, 200, 0008000h
	linie_verticala 338, 90, 200, 0008000h
	linie_verticala 339, 90, 200, 0008000h
	
	linie_orizontala 340, 90, 200, 0008000h
	linie_orizontala 340, 91, 200, 0008000h
	linie_orizontala 340, 92, 200, 0008000h
	linie_orizontala 340, 93, 200, 0008000h
	linie_orizontala 340, 94, 200, 0008000h
	linie_orizontala 340, 95, 200, 0008000h
	linie_orizontala 340, 96, 200, 0008000h
	linie_orizontala 340, 97, 200, 0008000h
	linie_orizontala 340, 98, 200, 0008000h
	linie_orizontala 340, 99, 200, 0008000h
	linie_orizontala 340, 100, 200, 0008000h
	linie_orizontala 340, 101, 200, 0008000h
	linie_orizontala 340, 102, 200, 0008000h
	linie_orizontala 340, 103, 200, 0008000h
	linie_orizontala 340, 104, 200, 0008000h
	linie_orizontala 340, 105, 200, 0008000h
	linie_orizontala 340, 106, 200, 0008000h
	linie_orizontala 340, 107, 200, 0008000h
	linie_orizontala 340, 108, 200, 0008000h
	linie_orizontala 340, 109, 200, 0008000h
	linie_orizontala 340, 110, 200, 0008000h
	linie_orizontala 340, 111, 200, 0008000h
	linie_verticala 540, 20, 92, 0008000h
	linie_verticala 541, 20, 92, 0008000h
	linie_verticala 542, 20, 92, 0008000h
	linie_verticala 543, 20, 92, 0008000h
	linie_verticala 544, 20, 92, 0008000h
	linie_verticala 545, 20, 92, 0008000h
	linie_verticala 546, 20, 92, 0008000h
	linie_verticala 547, 20, 92, 0008000h
	linie_verticala 548, 20, 92, 0008000h
	linie_verticala 549, 20, 92, 0008000h
	linie_verticala 550, 20, 92, 0008000h
	linie_verticala 551, 20, 92, 0008000h
	linie_verticala 552, 20, 92, 0008000h
	linie_verticala 553, 20, 92, 0008000h
	linie_verticala 554, 20, 92, 0008000h
	linie_verticala 555, 20, 92, 0008000h
	linie_verticala 556, 20, 92, 0008000h
	linie_verticala 557, 20, 92, 0008000h
	linie_verticala 558, 20, 92, 0008000h
	linie_verticala 559, 20, 92, 0008000h
	
	linie_orizontala 23, 95, 80, 0008000h
	linie_orizontala 23, 96, 80, 0008000h
	linie_orizontala 23, 97, 80, 0008000h
	linie_orizontala 23, 98, 80, 0008000h
	linie_orizontala 23, 99, 80, 0008000h
	linie_orizontala 23, 100, 80, 0008000h
	linie_orizontala 23, 101, 80, 0008000h
	linie_orizontala 23, 102, 80, 0008000h
	linie_orizontala 23, 103, 80, 0008000h
	linie_orizontala 23, 104, 80, 0008000h
	linie_orizontala 23, 105, 80, 0008000h
	linie_orizontala 23, 104, 80, 0008000h
	linie_orizontala 23, 105, 80, 0008000h
	linie_orizontala 23, 106, 80, 0008000h
	linie_orizontala 23, 107, 80, 0008000h
	linie_orizontala 23, 108, 80, 0008000h
	linie_orizontala 23, 109, 80, 0008000h
	linie_orizontala 23, 110, 80, 0008000h
	linie_orizontala 23, 111, 80, 0008000h
	linie_orizontala 23, 112, 80, 0008000h
	linie_orizontala 23, 113, 80, 0008000h
	linie_orizontala 23, 114, 80, 0008000h
	linie_orizontala 23, 115, 80, 0008000h
	
	linie_verticala 150, 220, 250, 0008000h
	linie_verticala 151, 220, 250, 0008000h
	linie_verticala 152, 220, 250, 0008000h
	linie_verticala 153, 220, 250, 0008000h
	linie_verticala 154, 220, 250, 0008000h
	linie_verticala 155, 220, 250, 0008000h
	linie_verticala 156, 220, 250, 0008000h
	linie_verticala 157, 220, 250, 0008000h
	linie_verticala 158, 220, 250, 0008000h
	linie_verticala 159, 220, 250, 0008000h
	linie_verticala 160, 220, 250, 0008000h
	linie_verticala 161, 220, 250, 0008000h
	linie_verticala 162, 220, 250, 0008000h
	linie_verticala 163, 220, 250, 0008000h
	linie_verticala 164, 220, 250, 0008000h
	linie_verticala 165, 220, 250, 0008000h
	linie_verticala 166, 220, 250, 0008000h
	linie_verticala 167, 220, 250, 0008000h
	linie_verticala 168, 220, 250, 0008000h
	linie_verticala 169, 220, 250, 0008000h
	linie_verticala 170, 220, 250, 0008000h
	
	linie_orizontala 430, 370, 50, 0008000h
	linie_orizontala 430, 371, 50, 0008000h
	linie_orizontala 430, 372, 50, 0008000h
	linie_orizontala 430, 373, 50, 0008000h
	linie_orizontala 430, 374, 50, 0008000h
	linie_orizontala 430, 375, 50, 0008000h
	linie_orizontala 430, 376, 50, 0008000h
	linie_orizontala 430, 377, 50, 0008000h
	linie_orizontala 430, 378, 50, 0008000h
	linie_orizontala 430, 379, 50, 0008000h
	linie_orizontala 430, 380, 50, 0008000h
	linie_orizontala 430, 381, 50, 0008000h
	linie_orizontala 430, 380, 50, 0008000h
	linie_orizontala 430, 381, 50, 0008000h
	linie_orizontala 430, 382, 50, 0008000h
	linie_orizontala 430, 383, 50, 0008000h
	linie_orizontala 430, 384, 50, 0008000h
	linie_orizontala 430, 385, 50, 0008000h
	linie_orizontala 430, 386, 50, 0008000h
	linie_orizontala 430, 387, 50, 0008000h
	linie_orizontala 430, 388, 50, 0008000h
	linie_orizontala 430, 389, 50, 0008000h	
	
	
	
	linie_orizontala 480, 180, 150, 0008000h
	linie_orizontala 480, 181, 150, 0008000h
	linie_orizontala 480, 182, 150, 0008000h
	linie_orizontala 480, 183, 150, 0008000h
	linie_orizontala 480, 184, 150, 0008000h
	linie_orizontala 480, 185, 150, 0008000h
	linie_orizontala 480, 186, 150, 0008000h
	linie_orizontala 480, 187, 150, 0008000h
	linie_orizontala 480, 188, 150, 0008000h
	linie_orizontala 480, 189, 150, 0008000h
	linie_orizontala 480, 190, 150, 0008000h
	linie_orizontala 480, 191, 150, 0008000h
	linie_orizontala 480, 192, 150, 0008000h
	linie_orizontala 480, 193, 150, 0008000h
	linie_orizontala 480, 194, 150, 0008000h
	linie_orizontala 480, 195, 150, 0008000h
	linie_orizontala 480, 196, 150, 0008000h
	linie_orizontala 480, 197, 150, 0008000h
	linie_orizontala 480, 198, 150, 0008000h
	linie_orizontala 480, 199, 150, 0008000h
	linie_orizontala 480, 200, 150, 0008000h
	
	;snake                                                                                                             
	
	mov x_cap, 60
	mov y_cap, 350
	mov x_cpy, 60
	mov y_cpy, 350
	
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cap, y_cap, 10, 800000h
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, x_cpy
	mov x_coada, eax
	mov eax, y_cpy
	mov y_coada, eax

	jmp final_draw
	
	

afisare_litere:
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	 mov ebx, 10    ;utilizata pt a efectua impartiri in baza 10
	 mov eax, counter
	;;cifra unitatilor
	 mov edx, 0   ;setam edx la 0
	 div ebx     ;impartum ebx la eax. rez va fi in eax, restuol in edx
	 add edx, '0'   ;adaug valoarea ascii a caracterului '0'   =>transforma val numerica a cifrei in cal ascii coresp
	 make_text_macro edx, area, 170, 40    ;in edx avem cifra unitatilor, pe care o apelam  cum facem la litere
	;cifra zecilor
	 mov edx, 0
	 div ebx
	 add edx, '0'
	 make_text_macro edx, area, 160, 40
	;cifra sutelor
	 mov edx, 0
	 div ebx
	 add edx, '0'
	 make_text_macro edx, area, 150, 40
	
	;scriem un mesaj
	make_text_macro 'S', area, 110, 100 ;x, y, x->coloane, y->linii
	make_text_macro 'T', area, 120, 100
	make_text_macro 'A', area, 130, 100
	make_text_macro 'R', area, 140, 100
	make_text_macro 'T', area, 150, 100
	make_text_macro 'Z', area, 160, 100
	
	make_text_macro 'S', area, 90, 40
	make_text_macro 'C', area, 100, 40
	make_text_macro 'O', area, 110, 40
	make_text_macro 'R', area, 120, 40
	make_text_macro 'E', area, 130, 40
	make_text_macro ' ', area, 140, 40
	

	linie_orizontala buton_x, buton_y, buton_size, 0FFFFFFh
	linie_orizontala buton_x, buton_y+buton_size, buton_size, 0FFFFFFh
	linie_verticala buton_x, buton_y, buton_size, 0FFFFFFh
	linie_verticala buton_x+buton_size, buton_y, buton_size, 0FFFFFFh
	linie_orizontala area_width, area_height, buton_size, 0F0F0F0F0h
	;marginile:
	linie_orizontala 0, 0, area_width, 0008000h
	linie_orizontala 0, 1, area_width, 0008000h
	linie_orizontala 0, 2, area_width, 0008000h
	linie_orizontala 0, 3, area_width, 0008000h
	linie_orizontala 0, 4, area_width, 0008000h
	linie_orizontala 0, 5, area_width, 0008000h
	linie_orizontala 0, 6, area_width, 0008000h
	linie_orizontala 0, 7, area_width, 0008000h
	linie_orizontala 0, 8, area_width, 0008000h
	linie_orizontala 0, 9, area_width, 0008000h
	linie_orizontala 0, 10, area_width, 0008000h
	linie_orizontala 0, 11, area_width, 0008000h
	linie_orizontala 0, 12, area_width, 0008000h
	linie_orizontala 0, 13, area_width, 0008000h
	linie_orizontala 0, 14, area_width, 0008000h
	linie_orizontala 0, 15, area_width, 0008000h
	linie_orizontala 0, 16, area_width, 0008000h
	linie_orizontala 0, 17, area_width, 0008000h
	linie_orizontala 0, 18, area_width, 0008000h
	linie_orizontala 0, 19, area_width, 0008000h
	linie_orizontala 0, 20, area_width, 0008000h
	
	linie_verticala 0, 0, area_height, 0008000h
	linie_verticala 1, 0, area_height, 0008000h
	linie_verticala 2, 0, area_height, 0008000h
	linie_verticala 3, 0, area_height, 0008000h
	linie_verticala 4, 0, area_height, 0008000h
	linie_verticala 5, 0, area_height, 0008000h
	linie_verticala 6, 0, area_height, 0008000h
	linie_verticala 7, 0, area_height, 0008000h
	linie_verticala 8, 0, area_height, 0008000h
	linie_verticala 9, 0, area_height, 0008000h
	linie_verticala 10, 0, area_height, 0008000h
	linie_verticala 11, 0, area_height, 0008000h
	linie_verticala 12, 0, area_height, 0008000h
	linie_verticala 13, 0, area_height, 0008000h
	linie_verticala 14, 0, area_height, 0008000h
	linie_verticala 15, 0, area_height, 0008000h
	linie_verticala 16, 0, area_height, 0008000h
	linie_verticala 17, 0, area_height, 0008000h
	linie_verticala 18, 0, area_height, 0008000h
	linie_verticala 19, 0, area_height, 0008000h
	linie_verticala 20, 0, area_height, 0008000h
	
	linie_orizontala 0, area_height, area_width, 0008000h
	linie_orizontala 0, area_height-1, area_width, 0008000h
	linie_orizontala 0, area_height-2, area_width, 0008000h
	linie_orizontala 0, area_height-3, area_width, 0008000h
	linie_orizontala 0, area_height-4, area_width, 0008000h
	linie_orizontala 0, area_height-5, area_width, 0008000h
	linie_orizontala 0, area_height-6, area_width, 0008000h
	linie_orizontala 0, area_height-7, area_width, 0008000h
	linie_orizontala 0, area_height-8, area_width, 0008000h
	linie_orizontala 0, area_height-9, area_width, 0008000h
	linie_orizontala 0, area_height-10, area_width, 0008000h
	linie_orizontala 0, area_height-11, area_width, 0008000h
	linie_orizontala 0, area_height-12, area_width, 0008000h
	linie_orizontala 0, area_height-13, area_width, 0008000h
	linie_orizontala 0, area_height-14, area_width, 0008000h
	linie_orizontala 0, area_height-15, area_width, 0008000h
	linie_orizontala 0, area_height-16, area_width, 0008000h
	linie_orizontala 0, area_height-17, area_width, 0008000h
	linie_orizontala 0, area_height-18, area_width, 0008000h
	linie_orizontala 0, area_height-19, area_width, 0008000h
	linie_orizontala 0, area_height-20, area_width, 0008000h
	
	linie_verticala area_width, 0, area_height, 0008000h
	linie_verticala area_width-1, 0, area_height, 0008000h
	linie_verticala area_width-2, 0, area_height, 0008000h
	linie_verticala area_width-3, 0, area_height, 0008000h
	linie_verticala area_width-4, 0, area_height, 0008000h
	linie_verticala area_width-5, 0, area_height, 0008000h
	linie_verticala area_width-6, 0, area_height, 0008000h
	linie_verticala area_width-7, 0, area_height, 0008000h
	linie_verticala area_width-8, 0, area_height, 0008000h
	linie_verticala area_width-9, 0, area_height, 0008000h
	linie_verticala area_width-10, 0, area_height, 0008000h
	linie_verticala area_width-11, 0, area_height, 0008000h
	linie_verticala area_width-12, 0, area_height, 0008000h
	linie_verticala area_width-13, 0, area_height, 0008000h
	linie_verticala area_width-14, 0, area_height, 0008000h
	linie_verticala area_width-15, 0, area_height, 0008000h
	linie_verticala area_width-16, 0, area_height, 0008000h
	linie_verticala area_width-17, 0, area_height, 0008000h
	linie_verticala area_width-18, 0, area_height, 0008000h
	linie_verticala area_width-19, 0, area_height, 0008000h
	linie_verticala area_width-20, 0, area_height, 0008000h

evt_timer:
	;inc counter
	;jmp final_draw
	


evt_tastatura:
	
	
	
	cmp dword ptr[ebp+arg2], '&'    ;w=>sus
	je miscare_sus
	cmp dword ptr[ebp+arg2], "'"   ;d=>dreapta
	je miscare_dreapta
	cmp dword ptr[ebp+arg2], '%'   ;a=>stanga
	je miscare_stanga
	cmp dword ptr[ebp+arg2], '('    ;s=>jos
	je miscare_jos
	jmp final_draw

	
miscare_sus:

	make_text_macro ' ', area, 110, 100 ;x, y, x->coloane, y->linii
	make_text_macro ' ', area, 120, 100
	make_text_macro ' ', area, 130, 100
	make_text_macro ' ', area, 140, 100
	make_text_macro ' ', area, 150, 100
	make_text_macro ' ', area, 160, 100
	linie_verticala 320, 90, 200, 0008000h
	linie_verticala 321, 90, 200, 0008000h
	linie_verticala 322, 90, 200, 0008000h
	linie_verticala 323, 90, 200, 0008000h
	linie_verticala 324, 90, 200, 0008000h
	linie_verticala 325, 90, 200, 0008000h
	linie_verticala 326, 90, 200, 0008000h
	linie_verticala 327, 90, 200, 0008000h
	linie_verticala 328, 90, 200, 0008000h
	linie_verticala 329, 90, 200, 0008000h
	linie_verticala 330, 90, 200, 0008000h
	linie_verticala 330, 90, 200, 0008000h
	linie_verticala 331, 90, 200, 0008000h
	linie_verticala 332, 90, 200, 0008000h
	linie_verticala 333, 90, 200, 0008000h
	linie_verticala 334, 90, 200, 0008000h
	linie_verticala 335, 90, 200, 0008000h
	linie_verticala 336, 90, 200, 0008000h
	linie_verticala 337, 90, 200, 0008000h
	linie_verticala 338, 90, 200, 0008000h
	linie_verticala 339, 90, 200, 0008000h
	
	linie_orizontala 340, 90, 200, 0008000h
	linie_orizontala 340, 91, 200, 0008000h
	linie_orizontala 340, 92, 200, 0008000h
	linie_orizontala 340, 93, 200, 0008000h
	linie_orizontala 340, 94, 200, 0008000h
	linie_orizontala 340, 95, 200, 0008000h
	linie_orizontala 340, 96, 200, 0008000h
	linie_orizontala 340, 97, 200, 0008000h
	linie_orizontala 340, 98, 200, 0008000h
	linie_orizontala 340, 99, 200, 0008000h
	linie_orizontala 340, 100, 200, 0008000h
	linie_orizontala 340, 101, 200, 0008000h
	linie_orizontala 340, 102, 200, 0008000h
	linie_orizontala 340, 103, 200, 0008000h
	linie_orizontala 340, 104, 200, 0008000h
	linie_orizontala 340, 105, 200, 0008000h
	linie_orizontala 340, 106, 200, 0008000h
	linie_orizontala 340, 107, 200, 0008000h
	linie_orizontala 340, 108, 200, 0008000h
	linie_orizontala 340, 109, 200, 0008000h
	linie_orizontala 340, 110, 200, 0008000h
	linie_orizontala 340, 111, 200, 0008000h
	linie_verticala 540, 20, 92, 0008000h
	linie_verticala 541, 20, 92, 0008000h
	linie_verticala 542, 20, 92, 0008000h
	linie_verticala 543, 20, 92, 0008000h
	linie_verticala 544, 20, 92, 0008000h
	linie_verticala 545, 20, 92, 0008000h
	linie_verticala 546, 20, 92, 0008000h
	linie_verticala 547, 20, 92, 0008000h
	linie_verticala 548, 20, 92, 0008000h
	linie_verticala 549, 20, 92, 0008000h
	linie_verticala 550, 20, 92, 0008000h
	linie_verticala 551, 20, 92, 0008000h
	linie_verticala 552, 20, 92, 0008000h
	linie_verticala 553, 20, 92, 0008000h
	linie_verticala 554, 20, 92, 0008000h
	linie_verticala 555, 20, 92, 0008000h
	linie_verticala 556, 20, 92, 0008000h
	linie_verticala 557, 20, 92, 0008000h
	linie_verticala 558, 20, 92, 0008000h
	linie_verticala 559, 20, 92, 0008000h
	
	linie_orizontala 23, 95, 80, 0008000h
	linie_orizontala 23, 96, 80, 0008000h
	linie_orizontala 23, 97, 80, 0008000h
	linie_orizontala 23, 98, 80, 0008000h
	linie_orizontala 23, 99, 80, 0008000h
	linie_orizontala 23, 100, 80, 0008000h
	linie_orizontala 23, 101, 80, 0008000h
	linie_orizontala 23, 102, 80, 0008000h
	linie_orizontala 23, 103, 80, 0008000h
	linie_orizontala 23, 104, 80, 0008000h
	linie_orizontala 23, 105, 80, 0008000h
	linie_orizontala 23, 104, 80, 0008000h
	linie_orizontala 23, 105, 80, 0008000h
	linie_orizontala 23, 106, 80, 0008000h
	linie_orizontala 23, 107, 80, 0008000h
	linie_orizontala 23, 108, 80, 0008000h
	linie_orizontala 23, 109, 80, 0008000h
	linie_orizontala 23, 110, 80, 0008000h
	linie_orizontala 23, 111, 80, 0008000h
	linie_orizontala 23, 112, 80, 0008000h
	linie_orizontala 23, 113, 80, 0008000h
	linie_orizontala 23, 114, 80, 0008000h
	linie_orizontala 23, 115, 80, 0008000h
	
	linie_verticala 150, 220, 250, 0008000h
	linie_verticala 151, 220, 250, 0008000h
	linie_verticala 152, 220, 250, 0008000h
	linie_verticala 153, 220, 250, 0008000h
	linie_verticala 154, 220, 250, 0008000h
	linie_verticala 155, 220, 250, 0008000h
	linie_verticala 156, 220, 250, 0008000h
	linie_verticala 157, 220, 250, 0008000h
	linie_verticala 158, 220, 250, 0008000h
	linie_verticala 159, 220, 250, 0008000h
	linie_verticala 160, 220, 250, 0008000h
	linie_verticala 161, 220, 250, 0008000h
	linie_verticala 162, 220, 250, 0008000h
	linie_verticala 163, 220, 250, 0008000h
	linie_verticala 164, 220, 250, 0008000h
	linie_verticala 165, 220, 250, 0008000h
	linie_verticala 166, 220, 250, 0008000h
	linie_verticala 167, 220, 250, 0008000h
	linie_verticala 168, 220, 250, 0008000h
	linie_verticala 169, 220, 250, 0008000h
	linie_verticala 170, 220, 250, 0008000h
	
	linie_orizontala 430, 370, 50, 0008000h
	linie_orizontala 430, 371, 50, 0008000h
	linie_orizontala 430, 372, 50, 0008000h
	linie_orizontala 430, 373, 50, 0008000h
	linie_orizontala 430, 374, 50, 0008000h
	linie_orizontala 430, 375, 50, 0008000h
	linie_orizontala 430, 376, 50, 0008000h
	linie_orizontala 430, 377, 50, 0008000h
	linie_orizontala 430, 378, 50, 0008000h
	linie_orizontala 430, 379, 50, 0008000h
	linie_orizontala 430, 380, 50, 0008000h
	linie_orizontala 430, 381, 50, 0008000h
	linie_orizontala 430, 380, 50, 0008000h
	linie_orizontala 430, 381, 50, 0008000h
	linie_orizontala 430, 382, 50, 0008000h
	linie_orizontala 430, 383, 50, 0008000h
	linie_orizontala 430, 384, 50, 0008000h
	linie_orizontala 430, 385, 50, 0008000h
	linie_orizontala 430, 386, 50, 0008000h
	linie_orizontala 430, 387, 50, 0008000h
	linie_orizontala 430, 388, 50, 0008000h
	linie_orizontala 430, 389, 50, 0008000h	
	
	
	
	linie_orizontala 480, 180, 150, 0008000h
	linie_orizontala 480, 181, 150, 0008000h
	linie_orizontala 480, 182, 150, 0008000h
	linie_orizontala 480, 183, 150, 0008000h
	linie_orizontala 480, 184, 150, 0008000h
	linie_orizontala 480, 185, 150, 0008000h
	linie_orizontala 480, 186, 150, 0008000h
	linie_orizontala 480, 187, 150, 0008000h
	linie_orizontala 480, 188, 150, 0008000h
	linie_orizontala 480, 189, 150, 0008000h
	linie_orizontala 480, 190, 150, 0008000h
	linie_orizontala 480, 191, 150, 0008000h
	linie_orizontala 480, 192, 150, 0008000h
	linie_orizontala 480, 193, 150, 0008000h
	linie_orizontala 480, 194, 150, 0008000h
	linie_orizontala 480, 195, 150, 0008000h
	linie_orizontala 480, 196, 150, 0008000h
	linie_orizontala 480, 197, 150, 0008000h
	linie_orizontala 480, 198, 150, 0008000h
	linie_orizontala 480, 199, 150, 0008000h
	linie_orizontala 480, 200, 150, 0008000h
	cmp y_cap, 21
	jle game_over
	
	mov eax, y_cap
	sub eax, 5
	mov ebx, area_width
	mul ebx
	add eax, x_cap
	shl eax, 2
	add eax, area
	mov ecx, [eax]
	cmp ecx, 0008000h
	je game_over
	
	;verificare mancare:
	
	mov ebx, 0
	mov ebx, x_mancare    ;nu pot compara 2 variabile
	cmp x_cap, ebx
	jge x_mai_mare1
	cmp x_cap, ebx
	jl x_mai_mic1
	jmp sf_01
	
	x_mai_mare1:
		mov ebx, 0
		mov ebx, x_mancare
		add ebx, 24    ;latime mar
		cmp x_cap, ebx
		jle verific_y1
		jmp sf_01
		
	x_mai_mic1:
		mov ebx,0
		mov ebx, x_cap
		add ebx, 24
		cmp x_mancare,ebx
		jle verific_y1
		jmp sf_01
		
	verific_y1:
		mov ebx, 0
		mov ebx, y_mancare
		cmp y_cap, ebx
		jle y_mai_mic1
		cmp y_cap, ebx
		jg y_mai_mare1
		jmp sf_01
	
	y_mai_mic1:
		mov ebx,0
		mov ebx, y_cap
		add ebx, 24
		cmp y_mancare,ebx
		jle incrementare1
		jmp sf_01
	
	y_mai_mare1:
		mov ebx,0
		mov ebx,y_mancare
		add ebx, 24
		cmp y_cap,ebx
		jle incrementare1
		jmp sf_01
	
	
	incrementare1:    ;aici voi pune scorul
		
	rdtsc
	xor edx, edx   ;resetam edx la 0
	mov ecx, 620
	sub ecx, 20
	add ecx, 1
	div ecx
	add edx, 20
	mov x_mancare, edx    ;x random mancare
	
	xor edx, edx
	mov ecx, 460
	sub ecx, 20
	add ecx, 1
	div ecx
	add edx, 20
	mov y_mancare, edx    ;y random mancare 
		
	mov aux, 0
	inc counter
		
	; genereaza_mancare:
	sf_01:
	; cmp aux, 1
	; je nu_genera
	make_desen_macro '^',area, x_mancare,y_mancare
	mov aux, 1
	sub y_cap, 10 ;scade cu 10 pixeli
	mov eax, y_cap;
	add eax, 1
	mov y_cpy, eax  ;=> y_cpy=y_cap+1
	linie_orizontala x_cap, y_cap, 10, 800000h
	mov eax, x_cap
	mov x_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	jmp continuare
	
	
miscare_dreapta:
	make_text_macro ' ', area, 110, 100 ;x, y, x->coloane, y->linii
	make_text_macro ' ', area, 120, 100
	make_text_macro ' ', area, 130, 100
	make_text_macro ' ', area, 140, 100
	make_text_macro ' ', area, 150, 100
	make_text_macro ' ', area, 160, 100
	linie_verticala 320, 90, 200, 0008000h
	linie_verticala 321, 90, 200, 0008000h
	linie_verticala 322, 90, 200, 0008000h
	linie_verticala 323, 90, 200, 0008000h
	linie_verticala 324, 90, 200, 0008000h
	linie_verticala 325, 90, 200, 0008000h
	linie_verticala 326, 90, 200, 0008000h
	linie_verticala 327, 90, 200, 0008000h
	linie_verticala 328, 90, 200, 0008000h
	linie_verticala 329, 90, 200, 0008000h
	linie_verticala 330, 90, 200, 0008000h
	linie_verticala 330, 90, 200, 0008000h
	linie_verticala 331, 90, 200, 0008000h
	linie_verticala 332, 90, 200, 0008000h
	linie_verticala 333, 90, 200, 0008000h
	linie_verticala 334, 90, 200, 0008000h
	linie_verticala 335, 90, 200, 0008000h
	linie_verticala 336, 90, 200, 0008000h
	linie_verticala 337, 90, 200, 0008000h
	linie_verticala 338, 90, 200, 0008000h
	linie_verticala 339, 90, 200, 0008000h
	
	linie_orizontala 340, 90, 200, 0008000h
	linie_orizontala 340, 91, 200, 0008000h
	linie_orizontala 340, 92, 200, 0008000h
	linie_orizontala 340, 93, 200, 0008000h
	linie_orizontala 340, 94, 200, 0008000h
	linie_orizontala 340, 95, 200, 0008000h
	linie_orizontala 340, 96, 200, 0008000h
	linie_orizontala 340, 97, 200, 0008000h
	linie_orizontala 340, 98, 200, 0008000h
	linie_orizontala 340, 99, 200, 0008000h
	linie_orizontala 340, 100, 200, 0008000h
	linie_orizontala 340, 101, 200, 0008000h
	linie_orizontala 340, 102, 200, 0008000h
	linie_orizontala 340, 103, 200, 0008000h
	linie_orizontala 340, 104, 200, 0008000h
	linie_orizontala 340, 105, 200, 0008000h
	linie_orizontala 340, 106, 200, 0008000h
	linie_orizontala 340, 107, 200, 0008000h
	linie_orizontala 340, 108, 200, 0008000h
	linie_orizontala 340, 109, 200, 0008000h
	linie_orizontala 340, 110, 200, 0008000h
	linie_orizontala 340, 111, 200, 0008000h
	linie_verticala 540, 20, 92, 0008000h
	linie_verticala 541, 20, 92, 0008000h
	linie_verticala 542, 20, 92, 0008000h
	linie_verticala 543, 20, 92, 0008000h
	linie_verticala 544, 20, 92, 0008000h
	linie_verticala 545, 20, 92, 0008000h
	linie_verticala 546, 20, 92, 0008000h
	linie_verticala 547, 20, 92, 0008000h
	linie_verticala 548, 20, 92, 0008000h
	linie_verticala 549, 20, 92, 0008000h
	linie_verticala 550, 20, 92, 0008000h
	linie_verticala 551, 20, 92, 0008000h
	linie_verticala 552, 20, 92, 0008000h
	linie_verticala 553, 20, 92, 0008000h
	linie_verticala 554, 20, 92, 0008000h
	linie_verticala 555, 20, 92, 0008000h
	linie_verticala 556, 20, 92, 0008000h
	linie_verticala 557, 20, 92, 0008000h
	linie_verticala 558, 20, 92, 0008000h
	linie_verticala 559, 20, 92, 0008000h
	
	linie_orizontala 23, 95, 80, 0008000h
	linie_orizontala 23, 96, 80, 0008000h
	linie_orizontala 23, 97, 80, 0008000h
	linie_orizontala 23, 98, 80, 0008000h
	linie_orizontala 23, 99, 80, 0008000h
	linie_orizontala 23, 100, 80, 0008000h
	linie_orizontala 23, 101, 80, 0008000h
	linie_orizontala 23, 102, 80, 0008000h
	linie_orizontala 23, 103, 80, 0008000h
	linie_orizontala 23, 104, 80, 0008000h
	linie_orizontala 23, 105, 80, 0008000h
	linie_orizontala 23, 104, 80, 0008000h
	linie_orizontala 23, 105, 80, 0008000h
	linie_orizontala 23, 106, 80, 0008000h
	linie_orizontala 23, 107, 80, 0008000h
	linie_orizontala 23, 108, 80, 0008000h
	linie_orizontala 23, 109, 80, 0008000h
	linie_orizontala 23, 110, 80, 0008000h
	linie_orizontala 23, 111, 80, 0008000h
	linie_orizontala 23, 112, 80, 0008000h
	linie_orizontala 23, 113, 80, 0008000h
	linie_orizontala 23, 114, 80, 0008000h
	linie_orizontala 23, 115, 80, 0008000h
	
	linie_verticala 150, 220, 250, 0008000h
	linie_verticala 151, 220, 250, 0008000h
	linie_verticala 152, 220, 250, 0008000h
	linie_verticala 153, 220, 250, 0008000h
	linie_verticala 154, 220, 250, 0008000h
	linie_verticala 155, 220, 250, 0008000h
	linie_verticala 156, 220, 250, 0008000h
	linie_verticala 157, 220, 250, 0008000h
	linie_verticala 158, 220, 250, 0008000h
	linie_verticala 159, 220, 250, 0008000h
	linie_verticala 160, 220, 250, 0008000h
	linie_verticala 161, 220, 250, 0008000h
	linie_verticala 162, 220, 250, 0008000h
	linie_verticala 163, 220, 250, 0008000h
	linie_verticala 164, 220, 250, 0008000h
	linie_verticala 165, 220, 250, 0008000h
	linie_verticala 166, 220, 250, 0008000h
	linie_verticala 167, 220, 250, 0008000h
	linie_verticala 168, 220, 250, 0008000h
	linie_verticala 169, 220, 250, 0008000h
	linie_verticala 170, 220, 250, 0008000h
	
	linie_orizontala 430, 370, 50, 0008000h
	linie_orizontala 430, 371, 50, 0008000h
	linie_orizontala 430, 372, 50, 0008000h
	linie_orizontala 430, 373, 50, 0008000h
	linie_orizontala 430, 374, 50, 0008000h
	linie_orizontala 430, 375, 50, 0008000h
	linie_orizontala 430, 376, 50, 0008000h
	linie_orizontala 430, 377, 50, 0008000h
	linie_orizontala 430, 378, 50, 0008000h
	linie_orizontala 430, 379, 50, 0008000h
	linie_orizontala 430, 380, 50, 0008000h
	linie_orizontala 430, 381, 50, 0008000h
	linie_orizontala 430, 380, 50, 0008000h
	linie_orizontala 430, 381, 50, 0008000h
	linie_orizontala 430, 382, 50, 0008000h
	linie_orizontala 430, 383, 50, 0008000h
	linie_orizontala 430, 384, 50, 0008000h
	linie_orizontala 430, 385, 50, 0008000h
	linie_orizontala 430, 386, 50, 0008000h
	linie_orizontala 430, 387, 50, 0008000h
	linie_orizontala 430, 388, 50, 0008000h
	linie_orizontala 430, 389, 50, 0008000h	
	
	
	
	linie_orizontala 480, 180, 150, 0008000h
	linie_orizontala 480, 181, 150, 0008000h
	linie_orizontala 480, 182, 150, 0008000h
	linie_orizontala 480, 183, 150, 0008000h
	linie_orizontala 480, 184, 150, 0008000h
	linie_orizontala 480, 185, 150, 0008000h
	linie_orizontala 480, 186, 150, 0008000h
	linie_orizontala 480, 187, 150, 0008000h
	linie_orizontala 480, 188, 150, 0008000h
	linie_orizontala 480, 189, 150, 0008000h
	linie_orizontala 480, 190, 150, 0008000h
	linie_orizontala 480, 191, 150, 0008000h
	linie_orizontala 480, 192, 150, 0008000h
	linie_orizontala 480, 193, 150, 0008000h
	linie_orizontala 480, 194, 150, 0008000h
	linie_orizontala 480, 195, 150, 0008000h
	linie_orizontala 480, 196, 150, 0008000h
	linie_orizontala 480, 197, 150, 0008000h
	linie_orizontala 480, 198, 150, 0008000h
	linie_orizontala 480, 199, 150, 0008000h
	linie_orizontala 480, 200, 150, 0008000h
	
	cmp x_cap, 610
	jge game_over
	
	mov eax, x_cap
	add eax, 10
	mov aux, eax
	
	mov eax, y_cap
	mov ebx, area_width
	mul ebx
	add eax, aux
	shl eax, 2
	add eax, area
	mov ecx, [eax]
	cmp ecx, 0008000h
	je game_over
	
	;verificare mancare:
	mov ebx,0
	mov ebx,y_mancare
	cmp y_cap, ebx
	jle y_mai_mic2
	cmp y_cap,ebx
	jg y_mai_mare2
	jmp sf_02
	
	y_mai_mic2:
		mov ebx, 0
		mov ebx, y_cap
		add ebx, 24
		cmp y_mancare, ebx
		jle verific_x2
		jmp sf_02
		
	y_mai_mare2:
		mov ebx, 0
		mov ebx, y_mancare
		add ebx, 24
		cmp y_cap, ebx
		jle verific_x2
		jmp sf_02
		
	verific_x2:
		mov ebx, 0
		mov ebx, x_mancare
		cmp x_cap, ebx
		jle x_mai_mic2
		cmp x_cap, ebx
		jg x_mai_mare2
		jmp sf_02
	
	x_mai_mic2:
		mov ebx, 0
		mov ebx, x_cap
		add ebx, 24
		cmp x_mancare, ebx
		jle incrementare2
		jmp sf_02
		
	x_mai_mare2:
		mov ebx, 0
		mov ebx, x_mancare
		add ebx, 24
		cmp x_cap, ebx
		jle incrementare2
		jmp sf_02
		
	incrementare2:    
		rdtsc
		xor edx, edx   ;resetam edx la 0
		mov ecx, 620
		sub ecx, 20
		add ecx, 1
		div ecx
		add edx, 20
		mov x_mancare, edx    ;x random mancare
		
		xor edx, edx
		mov ecx, 460
		sub ecx, 20
		add ecx, 1
		div ecx
		add edx, 20
		mov y_mancare, edx    ;y random mancare 
			
		mov aux, 0
		inc counter
	
	sf_02:
	make_desen_macro '^',area, x_mancare,y_mancare
	
	mov eax, x_cap
	add eax, 10
	mov x_cap, eax
	mov x_cpy, eax
	linie_orizontala x_cap, y_cap, 10, 0800000h
	mov eax, y_cap
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov y_cpy, eax
	jmp continuare
	
miscare_stanga:
	make_text_macro ' ', area, 110, 100 ;x, y, x->coloane, y->linii
	make_text_macro ' ', area, 120, 100
	make_text_macro ' ', area, 130, 100
	make_text_macro ' ', area, 140, 100
	make_text_macro ' ', area, 150, 100
	make_text_macro ' ', area, 160, 100
	linie_verticala 320, 90, 200, 0008000h
	linie_verticala 321, 90, 200, 0008000h
	linie_verticala 322, 90, 200, 0008000h
	linie_verticala 323, 90, 200, 0008000h
	linie_verticala 324, 90, 200, 0008000h
	linie_verticala 325, 90, 200, 0008000h
	linie_verticala 326, 90, 200, 0008000h
	linie_verticala 327, 90, 200, 0008000h
	linie_verticala 328, 90, 200, 0008000h
	linie_verticala 329, 90, 200, 0008000h
	linie_verticala 330, 90, 200, 0008000h
	linie_verticala 330, 90, 200, 0008000h
	linie_verticala 331, 90, 200, 0008000h
	linie_verticala 332, 90, 200, 0008000h
	linie_verticala 333, 90, 200, 0008000h
	linie_verticala 334, 90, 200, 0008000h
	linie_verticala 335, 90, 200, 0008000h
	linie_verticala 336, 90, 200, 0008000h
	linie_verticala 337, 90, 200, 0008000h
	linie_verticala 338, 90, 200, 0008000h
	linie_verticala 339, 90, 200, 0008000h
	
	linie_orizontala 340, 90, 200, 0008000h
	linie_orizontala 340, 91, 200, 0008000h
	linie_orizontala 340, 92, 200, 0008000h
	linie_orizontala 340, 93, 200, 0008000h
	linie_orizontala 340, 94, 200, 0008000h
	linie_orizontala 340, 95, 200, 0008000h
	linie_orizontala 340, 96, 200, 0008000h
	linie_orizontala 340, 97, 200, 0008000h
	linie_orizontala 340, 98, 200, 0008000h
	linie_orizontala 340, 99, 200, 0008000h
	linie_orizontala 340, 100, 200, 0008000h
	linie_orizontala 340, 101, 200, 0008000h
	linie_orizontala 340, 102, 200, 0008000h
	linie_orizontala 340, 103, 200, 0008000h
	linie_orizontala 340, 104, 200, 0008000h
	linie_orizontala 340, 105, 200, 0008000h
	linie_orizontala 340, 106, 200, 0008000h
	linie_orizontala 340, 107, 200, 0008000h
	linie_orizontala 340, 108, 200, 0008000h
	linie_orizontala 340, 109, 200, 0008000h
	linie_orizontala 340, 110, 200, 0008000h
	linie_orizontala 340, 111, 200, 0008000h
	linie_verticala 540, 20, 92, 0008000h
	linie_verticala 541, 20, 92, 0008000h
	linie_verticala 542, 20, 92, 0008000h
	linie_verticala 543, 20, 92, 0008000h
	linie_verticala 544, 20, 92, 0008000h
	linie_verticala 545, 20, 92, 0008000h
	linie_verticala 546, 20, 92, 0008000h
	linie_verticala 547, 20, 92, 0008000h
	linie_verticala 548, 20, 92, 0008000h
	linie_verticala 549, 20, 92, 0008000h
	linie_verticala 550, 20, 92, 0008000h
	linie_verticala 551, 20, 92, 0008000h
	linie_verticala 552, 20, 92, 0008000h
	linie_verticala 553, 20, 92, 0008000h
	linie_verticala 554, 20, 92, 0008000h
	linie_verticala 555, 20, 92, 0008000h
	linie_verticala 556, 20, 92, 0008000h
	linie_verticala 557, 20, 92, 0008000h
	linie_verticala 558, 20, 92, 0008000h
	linie_verticala 559, 20, 92, 0008000h
	
	linie_orizontala 23, 95, 80, 0008000h
	linie_orizontala 23, 96, 80, 0008000h
	linie_orizontala 23, 97, 80, 0008000h
	linie_orizontala 23, 98, 80, 0008000h
	linie_orizontala 23, 99, 80, 0008000h
	linie_orizontala 23, 100, 80, 0008000h
	linie_orizontala 23, 101, 80, 0008000h
	linie_orizontala 23, 102, 80, 0008000h
	linie_orizontala 23, 103, 80, 0008000h
	linie_orizontala 23, 104, 80, 0008000h
	linie_orizontala 23, 105, 80, 0008000h
	linie_orizontala 23, 104, 80, 0008000h
	linie_orizontala 23, 105, 80, 0008000h
	linie_orizontala 23, 106, 80, 0008000h
	linie_orizontala 23, 107, 80, 0008000h
	linie_orizontala 23, 108, 80, 0008000h
	linie_orizontala 23, 109, 80, 0008000h
	linie_orizontala 23, 110, 80, 0008000h
	linie_orizontala 23, 111, 80, 0008000h
	linie_orizontala 23, 112, 80, 0008000h
	linie_orizontala 23, 113, 80, 0008000h
	linie_orizontala 23, 114, 80, 0008000h
	linie_orizontala 23, 115, 80, 0008000h
	
	linie_verticala 150, 220, 250, 0008000h
	linie_verticala 151, 220, 250, 0008000h
	linie_verticala 152, 220, 250, 0008000h
	linie_verticala 153, 220, 250, 0008000h
	linie_verticala 154, 220, 250, 0008000h
	linie_verticala 155, 220, 250, 0008000h
	linie_verticala 156, 220, 250, 0008000h
	linie_verticala 157, 220, 250, 0008000h
	linie_verticala 158, 220, 250, 0008000h
	linie_verticala 159, 220, 250, 0008000h
	linie_verticala 160, 220, 250, 0008000h
	linie_verticala 161, 220, 250, 0008000h
	linie_verticala 162, 220, 250, 0008000h
	linie_verticala 163, 220, 250, 0008000h
	linie_verticala 164, 220, 250, 0008000h
	linie_verticala 165, 220, 250, 0008000h
	linie_verticala 166, 220, 250, 0008000h
	linie_verticala 167, 220, 250, 0008000h
	linie_verticala 168, 220, 250, 0008000h
	linie_verticala 169, 220, 250, 0008000h
	linie_verticala 170, 220, 250, 0008000h
	
	linie_orizontala 430, 370, 50, 0008000h
	linie_orizontala 430, 371, 50, 0008000h
	linie_orizontala 430, 372, 50, 0008000h
	linie_orizontala 430, 373, 50, 0008000h
	linie_orizontala 430, 374, 50, 0008000h
	linie_orizontala 430, 375, 50, 0008000h
	linie_orizontala 430, 376, 50, 0008000h
	linie_orizontala 430, 377, 50, 0008000h
	linie_orizontala 430, 378, 50, 0008000h
	linie_orizontala 430, 379, 50, 0008000h
	linie_orizontala 430, 380, 50, 0008000h
	linie_orizontala 430, 381, 50, 0008000h
	linie_orizontala 430, 380, 50, 0008000h
	linie_orizontala 430, 381, 50, 0008000h
	linie_orizontala 430, 382, 50, 0008000h
	linie_orizontala 430, 383, 50, 0008000h
	linie_orizontala 430, 384, 50, 0008000h
	linie_orizontala 430, 385, 50, 0008000h
	linie_orizontala 430, 386, 50, 0008000h
	linie_orizontala 430, 387, 50, 0008000h
	linie_orizontala 430, 388, 50, 0008000h
	linie_orizontala 430, 389, 50, 0008000h	
	
	
	
	linie_orizontala 480, 180, 150, 0008000h
	linie_orizontala 480, 181, 150, 0008000h
	linie_orizontala 480, 182, 150, 0008000h
	linie_orizontala 480, 183, 150, 0008000h
	linie_orizontala 480, 184, 150, 0008000h
	linie_orizontala 480, 185, 150, 0008000h
	linie_orizontala 480, 186, 150, 0008000h
	linie_orizontala 480, 187, 150, 0008000h
	linie_orizontala 480, 188, 150, 0008000h
	linie_orizontala 480, 189, 150, 0008000h
	linie_orizontala 480, 190, 150, 0008000h
	linie_orizontala 480, 191, 150, 0008000h
	linie_orizontala 480, 192, 150, 0008000h
	linie_orizontala 480, 193, 150, 0008000h
	linie_orizontala 480, 194, 150, 0008000h
	linie_orizontala 480, 195, 150, 0008000h
	linie_orizontala 480, 196, 150, 0008000h
	linie_orizontala 480, 197, 150, 0008000h
	linie_orizontala 480, 198, 150, 0008000h
	linie_orizontala 480, 199, 150, 0008000h
	linie_orizontala 480, 200, 150, 0008000h
	
	cmp x_cap, 21
	jle game_over
	
	mov eax, x_cap
	sub eax, 7
	mov aux, eax
	
	mov eax, y_cap
	mov ebx, area_width
	mul ebx
	add eax, aux
	shl eax, 2
	add eax, area
	mov ecx, [eax]
	cmp ecx, 0008000h
	je game_over
	
	;verificare mancare:
	mov ebx, 0
	mov ebx,y_mancare
	cmp y_cap,ebx
	jle y_mai_mic3
	cmp y_cap,ebx
	jg y_mai_mare3
	jmp sf_03
	
	y_mai_mic3:
		mov ebx, 0
		mov ebx, y_cap
		add ebx, 24
		cmp y_mancare, ebx
		jle verific_x3
		jmp sf_03
	
	y_mai_mare3:
		mov ebx, 0
		mov ebx, y_mancare
		add ebx, 24
		cmp y_cap, ebx
		jle verific_x3
		jmp sf_03
		
	verific_x3:
		mov ebx, 0
		mov ebx, x_mancare
		cmp x_cap, ebx
		jle x_mai_mic3
		cmp x_cap, ebx
		jg x_mai_mare3
		jmp sf_03
		
	x_mai_mic3:
		mov ebx, 0
		mov ebx, x_cap
		add ebx, 24
		cmp x_mancare, ebx
		jle incrementare3
		jmp sf_03
		
	x_mai_mare3:
		mov ebx, 0
		mov ebx, x_mancare
		add ebx, 24
		cmp x_cap, ebx
		jle incrementare3
		jmp sf_03
		
	incrementare3:    
		rdtsc
		xor edx, edx   ;resetam edx la 0
		mov ecx, 620
		sub ecx, 20
		add ecx, 1
		div ecx
		add edx, 20
		mov x_mancare, edx    ;x random mancare
		
		xor edx, edx
		mov ecx, 460
		sub ecx, 20
		add ecx, 1
		div ecx
		add edx, 20
		mov y_mancare, edx    ;y random mancare 
			
		mov aux, 0
		inc counter
	
	
	sf_03: 
	make_desen_macro '^',area, x_mancare,y_mancare
	
	mov eax, x_cap
	sub eax, 10
	mov x_cap, eax
	mov x_cpy, eax
	linie_orizontala x_cap, y_cap, 10, 0800000h
	mov eax, y_cap
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov y_cpy, eax
	jmp continuare
	
miscare_jos:
	make_text_macro ' ', area, 110, 100 ;x, y, x->coloane, y->linii
	make_text_macro ' ', area, 120, 100
	make_text_macro ' ', area, 130, 100
	make_text_macro ' ', area, 140, 100
	make_text_macro ' ', area, 150, 100
	make_text_macro ' ', area, 160, 100
	linie_verticala 320, 90, 200, 0008000h
	linie_verticala 321, 90, 200, 0008000h
	linie_verticala 322, 90, 200, 0008000h
	linie_verticala 323, 90, 200, 0008000h
	linie_verticala 324, 90, 200, 0008000h
	linie_verticala 325, 90, 200, 0008000h
	linie_verticala 326, 90, 200, 0008000h
	linie_verticala 327, 90, 200, 0008000h
	linie_verticala 328, 90, 200, 0008000h
	linie_verticala 329, 90, 200, 0008000h
	linie_verticala 330, 90, 200, 0008000h
	linie_verticala 330, 90, 200, 0008000h
	linie_verticala 331, 90, 200, 0008000h
	linie_verticala 332, 90, 200, 0008000h
	linie_verticala 333, 90, 200, 0008000h
	linie_verticala 334, 90, 200, 0008000h
	linie_verticala 335, 90, 200, 0008000h
	linie_verticala 336, 90, 200, 0008000h
	linie_verticala 337, 90, 200, 0008000h
	linie_verticala 338, 90, 200, 0008000h
	linie_verticala 339, 90, 200, 0008000h
	
	linie_orizontala 340, 90, 200, 0008000h
	linie_orizontala 340, 91, 200, 0008000h
	linie_orizontala 340, 92, 200, 0008000h
	linie_orizontala 340, 93, 200, 0008000h
	linie_orizontala 340, 94, 200, 0008000h
	linie_orizontala 340, 95, 200, 0008000h
	linie_orizontala 340, 96, 200, 0008000h
	linie_orizontala 340, 97, 200, 0008000h
	linie_orizontala 340, 98, 200, 0008000h
	linie_orizontala 340, 99, 200, 0008000h
	linie_orizontala 340, 100, 200, 0008000h
	linie_orizontala 340, 101, 200, 0008000h
	linie_orizontala 340, 102, 200, 0008000h
	linie_orizontala 340, 103, 200, 0008000h
	linie_orizontala 340, 104, 200, 0008000h
	linie_orizontala 340, 105, 200, 0008000h
	linie_orizontala 340, 106, 200, 0008000h
	linie_orizontala 340, 107, 200, 0008000h
	linie_orizontala 340, 108, 200, 0008000h
	linie_orizontala 340, 109, 200, 0008000h
	linie_orizontala 340, 110, 200, 0008000h
	linie_orizontala 340, 111, 200, 0008000h
	linie_verticala 540, 20, 92, 0008000h
	linie_verticala 541, 20, 92, 0008000h
	linie_verticala 542, 20, 92, 0008000h
	linie_verticala 543, 20, 92, 0008000h
	linie_verticala 544, 20, 92, 0008000h
	linie_verticala 545, 20, 92, 0008000h
	linie_verticala 546, 20, 92, 0008000h
	linie_verticala 547, 20, 92, 0008000h
	linie_verticala 548, 20, 92, 0008000h
	linie_verticala 549, 20, 92, 0008000h
	linie_verticala 550, 20, 92, 0008000h
	linie_verticala 551, 20, 92, 0008000h
	linie_verticala 552, 20, 92, 0008000h
	linie_verticala 553, 20, 92, 0008000h
	linie_verticala 554, 20, 92, 0008000h
	linie_verticala 555, 20, 92, 0008000h
	linie_verticala 556, 20, 92, 0008000h
	linie_verticala 557, 20, 92, 0008000h
	linie_verticala 558, 20, 92, 0008000h
	linie_verticala 559, 20, 92, 0008000h
	
	linie_orizontala 23, 95, 80, 0008000h
	linie_orizontala 23, 96, 80, 0008000h
	linie_orizontala 23, 97, 80, 0008000h
	linie_orizontala 23, 98, 80, 0008000h
	linie_orizontala 23, 99, 80, 0008000h
	linie_orizontala 23, 100, 80, 0008000h
	linie_orizontala 23, 101, 80, 0008000h
	linie_orizontala 23, 102, 80, 0008000h
	linie_orizontala 23, 103, 80, 0008000h
	linie_orizontala 23, 104, 80, 0008000h
	linie_orizontala 23, 105, 80, 0008000h
	linie_orizontala 23, 104, 80, 0008000h
	linie_orizontala 23, 105, 80, 0008000h
	linie_orizontala 23, 106, 80, 0008000h
	linie_orizontala 23, 107, 80, 0008000h
	linie_orizontala 23, 108, 80, 0008000h
	linie_orizontala 23, 109, 80, 0008000h
	linie_orizontala 23, 110, 80, 0008000h
	linie_orizontala 23, 111, 80, 0008000h
	linie_orizontala 23, 112, 80, 0008000h
	linie_orizontala 23, 113, 80, 0008000h
	linie_orizontala 23, 114, 80, 0008000h
	linie_orizontala 23, 115, 80, 0008000h
	
	linie_verticala 150, 220, 250, 0008000h
	linie_verticala 151, 220, 250, 0008000h
	linie_verticala 152, 220, 250, 0008000h
	linie_verticala 153, 220, 250, 0008000h
	linie_verticala 154, 220, 250, 0008000h
	linie_verticala 155, 220, 250, 0008000h
	linie_verticala 156, 220, 250, 0008000h
	linie_verticala 157, 220, 250, 0008000h
	linie_verticala 158, 220, 250, 0008000h
	linie_verticala 159, 220, 250, 0008000h
	linie_verticala 160, 220, 250, 0008000h
	linie_verticala 161, 220, 250, 0008000h
	linie_verticala 162, 220, 250, 0008000h
	linie_verticala 163, 220, 250, 0008000h
	linie_verticala 164, 220, 250, 0008000h
	linie_verticala 165, 220, 250, 0008000h
	linie_verticala 166, 220, 250, 0008000h
	linie_verticala 167, 220, 250, 0008000h
	linie_verticala 168, 220, 250, 0008000h
	linie_verticala 169, 220, 250, 0008000h
	linie_verticala 170, 220, 250, 0008000h
	
	linie_orizontala 430, 370, 50, 0008000h
	linie_orizontala 430, 371, 50, 0008000h
	linie_orizontala 430, 372, 50, 0008000h
	linie_orizontala 430, 373, 50, 0008000h
	linie_orizontala 430, 374, 50, 0008000h
	linie_orizontala 430, 375, 50, 0008000h
	linie_orizontala 430, 376, 50, 0008000h
	linie_orizontala 430, 377, 50, 0008000h
	linie_orizontala 430, 378, 50, 0008000h
	linie_orizontala 430, 379, 50, 0008000h
	linie_orizontala 430, 380, 50, 0008000h
	linie_orizontala 430, 381, 50, 0008000h
	linie_orizontala 430, 380, 50, 0008000h
	linie_orizontala 430, 381, 50, 0008000h
	linie_orizontala 430, 382, 50, 0008000h
	linie_orizontala 430, 383, 50, 0008000h
	linie_orizontala 430, 384, 50, 0008000h
	linie_orizontala 430, 385, 50, 0008000h
	linie_orizontala 430, 386, 50, 0008000h
	linie_orizontala 430, 387, 50, 0008000h
	linie_orizontala 430, 388, 50, 0008000h
	linie_orizontala 430, 389, 50, 0008000h	
	
	
	
	linie_orizontala 480, 180, 150, 0008000h
	linie_orizontala 480, 181, 150, 0008000h
	linie_orizontala 480, 182, 150, 0008000h
	linie_orizontala 480, 183, 150, 0008000h
	linie_orizontala 480, 184, 150, 0008000h
	linie_orizontala 480, 185, 150, 0008000h
	linie_orizontala 480, 186, 150, 0008000h
	linie_orizontala 480, 187, 150, 0008000h
	linie_orizontala 480, 188, 150, 0008000h
	linie_orizontala 480, 189, 150, 0008000h
	linie_orizontala 480, 190, 150, 0008000h
	linie_orizontala 480, 191, 150, 0008000h
	linie_orizontala 480, 192, 150, 0008000h
	linie_orizontala 480, 193, 150, 0008000h
	linie_orizontala 480, 194, 150, 0008000h
	linie_orizontala 480, 195, 150, 0008000h
	linie_orizontala 480, 196, 150, 0008000h
	linie_orizontala 480, 197, 150, 0008000h
	linie_orizontala 480, 198, 150, 0008000h
	linie_orizontala 480, 199, 150, 0008000h
	linie_orizontala 480, 200, 150, 0008000h
	; cmp y_cpy, 460
	; jge game_over
	
	mov eax, y_cap
	add eax, 19
	mov ebx, area_width
	mul ebx
	add eax, x_cap
	shl eax, 2
	add eax, area
	mov ecx, [eax]
	cmp ecx, 0008000h
	je game_over
	
	
	;verificare mancare:
	mov ebx,0
	mov ebx, x_mancare
	cmp x_cap,ebx
	jle x_mai_mic4
	cmp x_cap, ebx
	jg x_mai_mare4
	jmp sf_04
	
	x_mai_mic4:
		mov ebx, 0
		mov ebx, x_cap
		add ebx, 24
		cmp x_mancare, ebx
		jle verific_y4
		jmp sf_04
		
	x_mai_mare4:
		mov ebx, 0
		mov ebx, x_mancare
		add ebx, 24
		cmp x_cap, ebx
		jle verific_y4
		jmp sf_04
		
	verific_y4:
		mov ebx,0
		mov ebx, y_mancare
		cmp y_cap,ebx
		jle y_mai_mic4
		cmp y_cap,ebx
		jg y_mai_mare4
		jmp sf_04
		
	y_mai_mic4:
		mov ebx, 0
		mov ebx, y_cap
		add ebx, 24
		cmp y_mancare, ebx
		jle incrementare4
		jmp sf_04
		
	y_mai_mare4:
		mov ebx, 0
		mov ebx, y_mancare
		add ebx, 24
		cmp x_cap, ebx
		jle incrementare4
		jmp sf_04
		
		
	incrementare4:    
		rdtsc
		xor edx, edx   ;resetam edx la 0
		mov ecx, 620
		sub ecx, 20
		add ecx, 1
		div ecx
		add edx, 20
		mov x_mancare, edx    ;x random mancare
		
		xor edx, edx
		mov ecx, 460
		sub ecx, 20
		add ecx, 1
		div ecx
		add edx, 20
		mov y_mancare, edx    ;y random mancare 
			
		mov aux, 0
		inc counter
	
	
	sf_04:
	make_desen_macro '^',area, x_mancare,y_mancare
	
	add y_cap, 10 ;scade cu 10 pixeli
	mov eax, y_cap;
	add eax, 1
	mov y_cpy, eax  ;=> y_cpy=y_cap+1
	linie_orizontala x_cap, y_cap, 10, 800000h
	
	mov eax, x_cap
	mov x_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	mov eax, y_cpy
	add eax, 1
	mov y_cpy, eax
	linie_orizontala x_cpy, y_cpy, 10, 0FFFF00h
	jmp continuare
	
	continuare: 
	
	jmp final_draw	 
	
	
	
game_over:
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 0FFFFFFh
	push area
	call memset
	add esp, 12
	make_text_macro 'G', area, 210, 170
	make_text_macro 'A', area, 220, 170
	make_text_macro 'M', area, 230, 170
	make_text_macro 'E', area, 240, 170
	make_text_macro ' ', area, 250, 170
	make_text_macro 'O', area, 260, 170
	make_text_macro 'V', area, 270, 170
	make_text_macro 'E', area, 280, 170
	make_text_macro 'R', area, 290, 170
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret

draw endp



start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width 
	mov ebx, area_height
	;inmultimi pt a aloca memorie
	mul ebx
	shl eax, 2 ;inmultim cu 4, deoarece fiecare pixel din zona de desenat ocuoa un dubleword <=> 4 bytes
	push eax
	call malloc ;apeleaza in memorie pt zona de desenat
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw ;proc princ in program
	push area ;zona de desenat. aici noi putem scrie cod si reactionam la anumite evenimente
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	

	
	;terminarea programului
	push 0
	call exit
end start
