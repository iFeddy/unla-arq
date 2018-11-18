		#INCLUDE<P16F628.INC>
		__CONFIG 3F10
		
;DECLARACION DE ESPACIOS DE MEMORIA A USAR		
		CBLOCK	0X20
		D1									;VARIABLE CON EL VALOR DEL DISPLAY 1
		D2									;VARIABLE CON EL VALOR DEL DISPLAY 2
		D3									;VARIABLE CON EL VALOR DEL DISPLAY 3
		D4									;VARIABLE CON EL VALOR DEL DISPLAY 4
		N1_LOADED							; FLAG DE N1 CARGADO
		N1_D1								; DIGITOS DE N1
		N1_D2
		N1_D3
		N1_D4
		N2_LOADED							; FLAG DE N2 CARGADO
		N2_D1								; DIGITOS DE N2
		N2_D2
		N2_D3
		N2_D4
		RES_NEG								;FLAG DE RESULTADO NEGATIVO
		CONT_RES							; CONTADORES DE LOOPS DE RESTA
		CONT_RES2
		CONT_RES3

		AUX_D1								; AUXILIAR 1 PARA LA RESTA
		AUX_D2
		AUX_D3
		AUX_D4
		AUX2_D1								; AUXILIAR 2 PARA LA RESTA
		AUX2_D2
		AUX2_D3
		AUX2_D4

		AUX_W								; AUXILIAR PARA W EN INTERRUPCION
		AUX_STATUS							; AUXILIAR PARA STATUS EN INTERRUPCION
		CONT_AR								; CONTADORES ANTIREBOTE
		CONT_AR_2
;		INPUT_1								;PRIMER INPUT (0x0000 A 0x0FFF)
;		INPUT_2								;SEGUNDO INPUT (0x0000 A 0x0FFF)
;		RESULTADO							;RESULTADO (0x0000 A 0x0FFF)

		ENDC		

;DECLARACION DE CONSTATNES
#DEFINE BTN_G1 	PORTA,6
#DEFINE BTN_G2 	PORTA,7
#DEFINE BTN_R 	PORTA,4
#DEFINE BTN_M 	PORTB,0

#DEFINE PIN_D1 	3
#DEFINE PIN_D2 	2
#DEFINE PIN_D3 	1
#DEFINE PIN_D4 	0

#DEFINE	CTRL_DISPLAY	PORTA
#DEFINE	APAGAR_DISPLAYS CLRF	PORTA
#DEFINE HEXA	.16

;DECLARACION DE MACROS

MOSTRAR	MACRO	DIGITO,PIN
		APAGAR_DISPLAYS
		MOVF	DIGITO,W
		CALL	TAB_DISPLAY
		MOVWF	PORTB
		BSF		CTRL_DISPLAY,PIN
		ENDM

SUMAR	MACRO	DIGITO
		INCF	DIGITO,1
		MOVF	DIGITO,W			; DIGITO ESTA EN DECIMAL (VER DE GUARDAR ESTO Y NO LOS DISPLAY)
		XORLW	.16					; LIMITE DE DIGITO -1
		BTFSC	STATUS,Z			; SI LLEGO AL LIMITE Z = 0
		CLRF	DIGITO				; LO PONE EN 0 PORQUE Z = 0
		BTFSC	STATUS,Z
		CALL	LOOP_DISPLAY
		ENDM		
				
DISMEN	MACRO	DIGITO
		MOVLW	0x10 			; .16
		MOVWF	DIGITO
		ENDM

DISAPA	MACRO	DIGITO
		MOVLW	0x11			;.17
		MOVWF	DIGITO
		ENDM



;INICIO DEL PROGRAMA
		
		ORG		0X00
		GOTO	CONFI
		ORG		0X04		
		GOTO	INT_TMR0
;RUTINA DE INTERRUPCION
;DESBORDA EL TIMER CADA 15ms
;MUESTRA TODOS LOS DIGITOS DE ACUERDO A LAS VARIABLES D1:4

;GUARDA STATUS Y W EN VARIABLES AUXILIARES
INT_TMR0
		BCF		INTCON,GIE
		BCF		INTCON,T0IF	
		MOVWF	AUX_W
		MOVF	STATUS,W
		MOVWF	AUX_STATUS
;MULTIPLEXADO DE DISPLAYS
		BTFSC	CTRL_DISPLAY,PIN_D1
		GOTO	MOSTRAR_D2			
		BTFSC	CTRL_DISPLAY,PIN_D2
		GOTO	MOSTRAR_D3
		BTFSC	CTRL_DISPLAY,PIN_D3
		GOTO	MOSTRAR_D4
		;GOTO 	FIN_T0I
		
		MOSTRAR	D1,PIN_D1
		GOTO 	FIN_T0I

MOSTRAR_D2
		MOSTRAR D2,PIN_D2
		GOTO 	FIN_T0I
MOSTRAR_D3
		MOSTRAR D3,PIN_D3
		GOTO 	FIN_T0I
