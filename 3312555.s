;*******************************************************************************
;@file				 Main.s
;@project		     Microprocessor Systems Term Project
;@29.01.2021
;
;@PROJECT GROUP
;@groupno : 38
;@member1 : Ali Osman Kiliç    150170716
;@member2 : Emine Dari         150180034
;@member3 : Fatima Rahimova    150180905
;@member4 : Irem Öztürk        150170100
;@member5 : Yusuf Alptigin Gün 150180043
;*******************************************************************************
;*******************************************************************************
;@section 		INPUT_DATASET
;*******************************************************************************

;@brief 	This data will be used for insertion and deletion operation.
;@note		The input dataset will be changed at the grading. 
;			Therefore, you shouldn't use the constant number size for this dataset in your code. 
				AREA     IN_DATA_AREA, DATA, READONLY
IN_DATA			DCD		0x10, 0x20, 0x15, 0x65, 0x25, 0x01, 0x01, 0x12, 0x65, 0x25, 0x85, 0x46, 0x10, 0x00
END_IN_DATA

;@brief 	This data contains operation flags of input dataset. 
;@note		0 -> Deletion operation, 1 -> Insertion 
				AREA     IN_DATA_FLAG_AREA, DATA, READONLY
IN_DATA_FLAG	DCD		0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00, 0x02
END_IN_DATA_FLAG


;*******************************************************************************
;@endsection 	INPUT_DATASET
;*******************************************************************************

;*******************************************************************************
;@section 		DATA_DECLARATION
;*******************************************************************************

;@brief 	This part will be used for constant numbers definition.
NUMBER_OF_AT	EQU		20									; Number of Allocation Table
AT_SIZE			EQU		NUMBER_OF_AT*4						; Allocation Table Size


DATA_AREA_SIZE	EQU		AT_SIZE*32*2						; Allocable data area
															; Each allocation table has 32 Cell
															; Each Cell Has 2 word (Value + Address)
															; Each word has 4 byte
ARRAY_SIZE		EQU		AT_SIZE*32							; Allocable data area
															; Each allocation table has 32 Cell
															; Each Cell Has 1 word (Value)
															; Each word has 4 byte
LOG_ARRAY_SIZE	EQU     AT_SIZE*32*3						; Log Array Size
															; Each log contains 3 word
															; 16 bit for index
															; 8 bit for error_code
															; 8 bit for operation
															; 32 bit for data
															; 32 bit for timestamp in us

;//-------- <<< USER CODE BEGIN Constant Numbers Definitions >>> ----------------------															
							


;//-------- <<< USER CODE END Constant Numbers Definitions >>> ------------------------	

;*******************************************************************************
;@brief 	This area will be used for global variables.
				AREA     GLOBAL_VARIABLES, DATA, READWRITE		
				ALIGN	
TICK_COUNT		SPACE	 4									; Allocate #4 byte area to store tick count of the system tick timer.
FIRST_ELEMENT  	SPACE    4									; Allocate #4 byte area to store the first element pointer of the linked list.
INDEX_INPUT_DS  SPACE    4									; Allocate #4 byte area to store the index of input dataset.
INDEX_ERROR_LOG SPACE	 4									; Allocate #4 byte aret to store the index of the error log array.
PROGRAM_STATUS  SPACE    4									; Allocate #4 byte to store program status.
															; 0-> Program started, 1->Timer started, 2-> All data operation finished.
;//-------- <<< USER CODE BEGIN Global Variables >>> ----------------------															
							


;//-------- <<< USER CODE END Global Variables >>> ------------------------															

;*******************************************************************************

;@brief 	This area will be used for the allocation table
				AREA     ALLOCATION_TABLE, DATA, READWRITE		
				ALIGN	
__AT_Start
AT_MEM       	SPACE    AT_SIZE							; Allocate #AT_SIZE byte area from memory.
__AT_END

;@brief 	This area will be used for the linked list.
				AREA     DATA_AREA, DATA, READWRITE		
				ALIGN	
__DATA_Start
DATA_MEM        SPACE    DATA_AREA_SIZE						; Allocate #DATA_AREA_SIZE byte area from memory.
__DATA_END

