STACK SEGMENT PARA STACK
    DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'

    TIME_AUX DB 0       ;var for time
    BLOCK_SIZE DB 08h   ;size of one block
    PEBBLE_POS DW 00h   ;position of pebble
    SNAKE_LENGTH DW 0Ah ;length of snake
    SNAKE_ARRAY DW 1001 DUP(0000h)
    SNAKE_HEAD_X DW 00h
    SNAKE_HEAD_Y DW 00h
    HEAD_DIRECTION DB 0 ;0up,1down;2left;3right

DATA ENDS

CODE SEGMENT PARA 'CODE'

    MAIN PROC FAR
    ASSUME CS:CODE,DS:DATA,SS:STACK
    PUSH DS         ;push to stack DS segment
    SUB AX,AX       ;clean AX register
    PUSH AX
    MOV AX,DATA     ;save on AX register the contents of DATA segment
    MOV DS,AX       ;save on the DS segments the contents of AX
    POP AX          ;release the top item of the stack to the AX register
    POP AX         ;release the top item of the stack to the AX register
        


        CALL INIT

        CALL CLEAR_SCREEN
        
        CHECK_TIME:
            
            MOV AH,2Ch  ;get system time
            INT 21h     ;CH = hour, CL = minutes, DH = secnod DL = 1/100 sec
            
            CMP DL,TIME_AUX
            JE CHECK_TIME
            MOV TIME_AUX,DL
            
            CALL KEYBOARD_INPUT
            
            CALL MOVE_SNAKE
            CALL PEBBLE_CHECK
            CALL SELF_COLLISION_CHECK
            
            CALL CLEAR_SCREEN
            CALL DRAW_PEBBLE
            CALL DRAW_SNAKE
            
            
            JMP CHECK_TIME

        RET
    MAIN ENDP
    
    INIT PROC NEAR
        MOV DI,00h
        CALL GENERATE_PEBBLE
        MOV AX,PEBBLE_POS
        MOV SNAKE_ARRAY[DI],AX
        
        CALL GENERATE_PEBBLE
        
        RET
    INIT ENDP
    
    CLEAR_SCREEN PROC NEAR
        MOV AH,00h  ;video mode
        MOV AL,0Dh  ;320x200
        INT 10h     ;video mode interrupt
        RET
    CLEAR_SCREEN ENDP
    
    GENERATE_PEBBLE PROC NEAR
        ;rand val init
        XOR BX,BX
        MOV AH,2Ch  ;get system time
        INT 21h     ;CH = hour, CL = minutes, DH = secnod DL = 1/100 sec
        XOR CX,DX
        XOR DX,DX
        
        ;x position
        MOV AX,CX
        MOV BX,0028h
        DIV BX
        MOV DH,DL
        PUSH DX
        
        ;y position
        MOV AX,CX
        XOR DX,DX
        MOV BX,0019h
        DIV BX
        POP BX
        MOV BL,DL
        
        MOV PEBBLE_POS,BX
        
        RET
    GENERATE_PEBBLE ENDP
    
    
    PEBBLE_CHECK PROC NEAR
        XOR AX,AX
        XOR BX,BX
        MOV AX,SNAKE_ARRAY[0]
        MOV BX,PEBBLE_POS
        
        CMP AX,BX
        JNE NO_PEBBLE_MATCH
        MOV AX,SNAKE_LENGTH
        INC AX
        MOV SNAKE_LENGTH,AX
        CALL GENERATE_PEBBLE
        
        NO_PEBBLE_MATCH:
        RET
    PEBBLE_CHECK ENDP
    
    SELF_COLLISION_CHECK PROC NEAR
        
        MOV DI,SNAKE_LENGTH
        CMP DI,01h
        JE NO_CHECK_NEEDED
        
        MOV BX,SNAKE_ARRAY[0]
        XOR AX,AX
        MOV AL,2
        
        MUL DI
        MOV DI,AX
        
        
        
        COLLISION_CHECK_LOOP:
           SUB DI,2
           MOV AX,SNAKE_ARRAY[DI]
           CMP AX,BX
           JNE NO_COLLISION
           CALL EXIT_NOW
           
           NO_COLLISION:
           CMP DI,02h
           JG COLLISION_CHECK_LOOP
        
        NO_CHECK_NEEDED:
        RET
    SELF_COLLISION_CHECK ENDP
    
    MOVE_SNAKE PROC NEAR
        ;copy each arr[i] to arr[i+1] for snake length
        ;move snake head in direction
        
        XOR AX,AX
        MOV AL,2
        MOV DI,SNAKE_LENGTH
        MUL DI
        MOV DI,AX
        
        ;01 23 45
        COPY_SNAKE:
            SUB DI,2
            MOV AX,SNAKE_ARRAY[DI]
            ADD DI, 2
            MOV SNAKE_ARRAY[DI],AX
            SUB DI,2
            CMP DI,00h
            JNE COPY_SNAKE
        
        
        MOV DX,SNAKE_ARRAY[DI]
        CMP HEAD_DIRECTION,00h
        JE  MOVE_UP
        CMP HEAD_DIRECTION,01h
        JE  MOVE_DOWN
        CMP HEAD_DIRECTION,02h
        JE  MOVE_LEFT
        CMP HEAD_DIRECTION,03h
        JE  MOVE_RIGHT
        
        MOVE_UP:
            DEC DL
            CMP DL,00h
            JGE MOVE_DONE
            MOV DL,19h
            JMP MOVE_DONE
        MOVE_DOWN:
            INC DL
            CMP DL,19h
            JLE MOVE_DONE
            MOV DL,00h
            JMP MOVE_DONE
        MOVE_LEFT:
            DEC DH
            CMP DH,00h
            JGE MOVE_DONE
            MOV DH,28h
            JMP MOVE_DONE
        MOVE_RIGHT:
            INC DH
            CMP DH,28h
            JLE MOVE_DONE
            MOV DH,00h
            JMP MOVE_DONE
        
        MOVE_DONE:
            MOV SNAKE_ARRAY[DI],DX
            
        RET
    MOVE_SNAKE ENDP
    
    DRAW_PEBBLE PROC NEAR
    
       
        
        ;;x pos
        MOV AX,PEBBLE_POS
        MOV AL,AH                   ;move x coord to al
        XOR AH,AH                   ;clear ah
        MOV CL,BLOCK_SIZE            
        MUL CL                      ;ax = al*cl
        MOV CX,AX                   ;got x coord position
        MOV SNAKE_HEAD_X,CX
        
        ;y coord
        MOV AX,PEBBLE_POS      
        XOR AH,AH                   ;clear ah
        MOV DL,BLOCK_SIZE            
        MUL DL                      ;ax = al*dl
        MOV DX,AX                   ;got y coord position
        MOV SNAKE_HEAD_Y,DX
        
        CALL DRAW_ONE_BLOCK_HORIZONTAL
        
        RET
    DRAW_PEBBLE ENDP
    
    DRAW_SNAKE PROC NEAR
        
        XOR AX,AX
        MOV AL,2
        MOV DI,SNAKE_LENGTH
        MUL DI
        MOV DI,AX
        DRAW_ONE_BLOCK:
            SUB DI,2
            
            ;x coord
            MOV AX,SNAKE_ARRAY[DI]      ;copy whole snake blck
            MOV AL,AH                   ;move x coord to al
            XOR AH,AH                   ;clear ah
            MOV CL,BLOCK_SIZE            
            MUL CL                      ;ax = al*cl
            MOV CX,AX                   ;got x coord position
            MOV SNAKE_HEAD_X,CX
            
            ;y coord
            MOV AX,SNAKE_ARRAY[DI]      ;copy whole snake blck
            XOR AH,AH                   ;clear ah
            MOV DL,BLOCK_SIZE            
            MUL DL                      ;ax = al*dl
            MOV DX,AX                   ;got y coord position
            MOV SNAKE_HEAD_Y,DX
            
            CALL DRAW_ONE_BLOCK_HORIZONTAL
            
            CMP DI,00h
            JNE DRAW_ONE_BLOCK
        
        RET
    DRAW_SNAKE ENDP
    
    DRAW_ONE_BLOCK_HORIZONTAL PROC NEAR
    
        DOBH_LOOP:
            MOV AH,0Ch  ;draw pixel
            MOV AL,0Fh  ;color
            MOV BH,00h  ;page num
            INT 10h
            
            INC CX      ;inc pixel x by 1
            ;compare if we have enough pixels done for row
            ;need H of SNAKE_ARRAY[DI]
            ;multiply by block size, add block size
            ;compare to current pixel position
            
            MOV AX,CX
            SUB AX,SNAKE_HEAD_X
            CMP AL,BLOCK_SIZE
            JNG DOBH_LOOP
            
            ;line finished: reset position
            MOV CX,SNAKE_HEAD_X

            ;new line
            INC DX
            
            ;compare if we have enough rows
            MOV AX,DX
            SUB AX,SNAKE_HEAD_Y
            CMP AL,BLOCK_SIZE
            JNG DOBH_LOOP
        RET
    DRAW_ONE_BLOCK_HORIZONTAL ENDP
    
    KEYBOARD_INPUT PROC NEAR
        ;check if any key has been pressed if not exit
        MOV AH,01h
        INT 16h
        JZ KEYBOARD_END
        ;check which key is being pressed
        ;TODO CHECK IF YOU CAN READ FROM 01h
        MOV AH,00h
        INT 16h
        
        ;exit on escape
        CMP AH,01h
        JNE DONT_EXIT
        CALL EXIT_NOW
        
        DONT_EXIT:
        ;if it is 'arrow_up' move up
        CMP AH,48h
        JE MOVE_HEAD_UP

        ;if it is 'arrow_down move down
        CMP AH,50h
        JE MOVE_HEAD_DOWN
        
        CMP AH,4Bh
        JE MOVE_HEAD_LEFT
        
        CMP AH,4Dh
        JE MOVE_HEAD_RIGHT
        
        JMP KEYBOARD_END
        
        MOVE_HEAD_UP:
            CMP HEAD_DIRECTION,01h
            JE KEYBOARD_END
            MOV HEAD_DIRECTION,00h
            JMP KEYBOARD_END
        MOVE_HEAD_DOWN:
            CMP HEAD_DIRECTION,00h
            JE KEYBOARD_END
            MOV HEAD_DIRECTION,01h
            JMP KEYBOARD_END
        MOVE_HEAD_LEFT:
            CMP HEAD_DIRECTION,03h
            JE KEYBOARD_END
            MOV HEAD_DIRECTION,02h
            JMP KEYBOARD_END
        MOVE_HEAD_RIGHT:
            CMP HEAD_DIRECTION,02h
            JE KEYBOARD_END
            MOV HEAD_DIRECTION,03h
            JMP KEYBOARD_END
        
        KEYBOARD_END:
        RET
    KEYBOARD_INPUT ENDP
    
    EXIT_NOW PROC NEAR
        MOV AH,4Ch
        INT 21h
    EXIT_NOW ENDP

CODE ENDS
END