MOSTRAR_D4
		MOSTRAR	D4,PIN_D4
		
FIN_T0I
;REINICIA TIMER Y RECUPERA STATUS Y W
		MOVLW	.220
		MOVWF	TMR0
		MOVF	AUX_STATUS,W
		MOVWF	STATUS
		MOVF	AUX_W,W
		RETFIE

;CONFIGURACION
		
CONFI
		BCF		STATUS,RP0 ; me muevo al Banco 0
		BCF		STATUS,RP1
		BSF		INTCON,GIE
;		BSF		INTCON,PEIE
		BSF		INTCON,T0IE

		MOVLW	0X07
		MOVWF	CMCON; CMCON SE TIENE QUE ESTABLECER EN 7 PARA USAR TODO EL PORTA
		MOVLW	.220
		MOVWF	TMR0
		
		BSF		STATUS,RP0		; me muevo al Banco 1
		MOVLW	b'00000001'
		MOVWF	TRISB	
		MOVLW	b'11010000'
		MOVWF	TRISA
		BCF		OPTION_REG,T0CS
		BCF		OPTION_REG,PSA
		BSF		OPTION_REG,PS0
		BSF		OPTION_REG,PS1
		BSF		OPTION_REG,PS2
		BCF		STATUS,RP0		; regreso al Banco 0


;RUTINA PRINCIPAL
;INCREMENTA DE 0 A 9 CADA DIGITO DEPENDIENDO QUE BOTON SE TOCA. 

		CLRF	PORTA
		CLRF	PORTB
		CALL 	LIMPIAR_DISPLAY
		CALL	LIMPIAR_N1_N2
		CALL	INI_EEP			; LIMPIO EEPROM
		CALL	LEERD
		CALL	LEERN1
		CALL	LEERN2
		CALL	LEERR
BOTONES
		BTFSC	BTN_G1			;BOTON G1 = INCREMENTA
		CALL	DEMORA_AR
		BTFSC	BTN_G1			
		GOTO	BTN_G1A			; TIENE QUE SUMAR DE 000 A FFF 
		
		BTFSC	BTN_G2			;BOTON G2 = RESTA
		CALL	DEMORA_AR
		BTFSC	BTN_G2	
		GOTO	BTN_G2A			;VERFICA LOS DISPLAY Y LE RESTA DE A 1

		BTFSC	BTN_R			; BOTON R = RESETEAR A CERO
		CALL	DEMORA_AR
		BTFSC	BTN_R
		GOTO	BTN_RA			;REINICIA LAS VARIABLES

		BTFSC	BTN_M			; BOTON M = CAMBIO DE INPUT O RESUELVO RESTA
		CALL	DEMORA_AR
		BTFSC	BTN_M
		GOTO	BTN_MA			;DEPENDIENDO DE LOS FLAGS N1_LOADED Y N2_LOADED CARGO N1 O CARGO N2 Y HAGO LA RESTA

		GOTO 	BOTONES

BTN_G1A	SUMAR	D4				; HAGO LA SUMA Y GRABO VALORES EN EEPROM
		CALL	GRABAR_TODO
		GOTO	BOTONES

BTN_G2A	CALL	RESTAR_1		; RESTO DE A UNO Y GRABO VALORES EN EEPROM
		CALL	GRABAR_TODO
		GOTO	BOTONES

BTN_RA	CALL	REINICIAR		; REINICIO VALORES Y LOS GRABO EN EEPROM
		CALL	GRABAR_TODO
		GOTO	BOTONES

BTN_MA	CALL	SETVARIABLE		; CAMBIO DE INPUT O RESUELVO Y GRABO CAMBIOS EN EEPROM
		CALL	GRABAR_TODO
		GOTO	BOTONES


GRABAR_TODO						; GRABO TODO EN EEPROM
		CALL	GRABD			;	GRABO VALORES DEL DISPLAY
		CALL	GRABN1			;	GRABO VALORES DEL NUMERO 1 (N1) 
		CALL	GRABN2			;	GRABO VALORES DEL NUMERO 2 (N2)
		CALL	GRABR			;	GRABO VALORES DEL NUMERO 1 (N1)
		RETURN

SETVARIABLE
		BTFSS	N1_LOADED,1			; IF N1_LOADED - Si no cargue 1 lo cargo
		GOTO	CARGAR_N1			; SI
		BTFSS	N2_LOADED,1			; IF N2_LOADED - Si no cargue 2 lo cargo, otro caso no hago nada
		GOTO	CARGAR_N2			; NO

FIN_SETVAR
		RETURN

CARGAR_N1							; CARGO VALORES DEL DISPLAY EN EL NUMERO 1 (N1) Y LIMPIO DISPLAY		
		MOVF	D1,W
		MOVWF	N1_D1
		MOVF	D2,W
		MOVWF	N1_D2
		MOVF	D3,W
		MOVWF	N1_D3
		MOVF	D4,W
		MOVWF	N1_D4
		BSF 	N1_LOADED,1
		CALL	LIMPIAR_DISPLAY
		GOTO	FIN_SETVAR