;@brief 	This area will be used for the array. 
;			Array will be used at the end of the program to transform linked list to array.
				AREA     ARRAY_AREA, DATA, READWRITE		
				ALIGN	
__ARRAY_Start
ARRAY_MEM       SPACE    ARRAY_SIZE						; Allocate #ARRAY_SIZE byte area from memory.
__ARRAY_END

;@brief 	This area will be used for the error log array. 
				AREA     ARRAY_AREA, DATA, READWRITE		
				ALIGN	
__LOG_Start
LOG_MEM       	SPACE    LOG_ARRAY_SIZE						; Allocate #DATA_AREA_SIZE byte area from memory.
__LOG_END

;//-------- <<< USER CODE BEGIN Data Allocation >>> ----------------------															
							


;//-------- <<< USER CODE END Data Allocation >>> ------------------------															

;*******************************************************************************
;@endsection 	DATA_DECLARATION
;*******************************************************************************

;*******************************************************************************
;@section 		MAIN_FUNCTION
;*******************************************************************************

			
;@brief 	This area contains project codes. 
;@note		You shouldn't change the main function. 				
				AREA MAINFUNCTION, CODE, READONLY
				ENTRY
				THUMB
				ALIGN 
__main			FUNCTION
				EXPORT __main
				BL	Clear_Alloc					; Call Clear Allocation Function.
				BL  Clear_ErrorLogs				; Call Clear ErrorLogs Function.
				BL	Init_GlobVars				; Call Initiate Global Variable Function.
				BL	SysTick_Init				; Call Initialize System Tick Timer Function.
				LDR R0, =PROGRAM_STATUS			; Load Program Status Variable Addresses.
LOOP			LDR R1, [R0]					; Load Program Status Variable.
				CMP	R1, #2						; Check If Program finished.
				BNE LOOP						; Go to loop If program do not finish.
STOP			B	STOP						; Infinite loop.
				
				ENDFUNC
			
;*******************************************************************************
;@endsection 		MAIN_FUNCTION
;*******************************************************************************				

;*******************************************************************************
;@section 			USER_FUNCTIONS
;*******************************************************************************



;@brief 	This function will be used for System Tick Handler
SysTick_Handler	FUNCTION			
;//-------- <<< USER CODE BEGIN System Tick Handler >>> ----------------------															
				EXPORT SysTick_Handler			;export the overidden function 
				PUSH {LR}						;push link register
				LDR	R5,=TICK_COUNT				;load tick count address
				LDR R1,[R5]						;get tick count value
				PUSH {R1}						;push the tick count value, later used as data index
				
				LSLS R1,R1,#2					;multiply tick count by 4, because data is 1 word

				LDR R2,=IN_DATA					;get start address of data
				LDR R6,=END_IN_DATA				;get end address of data
				ADDS R7,R2,R1					;add the tick_count*4 to start address
				CMP R7,R6						;compare the results to see if all data is processed
				BEQ	SysTick_Stop				;stop the timer if we have reached end of data
				
				
				LDR R0,[R2,R1]					;get the data at index	
				PUSH {R0}						;push data at index
					
				
				LDR R2,=IN_DATA_FLAG			;load operation flags' address
				LDR R4,[R2,R1]					;get the flag at index	
				
				PUSH {R4}						;push operation code
				CMP R4,#0						;compare the code with 0
				BEQ remove						;if equal, branch to remove label to execute operation
				CMP R4,#1						;compare the code with 1
				BEQ insert						;if equal, branch to insert label to execute operation
				CMP R4,#2						;compare the code with 2
				BEQ transform					;if equal, branch to transform label to execute operation
				MOVS R0,#6 						;operation not found
				B write_error					;branch to write an error
						

remove			BL Remove						;branch to actual Remove function
				B write_error					;branch to write error after the function call
				
insert			BL Insert						;branch to actual Insert function
				B write_error					;branch to write error after the function call
				
transform		BL LinkedList2Arr				;branch to actual LinkedList2Arr function
				B write_error					;branch to write error after the function call