CARGAR_N2							; CARGO VALORES DEL DISPLAY EN EL NUMERO 2 (N2), LIMPIO DISPLAY Y HAGO LA RESTA
		MOVF	D1,W
		MOVWF	N2_D1
		MOVF	D2,W
		MOVWF	N2_D2
		MOVF	D3,W
		MOVWF	N2_D3
		MOVF	D4,W
		MOVWF	N2_D4
		BSF 	N2_LOADED,1			;ESTAN CARGADOS LOS DOS
		CALL	LIMPIAR_DISPLAY		;PONE EN 000
		CALL	HACER_RESTA			;RESUELVE LA RESTA
		GOTO	FIN_SETVAR			


REINICIAR							; LIMPIO VALORES Y LOS GRABO EN EEPROM
		CALL	LIMPIAR_DISPLAY		;		LIMPIA DISPLAY Y DEJA LAS VARIABLES EN 0
		CALL	LIMPIAR_N1_N2		;		LIMPIO N1, N2 Y FLAGS
		CLRF	RES_NEG				;		LIMPIO FLAG DE RESULTADO NEGATIVO
		CALL	GRABAR_TODO			;		GRABO TODO EN EEPROM
		RETURN

LOOP_DISPLAY
		MOVF	D4,0			;D3 (VER SI NO ESTAN MEZCLADOS EN EL REAL) 
		SUBLW	.16
		BTFSS	STATUS,W		;W = 0
		RETURN
		INCF	D3,1				; SI ES 16 EMPEZAR A SUMARLE AL TERCER DISPLAY
		MOVF	D3,W
		XORLW	.16				; LIMITE DE DIGITO -1
		BTFSC	STATUS,Z		; SI LLEGO AL LIMITE Z = 1
		CLRF	D3				; LO PONE EN 0 PORQUE Z = 1
		BTFSC	STATUS,Z			
		MOVF	D3,0			;D4 (VER) SI ES 0 SUMARLE UNO A D2
		SUBLW	.16
		BTFSS	STATUS,W
		RETURN
		INCF	D2,1
		MOVF	D2,W
		XORLW	.16
		BTFSC	STATUS,Z
		CALL	LIMPIAR_DISPLAY	;LLEGO A 0X0FFF
		RETURN

LIMPIAR_DISPLAY					; PONGO EN 0 TODOS LOS VALORES DEL DIPLAY
		CLRF	D4
		CLRF	D3
		CLRF	D2
		CLRF	D1
		RETURN

LIMPIAR_N1_N2					; PONGO EN CERO LOS VALORES DE LOS NUMEROS 1 Y 2, TAMBIEN SUS FLAGS DE INPUT 
		CLRF	N1_LOADED
		CLRF	N1_D1
		CLRF	N1_D2
		CLRF	N1_D3
		CLRF	N1_D4
		CLRF	N2_LOADED
		CLRF	N2_D1
		CLRF	N2_D2
		CLRF	N2_D3
		CLRF	N2_D4
		RETURN

DEMORA_AR						; DEMORA ANTIREBOTE DE BOTONES
		MOVLW	.255
		MOVWF	CONT_AR
LOOP_AR
		MOVLW	.255
		MOVWF	CONT_AR_2
LOOP_AR_2
		DECFSZ	CONT_AR_2,1
		GOTO	LOOP_AR_2
		DECFSZ	CONT_AR,1
		GOTO	LOOP_AR
		RETURN
			
;CONVERSOR A DISPLAY
;RB1->SEG A
;RB2->SEG B 
;RB3->SEG C
;RB4->SEG D
;RB5->SEG E 
;RB6->SEG F
;RB7->SEG G

TAB_DISPLAY
		ADDWF	PCL,1
		;         GFEDCBA-
		RETLW	b'01111111'			;0
		RETLW	b'00001101'			;1
		RETLW	b'10110111'			;2
		RETLW	b'10011111'			;3
		RETLW	b'11001101'			;4
		RETLW	b'11011011'			;5
		RETLW	b'11111011'			;6
		RETLW	b'00001111'			;7
		RETLW	b'11111111'			;8
		RETLW	b'11001111'			;9
		RETLW	b'11101111'			;A
		RETLW	b'11111001'			;B
		RETLW	b'01110011'			;C
		RETLW	b'10111101'			;D
		RETLW	b'11110011'			;E
		RETLW	b'11100011'			;F
		RETLW	b'10000001'			;-
		RETLW	b'00000001'			;	(DIGITO APAGADO)

RESTAR_1							; HAGO LA RESTA DE A UNO SOBRE EL DIGITO EN EL DISPLAY
		CALL MOV_DIG_AUX
		CALL RESTAR_AUX
		CALL MOV_AUX_DIG
		RETURN

HACER_RESTA					; HAGO LA RESTA N1 - N2
							; 	EN REALIDAD VOY A HACER AUX - AUX2
							; 	ASIGNO EL MAYOR ENTRE N1 Y N2 EN AUX, EL MENOR EN AUX2
							; 	SI LOS TUVE QUE ROTAR LEVANTO EL FLAG DE RESULTADO NEGATIVO
		BCF		RES_NEG,1
		MOVF	N2_D2,W		;
		SUBWF	N1_D2,W		;
		BTFSS	STATUS,C	; c = 0 SI ES NEGATIVA LA RESTA DEBO ROTARLOS
		goto	HR_NEG	;
		BTFSS	STATUS,Z	; c = 1, SI Z=1 ERAN IGUALES VERIFICO SIGUIENTE DIGITO
		GOTO	HR_POS		; 		 SI Z=0 RESTA POSITIVA , PUEDO OPERAR COMO ESTAN
							; VERIFICO SIGUIENTE DIGITO
		MOVF	N2_D3,W		;
		SUBWF	N1_D3,W		;
		BTFSS	STATUS,C	; c = 0 SI ES NEGATIVA LA RESTA DEBO ROTARLOS
		goto	HR_NEG	;
		BTFSS	STATUS,Z	; c = 1, SI Z=1 ERAN IGUALES VERIFICO SIGUIENTE DIGITO
		GOTO	HR_POS		; 		 SI Z=0 RESTA POSITIVA , PUEDO OPERAR COMO ESTAN
							; VERIFICO SIGUIENTE DIGITO

		MOVF	N2_D4,W		;
		SUBWF	N1_D4,W		;
		BTFSS	STATUS,C	; c = 0 SI ES NEGATIVA LA RESTA DEBO ROTALOS
		goto	HR_NEG	;
		BTFSS	STATUS,Z	; c = 1, SI Z=1 ERAN IGUALES VERIFICO SIGUIENTE DIGITO
							; 		 SI Z=0 RESTA POSITIVA , PUEDO OPERAR COMO ESTAN
		
HR_POS						; SI LA RESTA DABA POSITIVA OPERO COMO ESTAN
		CALL	MOV_N1_AUX
		CALL	MOV_N2_AUX2
		GOTO	HR_OPERAR
HR_NEG						; SI LA RESTA DABA NEGATIVA LOS INVIERTO 
		BSF		RES_NEG,1			; SI LOS INVIERTO EL SIGNO DEBERIA SER NEGATIVO	CUANDO LO MUESTRO, ACTIVO FLAG
		CALL	MOV_N2_AUX 
		CALL 	MOV_N1_AUX2

HR_OPERAR					; VOY A HACER LA RESTA EL MAYOR MENOS EL MENOR
							;		AL PRIMERO LE RESTO LA CANTIDAD DE VECES EL DIGITO MENOS SIGNIFICATIVO (D4) DEL SEGUNDO
							;		LUEGO LE RESTO 16 VECES LA CANTIDAD DE VECES EL DIGITO SIGUIENTE (D3) DEL SEGUNDO
							;		LUEGO LE RESTO 256 VECES LA CANTIDAD DE VECES EL DIGITO SIGUIENTE (D2) DEL SEGUNDO
		MOVF	AUX2_D4,W	; APLICO RESTA LA CANT DE VECES DEL DIGITO MENOS SIGNIFICATIVO
		MOVWF	CONT_RES
		BTFSS	STATUS,Z
		GOTO	LOOP_R4
		GOTO	HR_D3
		
LOOP_R4	
		CALL	RESTAR_AUX
		DECFSZ	CONT_RES,1
		GOTO	LOOP_R4	; FIN RESTA MENOS SIGNIFICATIVO

HR_D3	MOVLW	.16		
		MOVWF	CONT_RES2
LOOP_R3A	
		MOVF	AUX2_D3,W		; APLICO RESTA LA CANT DE VECES DEL 2DO DIGITO * 16
		MOVWF	CONT_RES
		BTFSS	STATUS,Z
		GOTO	LOOP_R3B
		GOTO	HR_D2

LOOP_R3B 
		CALL	RESTAR_AUX
		DECFSZ	CONT_RES,1
		GOTO	LOOP_R3B
		DECFSZ	CONT_RES2,1
		GOTO	LOOP_R3A		; FIN 2DO DIGITO

HR_D2	MOVLW	.2				; APLICO RESTA LA CANT DE VECES DEL 3ER DIGITO * 256
		MOVWF	CONT_RES3
LOOP_R2A
		MOVLW	.128		
		MOVWF	CONT_RES2
LOOP_R2B
		MOVF	AUX2_D2,W
		MOVWF	CONT_RES
		BTFSS	STATUS,Z
		GOTO	LOOP_R2C
		GOTO	HR_MOV