write_error		CMP R0,#0						;check whether R0 contains success code
				MOVS R1,R0						;set error code
												;pop the values according to error log parameters

				POP {R2}						;set operation code to R2
				POP {R3}						;set data to R3
				POP {R0}						;set index to R0
				BEQ increment_tick				;if the results of comparison is zero, no error occured just branch to increment tick count
				BL WriteErrorLog				;branch to WriteErrorLog function to write these values to memory
								

increment_tick	LDR	R5,=TICK_COUNT				;load tick count address
				LDR R1,[R5]						;get tick count value
				ADDS R1,R1,#1					;increment tick count
				STR R1,[R5]						;store the incremented value
				LDR R1,=INDEX_INPUT_DS			;get address of index variable
				LDR R2,[R1]						;get index value
				ADDS R2,R2,#1					;increment input index
				STR R2,[R1]						;store index
				POP {PC}						;pop LR to PC
				
;//-------- <<< USER CODE END System Tick Handler >>> ------------------------				
				ENDFUNC

;*******************************************************************************				

;@brief 	This function will be used to initiate System Tick Handler
SysTick_Init	FUNCTION			
;//-------- <<< USER CODE BEGIN System Tick Timer Initialize >>> ----------------------															
		LDR	R0,=0xE000E010 						;load CVR address
		LDR R1,=17567							;Clock period* (Reload value + 1) = Interrupt period, set reload value to R1
		STR R1,[R0,#4]							;store the reload value to RVR
		MOVS R1,#0								;move 0 to R1 to initialize the variables as zero
		STR R1,[R0,#8]							;clear CVR
		MOVS R1,#7								;set enable, clock and interrupt flags
		STR R1,[R0]								;store the values
		
		LDR r0,=PROGRAM_STATUS					;get program status variable's address
		MOVS r1,#1								; move 1 to r1 
		STR r1,[r0]								;start the timer by setting program status to zero
		
		BX LR									;branch back to where function was called
				
				
;//-------- <<< USER CODE END System Tick Timer Initialize >>> ------------------------				
				ENDFUNC

;*******************************************************************************				

;@brief 	This function will be used to stop the System Tick Timer
SysTick_Stop	FUNCTION			
;//-------- <<< USER CODE BEGIN System Tick Timer Stop >>> ----------------------	
			
			LDR	R0,=0xE000E010 					;load CVR address
			MOVS R1,#0							;move 0 to R1 to use when resetting
			STR R1,[R0]							;clear enable, tick int
			STR R1,[R0,#8]						;clear count flag	
			
			LDR r0,=PROGRAM_STATUS				;get program status variable's address
			MOVS r1,#2							;stop the timer
			STR r1,[r0]							;store the updated value
			BL LOOP								;branch to LOOP label to stop the program



;//-------- <<< USER CODE END System Tick Timer Stop >>> ------------------------				
				ENDFUNC

;*******************************************************************************				

;@brief 	This function will be used to clear allocation table
Clear_Alloc		FUNCTION			
;//-------- <<< USER CODE BEGIN Clear Allocation Table Function >>> ----------------------															
		LDR R4,=AT_MEM							;load allocation table's address
		LDR	R5,=AT_SIZE							;load allocation table's size
		ADDS R5,R5,R4							;add the size to beginning to get the end address
loop	CMP R4,R5								;compare the size with the end address
		BEQ	out									;whole table is cleared, go to out label
		MOVS R6,#0								;move 0 to r6 to use when clearing
		STR R6,[R4]								;store 0 to current index in the loop
		ADDS R4,R4,#4							;go to next address
		B loop									;branch to loop
		
out 	BX LR									;branch back to where function was called
	
;//-------- <<< USER CODE END Clear Allocation Table Function >>> ------------------------				
				ENDFUNC
				
;*******************************************************************************		

;@brief 	This function will be used to clear error log array
Clear_ErrorLogs	FUNCTION			
;//-------- <<< USER CODE BEGIN Clear Error Logs Function >>> ----------------------															
			LDR R4,=LOG_MEM						;get the adress of error log in memory
			LDR	R5,=LOG_ARRAY_SIZE				;get the size of error log array
			ADDS R5,R5,R4						;set r5 as end adress of memory
logloop		CMP R4,R5							;compare memory place to end adress
			BEQ	log_out							;if equal go to log_out branch
			MOVS R6,#0							;get clear value to r6
			STR R6,[R4]							;store clear value to adress
			ADDS R4,R4,#4						;go to next word
			B logloop							;continue to logloop
			
log_out 	BX LR								;branch back to where function was called
		
;//-------- <<< USER CODE END Clear Error Logs Function >>> ------------------------				
				ENDFUNC
				
;*******************************************************************************

;@brief 	This function will be used to initialize global variables
Init_GlobVars	FUNCTION			
;//-------- <<< USER CODE BEGIN Initialize Global Variables >>> ----------------------															
	LDR r0,=TICK_COUNT							;get adress of TICK_COUNT
	MOVS r1,#0									;get clear value
	STR r1,[r0]									;store clear value to TICK_COUNT
	
	LDR r0,=PROGRAM_STATUS						;get adress of PROGRAM_STATUS
	MOVS r1,#0									;get clear value
	STR r1,[r0]									;store clear value to PROGRAM_STATUS
				
	LDR r0,=FIRST_ELEMENT						;get adress of FIRST_ELEMENT
	MOVS r1,#0									;get clear value
	STR r1,[r0]									;store clear value to FIRST_ELEMENT

	LDR r0,=INDEX_INPUT_DS						;get adress of INDEX_INPUT_DS
	MOVS r1,#0									;get clear value
	STR r1,[r0]									;store clear value to INDEX_INPUT_DS

	LDR r0,=INDEX_ERROR_LOG						;get adress of INDEX_ERROR_LOG
	MOVS r1,#0									;get clear value
	STR r1,[r0]									;store clear value to INDEX_ERROR_LOG
	BX LR										;branch to main function
				
;//-------- <<< USER CODE END Initialize Global Variables >>> ------------------------				
				ENDFUNC
				
;*******************************************************************************	

;@brief 	This function will be used to allocate the new cell 
;			from the memory using the allocation table.

;@return 	R0 <- The allocated area address
Malloc			FUNCTION			
;//-------- <<< USER CODE BEGIN System Tick Handler >>> ----------------------	

			LDR R4,=AT_MEM						;get beginning adress of allocation table
			LDR	R5,=AT_SIZE						;get allocation table size
			ADDS R5,R5,R4						;set r5 to end of allocation table
			SUBS R4,R4,#4						;go previous word to synch with line loop logic
line		ADDS R4,R4,#4						;go next line
			CMP R4,R5							;check if reached end of allocation table 
			BEQ list_is_full					;branch to list_is_full branch if reached to end of allocation table
			MOVS R7,#0							;set allocation table index as 0
				
			LDR R0,[R4]							;load value of allocation table line
			LDR R3,[R4]							;load value of allocation table line
			

bit_loop	CMP R7,#31							;compare r7 value with end index of allocation table
			BGT line							;branch to line if value greater than 31 
			MOVS R2, #1							;get comparative value to r2
			MOVS R0,R3							;get value of allocation table line
			ANDS R0,R0,R2						;and with comparative value to check whether it is available
			CMP R0,#0							;compare with zero for checking
			BEQ malloc_out						;branch if bit is available
			LSRS R3,R3,#1						;shift one bit if its not available
			ADDS R7,R7,#1						;increase bit loop index
			
			B bit_loop
			


malloc_out	MOVS R5,#1							;get value of 1 for adding operation
			LSLS R5,R5,R7						;shift value to change that bit
			LDR R6,[R4]							;load allocation table line value
			ADDS R6,R6,R5    					;add bit to table value
			STR R6,[R4]							;store value in memory

			LDR R3,=AT_MEM						;get beginning adress of allocation table memory
			SUBS R4,R4,R3						;substitute allocation table address from beginning
			LSRS R4,#2							;divide to four to get index of table line
			LSLS R4,#5							;multiply with 32
			
			MOVS R0,R7							;set r0 as index value
			ADDS R0,R0,R4						;add each table line to r0 to get exact index
			
			
			LSLS R0,#3							;multiply that index with 8 for each memory node
			LDR R1,=DATA_MEM					;load beginning adress of data memory
			ADDS R0,R1,R0						;go freed memory in r0
			
			BX LR								;return to insert

list_is_full	MOVS R0,#1						;set error flag, list is full
				BX LR							;return to insert
	

;//-------- <<< USER CODE END System Tick Handler >>> ------------------------				
				ENDFUNC
				
;*******************************************************************************				

;@brief 	This function will be used for deallocate the existing area
;@param		R0 <- Address to deallocate
Free			FUNCTION			
;//-------- <<< USER CODE BEGIN Free Function >>> ----------------------

			LDR R1,=DATA_MEM					;get beginning adress of data memory
			SUBS R1,R0,R1						;load r1 substituted value
			LSRS R1,#3							;divide by 8 to get index
			MOVS R2,#0							;load find line loop index value to r2
			
find_line	CMP R1,#32 							;compare if r1 value bigger than a table line can hold
			BLT clear_bit						;branch if its less than a table line can hold
			SUBS R1,R1,#32						;go back previous table line if bigger
			ADDS R2,R2,#1						;increase loop index value
			B find_line							;branch beginning of the loop

			

clear_bit	LDR R3,=AT_MEM						;get beginning adress of at table in memory
			LSLS R2,R2,#2						;multiply line index value by four
			ADDS R2,R2,R3						;add that value to beginning to get exact adress of that line in memory
			LDR R4,[R2]							;get value at that line
			MOVS R5,#1							;load 1 for subtraction operation (bit clearing)
			LSLS R5,R5,R1						;get value to subtract by shifting
			SUBS R4,R4,R5						;subtract that value thus that bit will be freed
			STR R4,[R2]							;store freed version of that line
			BX LR								;return to delete
		
				
				
				
;//-------- <<< USER CODE END Free Function >>> ------------------------				
				ENDFUNC
				
;*******************************************************************************				

;@brief 	This function will be used to insert data to the linked list
;@param		R0 <- The data to insert
;@return    R0 <- Error Code
Insert			FUNCTION			
;//-------- <<< USER CODE BEGIN Insert Function >>> ----------------------															
				PUSH {LR}
				LDR R1,=FIRST_ELEMENT			;load first element address
				LDR R1,[R1]						;get value of first element variable
				CMP R1,#0						;compare the linked list is empty
				BEQ first_insert				;if linked list is empty jump to branch first_insert


				LDR R1,=FIRST_ELEMENT 			;load adress of FIRST_ELEMENT
				LDR R1,[R1]						;load value of FIRST_ELEMENT
traverse_list	LDR R2,[R1] 					;load beginning value of linked list (stored in FIRST_ELEMENT) 
				CMP R2,R0						;compare beginning value with value to add
				BEQ duplicate					;branch if value exists
				ADDS R1,R1,#4					;go next adress of value in memory node
				LDR R3,[R1]						;load that next memory adress
				CMP R3,#0						;check if its null
				BEQ can_insert					;branch to can insert if its null
				MOVS R1,R3						;go next adress if its not null
				B traverse_list					;go beginning of the loop
						
duplicate		MOVS R0,#2						;set duplicate data error flag to r0
				POP {PC}						;return to sysTickHandler
				
				
can_insert		LDR R1,=FIRST_ELEMENT			;load adress of FIRST_ELEMENT
				LDR R1,[R1]						;load value of FIRST_ELEMENT (beginning adress of linked list)
				LDR R2,[R1]						;load head's value to r2
				CMP R0,R2						;compare head value with value to add
				BLT insert_head					;if value to add less one, set as head
				
search 			ADDS R1,R1,#4					;go next word
				LDR R5,[R1]						;load value in that word
				CMP R5,#0						;check if its null (end of list)
				BEQ	insert_to_end				;branch to end of list if its null
				LDR	R6,[R5]						;go next adress if its not null
				CMP R0,R6						;compare value with value to add
				BLT insert_between				;if its less insert between
				MOVS R1,R5						;if its not go next adress
				B search						;continue to loop
				
				
				
insert_between	PUSH {R0}						;push the value to be inserted
				PUSH {R1}						;prev node's second word's address
				PUSH {R5}						;next
				BL	Malloc						;r0 has the next available address as returned value
				POP {R5}						;pop used register in that function
				POP {R1}						;pop used register in that function
				POP {R4}						;pop the new value to r4
				CMP R0,#1						;compare adress with 1
				BEQ check_error 				;branch if error occurred
				STR R4,[R0]						;set value
				STR R0,[R1]						;SET PREVIOUS NODE'S NEXT ADDRES TO NEW NODE
				STR R5,[R0,#4]					;SET NEW NODE'S NEXT TO R5
				B stop							;branch to end of function
			
							
				
				
				
insert_to_end	PUSH {R0}						;push value to use it end of malloc
				PUSH {R1}						;push value to use it end of malloc
				PUSH {R6}						;push value to use it end of malloc
				BL	Malloc						;r0 has the next available address as returned value
				POP {R6}						;pop old value to use it
				POP {R1}						;pop old value to use it
				POP {R4}						;pop old value to use it
				CMP R0,#1						;compare returned value with 1
				BEQ check_error					;branch if error occurred
				STR R0,[R1]						;SET PREVIOUS NODE'S NEXT ADDRES TO NEW NODE
				STR R4,[R0]						;set value
				MOVS R6,#0						;SET NEXT POINTER TO NULL
				STR R6,[R0,#4]					;SET NEXT POINTER TO NULL

				B stop							;branch to end of function
				
				

				
insert_head		PUSH {R0}						;push value to use it end of malloc
				PUSH {R5}						;push value to use it end of malloc
				BL	Malloc						;r0 has the next available address as returned value
				POP {R5}						;pop old value to use it
				POP {R4}						;pop old value to use it
				CMP R0,#1						;compare returned value with 1
				BEQ check_error					;branch if error occurred
				STR R4,[R0]						;set value
				LDR R5,=FIRST_ELEMENT			;get adress of FIRST_ELEMENT
				MOVS R7,R5						;move that value to r7
				LDR R5,[R5]						;load old beginning adress of linked list (old head)
				STR R5,[R0,#4]					;store old head to new head's next
				STR R0,[R7]						;store new head adress to FIRST_ELEMENT
				B stop							;branch to end of function
							


first_insert	PUSH {R0}						;push value to use it end of malloc
				BL	Malloc						;r0 has the next available address as returned value
				LDR R6,=DATA_MEM				;load beginning adress of data memory
				POP {R4}						;pop old value to use it
				CMP R0,#1						;compare returned value for error checking
				BEQ check_error					;branch if error occurred
				STR R4,[R0]						;SET VALUE
				LDR R2,=FIRST_ELEMENT			;get adress of FIRST_ELEMENT
				
				STR R0,[R2]						;set value of FIRST_ELEMENT to beginning of linked list
				MOVS R3,#0						;load null value to r3
				STR R3,[R0,#4]					;SET NEXT POINTER TO NULL
				B stop							;branch to end of function
				
				

stop 			MOVS R0,#0						;move success code to r0
				POP {PC}						;return to sysTickHandler
				
check_error		POP {PC}						;return to sysTickHandler
				
				
				

;//-------- <<< USER CODE END Insert Function >>> ------------------------				
				ENDFUNC
				
;*******************************************************************************				

;@brief 	This function will be used to remove data from the linked list
;@param		R0 <- the data to delete
;@return    R0 <- Error Code
Remove			FUNCTION			
;//-------- <<< USER CODE BEGIN Remove Function >>> ----------------------															
				
				PUSH {LR}						;push link register to stack
				LDR R1,=FIRST_ELEMENT			;load first element variable's address
				LDR R1,[R1]						;get value of first element variable
				CMP R1,#0						;check if list is empty
				BEQ empty_list					;branch to empty_list label if result of comparison is zero



traverse2		LDR R2,[R1] 					;load the data of first element
				CMP R2,R0						;compare with the current data to operate on
				BEQ delete						;value exists
				ADDS R1,R1,#4					;R1= R1->NEXT'S ADDRESS
				LDR R3,[R1]						;load the data in the next address
				CMP R3,#0						;compare if the next address is empty
				BEQ not_found					;go to not_found label, data to delete does not exist
				MOVS R1,R3						;move the next address to register we iterate on
				B traverse2						;branch to traverse2		

delete			LDR R1,=FIRST_ELEMENT			;load first element variable's address
				LDR R1,[R1]						;get value of first element variable
				LDR R2,[R1] 					;load the data of first element in allocation table
				CMP R2,R0						;compare the first element with the data to delete
				BEQ delete_head					;branch to delete head
				
				
search2			ADDS R1,R1,#4					;go to next address (this loop starts at head)
				LDR R5,[R1]						;R5= current node's address
				LDR R6,[R5]						;R6= current node's value
				CMP R6,R0						;compare if the data to be deleted is at current address
				BEQ	delete_node					;branch to delete the node if they are equal
				MOVS R1,R5						;move the next address to the register we iterate on
				B search2						;branch to search2 again
				
	
delete_node		LDR R6,[R5,#4]					;load next adrress of the node to be deleted
				STR R6,[R1]						;store the address value in it
				MOVS R7,#0						;move 0 to R7 to use when clearing
				STR R7,[R5]						;clear data of the node to be deleted
				STR R7,[R5,#4]					;clear next address of the data to be deleted						
				MOVS R0,R5						;move the next address of the deleted node to its previous node
				BL Free							;branch to free to deallocate memory
				B finish						;branch to finish
					
				
				
delete_head		LDR R4,[R1,#4]					;R4=R1's next
				MOVS R0,R1						;move head's next address to R0
				CMP R4,#0						;check if head is the only element in the list
				BEQ clear_list					;go to clear_list if it is the only element
				MOVS R5,#0						;move 0 to R5 to use when clearing
				STR R5,[R1]						;clear head's value
				ADDS R1,R1,#4					;head next's address
				
				LDR R2,[R1]						;store new head's data
				STR R5,[R1]						;store new head's next address
				LDR R6,=FIRST_ELEMENT			;get address of first element variable
				STR R2,[R6]						;set new head
				BL Free							;branch to free to deallocate memory
				B finish						;branch to finish
						
				
				
clear_list		MOVS R5,#0						;move 0 to R5 to use when clearing
				STR R5,[R1]						;set head to zero
				LDR R1,=FIRST_ELEMENT			;clear first element
				STR R5,[R1]						;store zero as first element's address because the only element in the list has been deleted		
				BL Free							;branch to free to deallocate memory
				B finish						;branch to finish
				

finish 			MOVS R0,#0						;succes code
				POP {PC}						;return to SysTick_Handler


empty_list		MOVS R0,#3						;empty list error
				POP {PC}						;return to SysTick_Handler
							
				
not_found		MOVS R0,#4						;The element is not found.
				POP {PC}						;return to SysTick_Handler

;//-------- <<< USER CODE END Remove Function >>> ------------------------				
				ENDFUNC
				
;*******************************************************************************				

;@brief 	This function will be used to clear the array and copy the linked list to the array
;@return	R0 <- Error Code
LinkedList2Arr	FUNCTION			
;//-------- <<< USER CODE BEGIN Linked List To Array >>> ----------------------															

				LDR R1,=FIRST_ELEMENT			;load first element variable's address
				LDR R4,=ARRAY_MEM				;load array memory's address
				LDR R6,=ARRAY_SIZE				;load array size
				
				
				ADDS R6,R4,R6					;add beginning of array memory and array size to find finish address
clear_array		CMP R4,R6						;compare finish address and current address
				BEQ	continue					;if current address is equal to finish address jump to branch continue
				MOVS R5,#0						;clear R5
				STR R5,[R4]						;clear array element	
				ADDS R4,R4,#4					;incrementing of current address
				B clear_array					;to clear all array elements jump to clear_array

continue		LDR R4,=ARRAY_MEM				;load array memory address to R4
				LDR R1,[R1]						;get value of first element variable
				CMP R1,#0						;check if list is empty
				BEQ empty_error					;jump to branch empty_error
				


traverse3		LDR R2,[R1]						;load node's value of first element address
				STR R2,[R4]						;store node's value to array memory address
				
				LDR R2,[R1,#4]					;load linked list's other value to R2 by incrementing memory address 4 byte
				CMP R2,#0						;compare node value is whether 0 
				BEQ end_of_list					;if value is 0 jump to branch end_of_list
				MOVS R1,R2						;move node value to R1
				ADDS R4,R4,#4					;increment array index 4 byte
				B traverse3						;to transfer linked list values to array, jump to branch traverse3
				

empty_error		MOVS R0,#5						;empty list
				BX LR							;return to SysTick_Handler
				

end_of_list		MOVS R0,#0						;succes code
				BX LR 							;return to SysTick_Handler
				

;//-------- <<< USER CODE END Linked List To Array >>> ------------------------				
				ENDFUNC
				
;*******************************************************************************				

;@brief 	This function will be used to write errors to the error log array.
;@param		R0 -> Index of Input Dataset Array, 16 BIT
;@param     R1 -> Error Code , 8 BIT
;@param     R2 -> Operation (Insertion / Deletion / LinkedList2Array) , 8 BIT
;@param     R3 -> Data, 32 BIT
WriteErrorLog    FUNCTION
;//-------- <<< USER CODE BEGIN Write Error Log >>> ----------------------

                LDR R4,=LOG_MEM					; loading address of LOG_MEM to R4
                LDR R6,=INDEX_ERROR_LOG			; loading address of INDEX_ERROR_LOG to R6
                LDR R6,[R6]						; loading address of R6 to R6
                MOVS R7,#12						; R7=12
                MULS R6,R7,R6					; R6=R6*R7
                ADDS R4,R4,R6					; R4=the address to write log

                STRH R0,[R4]                    ; store lower halfword R0 to R4 
                STRB R1,[R4,#2]					; store 1 byte R1 to the 2nd index of R4, means R4[2]
                STRB R2,[R4,#3]					; store 1 byte R2 to the 3rd index of R4, means R4[3]
                STR  R3,[R4,#4]					; store 1 byte R3 to the 4th index of R4, means R4[4]
                PUSH {LR}						; For saving the value of LR register, we push it 
                BL GetNow						; calling GetNow function
                STR  R0,[R4,#8]                 ; store R0 to the 8th index of R4, means R4[8]

                LDR R6,=INDEX_ERROR_LOG         ; loading add of INDEX_ERROR_LOG to R6
                LDR R7,[R6]                     ; get log index
                ADDS R7,R7,#1                   ; increment log index
                STR R7,[R6]                     ; Store the value of R7 to the address of R6

                POP {PC}                        ; pop the last pushed value to the pc, return from the function

;//-------- <<< USER CODE END Write Error Log >>> ------------------------
                ENDFUNC
				
;@brief 	This function will be used to get working time of the System Tick timer
;@return	R0 <- Working time of the System Tick Timer (in us).			
GetNow			FUNCTION			
;//-------- <<< USER CODE BEGIN Get Now >>> ----------------------															
				
				LDR	R0,=0xE000E018				;load current value register 
				LDR R0, [R0]					;get current value
				LDR	R1,=TICK_COUNT				;load tick count address
				LDR R1, [R1]					;get tick count
				ADDS R1,R1,#1					;increment tick count
				LDR R2,=17567					;reload value
				
				SUBS R0, R2, R0					;r0= reload- current value
				LDR  R6,=549					;set period
				
				MULS R1,R6,R1					;PERIOD * (TICK_COUNT+1)
				LSRS R0,#5						;divide R0 by clock freq 32
				ADDS R0,R0,R1					;R2= PERIOD*(TICK_COUNT+1) + (reload-current value)/32
				
				BX LR							;branch back
				
;//-------- <<< USER CODE END Get Now >>> ------------------------
				ENDFUNC
				
;*******************************************************************************	

;//-------- <<< USER CODE BEGIN Functions >>> ----------------------															


;//-------- <<< USER CODE END Functions >>> ------------------------

;*******************************************************************************
;@endsection 		USER_FUNCTIONS
;*******************************************************************************
				ALIGN
				END		; Finish the assembly file
				
;*******************************************************************************
;@endfile 			main.s
;*******************************************************************************				