LOOP_R2C	
		CALL	RESTAR_AUX
		DECFSZ	CONT_RES,1
		GOTO	LOOP_R2C
		DECFSZ	CONT_RES2,1
		GOTO	LOOP_R2B
		DECFSZ	CONT_RES3,1
		GOTO	LOOP_R2A		; FIN 3ER DIGITO
HR_MOV
		CALL	MOV_AUX_DIG
		BTFSC	RES_NEG,1		; CHECK FLAG DE MENOS
		GOTO	HR_MINUS
		GOTO	HR_FIN
HR_MINUS						; SI LEVANTE EL FLAG DE MENOS TENGO QUE VER DONDE LO UBICO
								;	SI EL RESULTADO ES 1 DIGITO, MENOS EN D3 Y APAGO D2,D1
								;	SI EL RESULTADO ES 2 DIGITOS, MENOS EN D2 Y APAGO D1
		MOVF	D3,W
		IORWF	D2,W
		BTFSC	STATUS,Z
		GOTO	HR_M3
		MOVF	D2,W
		BTFSC	STATUS,Z
		GOTO	HR_M2
		DISMEN	D1
		GOTO	HR_FIN
		
HR_M3	DISMEN	D3
		DISAPA	D2
		DISAPA	D1
		GOTO	HR_FIN
HR_M2	DISMEN	D2
		DISAPA	D1
		GOTO	HR_FIN	
HR_FIN	
		RETURN

MOV_N1_AUX						; MUEVO NUMERO 1 A UN AUX, LA RESTA LA VOY A HACER AUX-AUX2
		MOVF	N1_D4,W
		MOVWF	AUX_D4
		MOVF	N1_D3,W
		MOVWF	AUX_D3
		MOVF	N1_D2,W
		MOVWF	AUX_D2
		MOVF	N1_D1,W
		MOVWF	AUX_D1
		RETURN

MOV_N1_AUX2						; MUEVO NUMERO 1 A UN AUX2, LA RESTA LA VOY A HACER AUX-AUX2
		MOVF	N1_D4,W
		MOVWF	AUX2_D4
		MOVF	N1_D3,W
		MOVWF	AUX2_D3
		MOVF	N1_D2,W
		MOVWF	AUX2_D2
		MOVF	N1_D1,W
		MOVWF	AUX2_D1
		RETURN

MOV_N2_AUX						; MUEVO NUMERO 2 A UN AUX, LA RESTA LA VOY A HACER AUX-AUX2
		MOVF	N2_D4,W
		MOVWF	AUX_D4
		MOVF	N2_D3,W
		MOVWF	AUX_D3
		MOVF	N2_D2,W
		MOVWF	AUX_D2
		MOVF	N2_D1,W
		MOVWF	AUX_D1
		RETURN

MOV_N2_AUX2						; MUEVO NUMERO 2 A UN AUX2, LA RESTA LA VOY A HACER AUX-AUX2
		MOVF	N2_D4,W
		MOVWF	AUX2_D4
		MOVF	N2_D3,W
		MOVWF	AUX2_D3
		MOVF	N2_D2,W
		MOVWF	AUX2_D2
		MOVF	N2_D1,W
		MOVWF	AUX2_D1
		RETURN


MOV_DIG_AUX						; MUEVO DIGITOS DEL DISPLAY A UN AUX
		MOVF	D4,W
		MOVWF	AUX_D4
		MOVF	D3,W
		MOVWF	AUX_D3
		MOVF	D2,W
		MOVWF	AUX_D2
		MOVF	D1,W
		MOVWF	AUX_D1
		RETURN

MOV_AUX_DIG						; RESTAURO DEL AUX A DIGITOS DEL DISPLAY
		MOVF	AUX_D4,W
		MOVWF	D4
		MOVF	AUX_D3,W
		MOVWF	D3
		MOVF	AUX_D2,W
		MOVWF	D2
		MOVF	AUX_D1,W
		MOVWF	D1
		RETURN
			

RESTAR_AUX						; AL AUX LE RESTO UNO 
		MOVF	AUX_D4,W
		BTFSC	STATUS,Z
		goto	R1mepase
		DECF	AUX_D4,F
		goto	R1fin

R1mepase	
		MOVF	AUX_D3,W
		IORWF	AUX_D2,W
		BTFSC	STATUS,Z
		goto	R1fin
		MOVLW	d'15'
		MOVWF	AUX_D4			; 
		MOVF	AUX_D3,W
		BTFSC	STATUS,Z
		goto	R1mepase2
		DECF	AUX_D3,F
		goto	R1fin
R1mepase2	
		MOVLW	d'15'
		MOVWF	AUX_D3			;
		MOVF	AUX_D2,W
		BTFSC	STATUS,Z
		goto	R1mepase3
		DECF	AUX_D2,F
		goto	R1fin
R1mepase3	
		MOVLW	d'15'
		MOVWF	AUX_D2			; 
R1fin	
		RETURN

INI_EEP								; USADA PARA EL PRIMER BOOTEO, PARA ELIMINAR BASURA DE LA EEPROM
		movlW	0x00                       	;leer un dato de eeprom
		bsf		STATUS,RP0                  ;cambiar a banco 1
		movWf	EEADR
		bsf		EECON1,RD
		movf	EEDATA,W
		bcf		STATUS,RP0                   ;cambiar a banco 0
		
		XORLW	H'FF'						; ME FIJO SI LEO BASURA DE EEPROM
		BTFSC	STATUS,Z					; 
		CALL	REINICIAR					; SI LEI BASURA ES EL PRIMER BOOTEO, REINICIO LAS VARIABLES A CERO Y GRABO EEPROM
		
		RETURN


LEERD								; LEO DIGITOS DEL DISPLAY DE LA EEPROM
		movlW	0x03                       ;leer un dato de eeprom
		bsf		STATUS,RP0                   ;cambiar a banco 1
		movWf	EEADR
		bsf		EECON1,RD
		movf	EEDATA,W
		bcf		STATUS,RP0                   ;cambiar a banco 0
		movWf	D4

		movlW	0x02                       ;leer un dato de eeprom
		bsf		STATUS,RP0                   ;cambiar a banco 1
		movWf	EEADR
		bsf		EECON1,RD
		movf	EEDATA,W
		bcf		STATUS,RP0                   ;cambiar a banco 0
		movWf	D3
	
		movlW	0x01                       ;leer un dato de eeprom
		bsf		STATUS,RP0                   ;cambiar a banco 1
		movWf	EEADR
		bsf		EECON1,RD
		movf	EEDATA,W
		bcf		STATUS,RP0                   ;cambiar a banco 0
		movWf	D2

		movlW	0x00                       ;leer un dato de eeprom
		bsf		STATUS,RP0                   ;cambiar a banco 1
		movWf	EEADR
		bsf		EECON1,RD
		movf	EEDATA,W
		bcf		STATUS,RP0                   ;cambiar a banco 0
		movWf	D1
		RETURN

GRABD								; GRABO DIGITOS DEL DISPLAY A LA EEPROM
		movlW	0x03                       ;grabar un dato en eeprom
		bsf		STATUS,RP0                   ;cambiar a banco 1
		bcf		STATUS,RP1
		movWf	EEADR
		bcf		STATUS,RP0                   ;cambiar a banco 0
		movf	D4,W
		bsf		STATUS,RP0                   ;cambiar a banco 1
		movWf	EEDATA
		call 	grabar_eeprom               ;llamada a rutina grabar_eeprom

		movlW	0x02                       ;grabar un dato en eeprom
		bsf		STATUS,RP0                   ;cambiar a banco 1
		bcf		STATUS,RP1
		movWf	EEADR
		bcf		STATUS,RP0                   ;cambiar a banco 0
		movf	D3,W
		bsf		STATUS,RP0                   ;cambiar a banco 1
		movWf	EEDATA
		call 	grabar_eeprom               ;llamada a rutina grabar_eeprom

		movlW	0x01                       ;grabar un dato en eeprom
		bsf		STATUS,RP0                   ;cambiar a banco 1
		bcf		STATUS,RP1
		movWf	EEADR
		bcf		STATUS,RP0                   ;cambiar a banco 0
		movf	D2,W
		bsf		STATUS,RP0                   ;cambiar a banco 1
		movWf	EEDATA
		call 	grabar_eeprom               ;llamada a rutina grabar_eeprom
		
		movlW	0x00                       ;grabar un dato en eeprom
		bsf 	STATUS,RP0                   ;cambiar a banco 1
		bcf		STATUS,RP1
		movWf	EEADR
		bcf 	STATUS,RP0                   ;cambiar a banco 0
		movf	D1,W
		bsf 	STATUS,RP0                   ;cambiar a banco 1
		movWf 	EEDATA
		call 	grabar_eeprom               ;llamada a rutina grabar_eeprom
		RETURN

LEERN1							; LEO EL VALOR DEL NUMERO 1 Y EL FLAG SI FUE CARGADO DE LA EEPROM
		movlW	0x08                       ;leer un dato de eeprom
		bsf		STATUS,RP0                   ;cambiar a banco 1
		movWf	EEADR
		bsf		EECON1,RD
		movf	EEDATA,W
		bcf		STATUS,RP0                   ;cambiar a banco 0
		movWf	N1_D4

		movlW	0x07                       ;leer un dato de eeprom
		bsf		STATUS,RP0                   ;cambiar a banco 1
		movWf	EEADR
		bsf		EECON1,RD
		movf	EEDATA,W
		bcf		STATUS,RP0                   ;cambiar a banco 0
		movWf	N1_D3
	
		movlW	0x06                       ;leer un dato de eeprom
		bsf		STATUS,RP0                   ;cambiar a banco 1
		movWf	EEADR
		bsf		EECON1,RD
		movf	EEDATA,W
		bcf		STATUS,RP0                   ;cambiar a banco 0
		movWf	N1_D2

		movlW	0x05                       ;leer un dato de eeprom
		bsf		STATUS,RP0                   ;cambiar a banco 1
		movWf	EEADR
		bsf		EECON1,RD
		movf	EEDATA,W
		bcf		STATUS,RP0                   ;cambiar a banco 0
		movWf	N1_D1

		movlW	0x04                       ;leer un dato de eeprom
		bsf		STATUS,RP0                   ;cambiar a banco 1
		movWf	EEADR
		bsf		EECON1,RD
		movf	EEDATA,W
		bcf		STATUS,RP0                   ;cambiar a banco 0
		movWf	N1_LOADED
		RETURN


GRABN1								; GRABO EL NUMERO 1 Y EL FLAG SI FUE CARGADO EN LA EEPROM
		movlW	0x08                       ;grabar un dato en eeprom
		bsf		STATUS,RP0                   ;cambiar a banco 1
		bcf		STATUS,RP1
		movWf	EEADR
		bcf		STATUS,RP0                   ;cambiar a banco 0
		movf	N1_D4,W
		bsf		STATUS,RP0                   ;cambiar a banco 1
		movWf	EEDATA
		call 	grabar_eeprom               ;llamada a rutina grabar_eeprom

		movlW	0x07                       ;grabar un dato en eeprom
		bsf		STATUS,RP0                   ;cambiar a banco 1
		bcf		STATUS,RP1
		movWf	EEADR
		bcf		STATUS,RP0                   ;cambiar a banco 0
		movf	N1_D3,W
		bsf		STATUS,RP0                   ;cambiar a banco 1
		movWf	EEDATA
		call 	grabar_eeprom               ;llamada a rutina grabar_eeprom

		movlW	0x06                       ;grabar un dato en eeprom
		bsf		STATUS,RP0                   ;cambiar a banco 1
		bcf		STATUS,RP1
		movWf	EEADR
		bcf		STATUS,RP0                   ;cambiar a banco 0
		movf	N1_D2,W
		bsf		STATUS,RP0                   ;cambiar a banco 1
		movWf	EEDATA
		call 	grabar_eeprom               ;llamada a rutina grabar_eeprom
		
		movlW	0x05                      ;grabar un dato en eeprom
		bsf 	STATUS,RP0                   ;cambiar a banco 1
		bcf		STATUS,RP1
		movWf	EEADR
		bcf 	STATUS,RP0                   ;cambiar a banco 0
		movf	N1_D1,W
		bsf 	STATUS,RP0                   ;cambiar a banco 1
		movWf 	EEDATA
		call 	grabar_eeprom               ;llamada a rutina grabar_eeprom

		movlW	0x04                       ;grabar un dato en eeprom
		bsf 	STATUS,RP0                   ;cambiar a banco 1
		bcf		STATUS,RP1
		movWf	EEADR
		bcf 	STATUS,RP0                   ;cambiar a banco 0
		movf	N1_LOADED,W
		bsf 	STATUS,RP0                   ;cambiar a banco 1
		movWf 	EEDATA
		call 	grabar_eeprom               ;llamada a rutina grabar_eeprom
		RETURN


LEERN2							; LEO EL VALOR DEL NUMERO 2 Y EL FLAG SI FUE CARGADO DE LA EEPROM
		movlW	0x0D                      ;leer un dato de eeprom
		bsf		STATUS,RP0                   ;cambiar a banco 1
		movWf	EEADR
		bsf		EECON1,RD
		movf	EEDATA,W
		bcf		STATUS,RP0                   ;cambiar a banco 0
		movWf	N2_D4

		movlW	0x0C                       ;leer un dato de eeprom
		bsf		STATUS,RP0                   ;cambiar a banco 1
		movWf	EEADR
		bsf		EECON1,RD
		movf	EEDATA,W
		bcf		STATUS,RP0                   ;cambiar a banco 0
		movWf	N2_D3
	
		movlW	0x0B                       ;leer un dato de eeprom
		bsf		STATUS,RP0                   ;cambiar a banco 1
		movWf	EEADR
		bsf		EECON1,RD
		movf	EEDATA,W
		bcf		STATUS,RP0                   ;cambiar a banco 0
		movWf	N2_D2

		movlW	0x0A                       ;leer un dato de eeprom
		bsf		STATUS,RP0                   ;cambiar a banco 1
		movWf	EEADR
		bsf		EECON1,RD
		movf	EEDATA,W
		bcf		STATUS,RP0                   ;cambiar a banco 0
		movWf	N2_D1

		movlW	0x09                       ;leer un dato de eeprom
		bsf		STATUS,RP0                   ;cambiar a banco 1
		movWf	EEADR
		bsf		EECON1,RD
		movf	EEDATA,W
		bcf		STATUS,RP0                   ;cambiar a banco 0
		movWf	N2_LOADED
		RETURN


GRABN2								; GRABO EL NUMERO 2 Y EL FLAG DE SI FUE INGRESADO EN EEPROM
		movlW	0x0D                       ;grabar un dato en eeprom
		bsf		STATUS,RP0                   ;cambiar a banco 1
		bcf		STATUS,RP1
		movWf	EEADR
		bcf		STATUS,RP0                   ;cambiar a banco 0
		movf	N2_D4,W
		bsf		STATUS,RP0                   ;cambiar a banco 1
		movWf	EEDATA
		call 	grabar_eeprom               ;llamada a rutina grabar_eeprom

		movlW	0x0C                       ;grabar un dato en eeprom
		bsf		STATUS,RP0                   ;cambiar a banco 1
		bcf		STATUS,RP1
		movWf	EEADR
		bcf		STATUS,RP0                   ;cambiar a banco 0
		movf	N2_D3,W
		bsf		STATUS,RP0                   ;cambiar a banco 1
		movWf	EEDATA
		call 	grabar_eeprom               ;llamada a rutina grabar_eeprom

		movlW	0x0B                       ;grabar un dato en eeprom
		bsf		STATUS,RP0                   ;cambiar a banco 1
		bcf		STATUS,RP1
		movWf	EEADR
		bcf		STATUS,RP0                   ;cambiar a banco 0
		movf	N2_D2,W
		bsf		STATUS,RP0                   ;cambiar a banco 1
		movWf	EEDATA
		call 	grabar_eeprom               ;llamada a rutina grabar_eeprom
		
		movlW	0x0A                      ;grabar un dato en eeprom
		bsf 	STATUS,RP0                   ;cambiar a banco 1
		bcf		STATUS,RP1
		movWf	EEADR
		bcf 	STATUS,RP0                   ;cambiar a banco 0
		movf	N2_D1,W
		bsf 	STATUS,RP0                   ;cambiar a banco 1
		movWf 	EEDATA
		call 	grabar_eeprom               ;llamada a rutina grabar_eeprom

		movlW	0x09                       ;grabar un dato en eeprom
		bsf 	STATUS,RP0                   ;cambiar a banco 1
		bcf		STATUS,RP1
		movWf	EEADR
		bcf 	STATUS,RP0                   ;cambiar a banco 0
		movf	N2_LOADED,W
		bsf 	STATUS,RP0                   ;cambiar a banco 1
		movWf 	EEDATA
		call 	grabar_eeprom               ;llamada a rutina grabar_eeprom
		return

LEERR								; LEO EL FLAG DE RESULTADO NEGATIVO EN LA EEPROM
		movlW	0x0E                      ;leer un dato de eeprom
		bsf		STATUS,RP0                   ;cambiar a banco 1
		movWf	EEADR
		bsf		EECON1,RD
		movf	EEDATA,W
		bcf		STATUS,RP0                   ;cambiar a banco 0
		movWf	RES_NEG
		RETURN

GRABR								; GRABO EL FLAG DE RESULTADO NEGATIVO EN LA EEPROM
		movlW	0x0E                       ;grabar un dato en eeprom
		bsf		STATUS,RP0                   ;cambiar a banco 1
		bcf		STATUS,RP1
		movWf	EEADR
		bcf		STATUS,RP0                   ;cambiar a banco 0
		movf	RES_NEG,W
		bsf		STATUS,RP0                   ;cambiar a banco 1
		movWf	EEDATA
		call	grabar_eeprom				; llamada a rutina grabar_eeprom
		RETURN

grabar_eeprom						; RUTINA DE GRABADO EN EEPROM
		;escribir el dato en la eeprom
		bsf		STATUS,RP0                   ;cambiar a banco 1
		bcf		STATUS,RP1
 		BSF		EECON1,WREN			;HABILITA ESCRITURA EN EEPROM
		BCF		INTCON,GIE			; DESHABILITA INTERRUPCIONES 
		MOVLW	0x55				;PREPARA SECUENCIA DE SEGURIDAD
		MOVWF	EECON2				;ESCRIBE PRIMER DATO DE SECUENCIA
		MOVLW	0xAA				;SEGUNDO DATO
		MOVWF	EECON2				;ESCRIBE SEGUNDO DATO DE SECUENCIA
		BSF		EECON1,WR			;INICIA CICLO DE ESCRITURA
EW      BTFSC	EECON1,WR			;MALLA PARA ESPERAR AL FINAL DEL CICLO
		GOTO	EW					;SI WR=1, CICLO DE ESCRITURA AUN NO TERMINA
		nop
		bcf		EECON1,EEIF
		BCF		EECON1,WREN			;DESHABILITA ESCRITURA
		BSF		INTCON,GIE			;HABILITA INTERRUPCIONES 
		bcf		STATUS,RP0                   ;cambiar a banco 0
		bcf		STATUS,RP1
		RETURN

;------------------------------------------------------------
;                  DATOS EN MEMORIA EEPROM
;------------------------------------------------------------
;   org  0x2100
;   data   H'FF'
;   data   H'FF'
;   data   H'FF'
;   data   H'FF'

		END