;
; RC Gear door seaquencer-T4 for PICAXE 14M2 (2015/7/18 version 1.00)
;
; This is door seaquencer for KAWASAKI T4 retract gear.
; T-4 has doors of nose, body gear. body gear has 2-doors.
; This seaquencer control the body gear 2-doors by servo.
; You can see video(Youtube) gear and door sequence.
;
; 	Kawasaki T4 Gear Door Sequencer PICAXE 14M2
; 	https://youtu.be/qPIBussmqMQ
;
;	Circuit diagram(in Japanese):
;	http://kurosawa.e-rc.jp/plane?bc=294qJNqV5n7d8
; 
; [main] control is nose and body front door together.
; [rear door] control is body rear door.
;
; [main]doors is open -> gear up -> close
; [rear door] is gear up and together close as like the linkaged body gear and rear door.
;
; Copyright (c) 2014 Hiroyuki Kurosawa
; http://kurosawa.e-rc.jp
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;
;
; Revision,
;
; 2015/7/18 
; 	fixed bloken door(failed sequence) 2015/7/18 
; 	out gear position same s/w postion for move gear(*1)
; 	beacue not move gear up when following case.
;  		1.gear DOWN, s/w DOWN
;  		2.all door open
;  		3.when s/w UP
;  		4.gear UP(when not move this time) <- *1
;  		5.proceed gear up procedure
;     	  (main rear door closing, but this time(status) is gear down
;      	  and bloken main rear door) 
;
; 2015/7/5 Add 2nd led for landing light.

Setfreq M32

; Pins
symbol LED_PIN = c.4 ; LED on/offout, ON when gear down complete like the landing light.
symbol LED_PIN2 = c.1 ; LED on/offout, ON when gear down complete like the landing light.
symbol DOOR_PIN = c.2 ; gear door(MAIN/NOSE) pulse out
symbol GEAR_PIN = b.1 ; gear pulse out
symbol SW_PIN = C.3 ; Gear switch pulse input 
symbol DOOR2_PIN = b.3 ; gear door(REAR) pulse out
symbol DOOR_MAIN_F_PIN = b.2 ; gear door(Main-Front) pulse out
;
; Vaiables & Constant
;
; reverse
symbol GEAR_REVERSE = 1 ; 1: reverse 0;non
symbol DOOR_REVERSE = 0 ; 1: reverse nose door 0;non
symbol DOOR2_REVERSE = 0 ; 1: reverse main-rear door 0;non
symbol DOOR_MAIN_F_REVERSE = 0 ; 1: reverse main-front door 0;non

;
; Word variables
;
; Gear switch 3 variables for chattering 
symbol pulseSwith = w0 
symbol pulseSwithPrv = w1 
symbol pulseSwithPrvPrv = w2 

; Current pulse from Transmitter gear switch
symbol pulseGear = w3
	symbol GEAR_MAX_POS = 1524; down
	symbol GEAR_MIN_POS = 882; up
	symbol SERVO_NEUTRAL_POS = 1203; 146

; Current door(NOSE) pulse
symbol pulseDoor = w4
	symbol DOOR_MAX_POS =  1530; 2.1ms
	symbol DOOR_MIN_POS =  670; 0.8ms
	symbol DOOR_PLUSE_INCREMENT = 12 ; incriment next pulse out for door(MAIN/NOSE) open/close speed. To Fist, increase the value.

; Current door(Main-REAR) pulse
symbol pulseDoor2 = w5
	symbol DOOR2_MAX_POS =  1600; 
	symbol DOOR2_MIN_POS =  700; 
	symbol DOOR2_PLUSE_INCREMENT = 12 ; incriment next pulse out for door(REAR) open/close speed, To Fist, increase the value.


; open/close wait count from gear down/up out to start for door(REAR)
 symbol countWaitCloseDoor = w6
	symbol DOOR2_OPEN_WAIT = 20 ; msec(>=20) wait for from output gear DOWN to start of door(REAR) open
	symbol DOOR2_CLOSE_WAIT = 100 ; msec(>=20) wait for from output gear UP to start of door close

; init wait count
symbol countWaitStartSequece = w7 
	symbol START_INIT_WAITE = 1000 ; (msec) wait for init(doors open)
	symbol START_SEQUENCE_WAITE = 2000 ; (msec) wait for start sequence
	symbol INIT_GEAR_UP_DOWN_WAIT = 2000 ; wait of init gear down from gear UP by gear s/w DOWN 
							 ; or gear DOWN by gear s/w UP 
; work
symbol work1 = w8
symbol work2 = w9

; Current door(Main-FRONT) pulse
symbol pulseDoorMainFront = w10
	symbol DOOR_MAIN_F_MAX_POS =  1530; 2.1ms at gear UP.
	symbol DOOR_MAIN_F_MIN_POS =  670; 0.8ms at gear UP.
	symbol DOOR_PLUSE_MAIN_F_INCREMENT = 12 ; incriment next pulse out for door(MAIN/NOSE) open/close speed. To Fist, increase the value.
	symbol DOOR_MAIN_F_G_DOWN_MAX_POS = 1380; 1.2ms max at gear DOWN.
	symbol DOOR_MAIN_F_G_DOWN_MIN_POS = 820; min at gear DOWN.
;
; Byte variables
;
; Status of Transmitter gear up/down
symbol upDownGearSwitch = b22; w11(0)
	symbol GEAR_SW_UP = 1 ;  UP
	symbol GEAR_SW_DOWN = 2 ; DOWN

; Status of gear/door sequence
symbol statusGear = b23 ; w11(1)
	symbol ST_INIT = 0 ; init
	symbol ST_INIT_WATING = 1
	symbol ST_INIT_WATING_START = 2
	symbol ST_INIT_WATING_GEAR_DOWN = 3 ; gear down waiting for initilial when gear s/w si down.
	symbol ST_GEAR_DOWN_FIN = 5 ; gear down / door close complete
	symbol ST_GEAR_DOWN = 10 ; gear DOWN
	symbol ST_GEAR_OPENING_FOR_UP = 20 ; door is opening(gear is uping) for UP
	symbol ST_GEAR_OPENING_FOR_DOWN = 22 ; door is opening(gear is uping) for DOWN
	symbol ST_GEAR_OPENED_FOR_UP = 30 ; door open complete for UP
	symbol ST_GEAR_OPENED_FOR_DOWN = 32 ; door open complete for DOWN
	symbol ST_GEAR_UPING = 40 ; gear uping (wait for start of door close) 
	symbol ST_GEAR_DOOR_CLOSING_2 = 50 ; door(REAR) closing
	symbol ST_GEAR_DOOR_CLOSING_FOR_UP = 60 ; door(REAR) closing for UP
	symbol ST_GEAR_DOOR_OPENING_2 = 62 ; door(REAR) opening
	symbol ST_GEAR_DOOR_OPENED_2 = 64 ; door(REAR) open complete
	symbol ST_GEAR_DOOR_CLOSING_FOR_DOWN = 66 ; door(MAIN) closing for DOWN
	symbol ST_GEAR_DOWING = 70 ; gear is downing
	symbol ST_GEAR_WAITING_DOWNING = 72; waiting gear dowing with not move rear door 
	symbol ST_GEAR_UP = 80 ; gear UP
	symbol ST_GEAR_UP_FIN = 99 ; gear UP complete / door close complete
	; Current door(REAR) pulse

;
; sequence of initilize 
;   1->2->80(up)
;       ->10(down)
;
; sequence gear UP 
;   5->20->30->80(init)->40->50->60->99 
;                     
;                        40----->60  
;                        skip 50 when initilized which s/w is UP and gear down status.
;                        for dot close rear door.
;      
; sequence gear DOWN
;   99->22->32->10(init)->70->62->64->66->5 
;
;                         70->72->62 
;                         add 72 when 1st gear down which s/w is UP and gear up status.
;                         for waiting gear up complete.
;  
;
; *Case 1(gear UP stat and power on, s/w UP)
;
; 1.Power off stat following.
;   -[main]doors is closed
;   -[rear door] is closed.
;   -[retract gear]is up
;   -gear [S/W] is UP
; 2.Power on 
; 3.[main]doors and [rear door]open immediate.
; 4.puse 2(sec)
; 5.[main]doors close. 
;
; complete power on
;
; 6.[S/W] DOWN.[rear door] is not move(open)
; 7.[main]doors open.
; 8.[retract gear] down
; 9.[main]doors close.([rear door] is keep opened)
;
; comlete gear down.
;
;
; *Case 2(gear DOWN stat and power on, s/w UP)
;
; 1.Power off stat following.
;   -[main]doors is closed
;   -[rear door] is opened.
;   -[retract gear]is down
;   -gear [S/W] is UP
; 2.Power on 
; 3.[main]doors open immediate(and [rear door] opend).
; 4.[retract gear] **NOT move to UP**
; 5.puse 2(sec)
; 6.[main]doors close. 
;
; complete power on
;
; 6.[S/W] DOWN for comfirmaion s/w
; 7.[main]doors open.
; 8.[retract gear] down
; 9.[main]doors and [rear door] close.
;
; comlete gear down confirmation illegale [S/W] poition.
;
;
;
; *Case 3(gear DOWN stat and power on, s/w DOWN)
;
; 1.Power off stat following.
;   -[main]doors is closed.
;   -[rear door] is open.
;   -[retract gear]is down.
;   -gear S/W is DOWN
; 2.Power on
; 3.[main]doors open
; 4.puse 2(sec)
; 5.[main]doors close.
; 
; complete power on
;
;
; *Case 4(gear DOWN stat and power on, s/w UP)
;
; 1.Power off stat following.
;   -[main]doors is closed.
;   -[rear door] is open.
;   -[retract gear]is down.
;   -gear S/W is UP
; 2.Power on
; 3.[main]doors open
; 4 [retract gear] **NOT move to UP**
; 4.puse 2(sec)
; 5.[main]doors close.
; 
; complete power on
;
; 6.[S/W] DOWN(for reset )
; 3.[main]doors open
; 4.puse 2(sec)
; 5.[main]doors close.
;
; complete down confirmation illegale [S/W] poition.


; *Case 5(gear up normal)
;
; 1.[S/W] UP
; 2.[main]doors open.
; 3.[retract geart] up with [rear door].
; 4.[main]doors close.
;
; complete gear up.
;
;
; *Case 6(gear down normal)
;
; 1.[S/W] UP
; 2.[main]doors open.
; 3.[retract geart] down with [rear door].
; 4.[main]doors close.
;
; complete gear down.
;
;

; result check door open by 'gosub doorOpenedClosedCheck' or 'gosub door2OpenedClosedCheck'
symbol statusDoor = b24 ; w12(0)
	symbol DOOR_CLOSED = 1
	symbol DOOR_OPENED = 2	

; count of gear down
symbol countGearDown = b25; w12(1)

; value of upDownGearSwitch when power on
symbol upDownGearSwitchPowerOn = b26 ; w13(0)
	

; reserved w13(1,0)

	
; if use gear unit of not move when power of pluse postion. then NOT_MOVE_INIT_PULSE_POS is 1
; ex:
;	Not move output to the value of gear down pulse when status of gear up.
; if move to output to the value of gear down pulse when status of gear up, 
; then NOT_MOVE_INIT_PULSE_POS is 0
;
symbol NOT_MOVE_INIT_PULSE_POS = 0

; LED for Landing light
symbol AVAILABLE_LED  = 1
symbol LED_OFF = 0
symbol LED_ON = 1
	
; intial 
init:
	; init variables
	pulseGear = 0
	pulseDoor = 0
	pulseDoor2 = 0
	pulseDoorMainFront = 0
	statusGear = ST_INIT
	upDownGearSwitch = 0
	pulseSwithPrv = 0
	pulseSwithPrvPrv = 0
	
	countGearDown = 0
	upDownGearSwitchPowerOn = 0
	
	gosub ledInit
	
'main loop
main:

	gosub checkSwitchGear ; check gear switch of transmitter, result -> statusGear
	gosub outPulseGearDoors ; output to pulse gear and doors
	
	;0: init start
	if statusGear = ST_INIT then
		work1 = START_INIT_WAITE
		if work1 >= 20 then
			countWaitStartSequece = START_INIT_WAITE / 20
		else
			countWaitStartSequece = 1
		endif
		
		statusGear = ST_INIT_WATING ;1: init wait
	;1: waiting for init
	elseif statusGear = ST_INIT_WATING then 
		;set wait count
		countWaitStartSequece = countWaitStartSequece - 1;
		if countWaitStartSequece <= 0 then
		
			; set upDownGearSwitchPoweOn when power on
			upDownGearSwitchPowerOn = upDownGearSwitch
			
			; door open
			gosub doorOpen ; MAIN/NOSE  
			gosub door2Open ; REAR
			
			work1 = NOT_MOVE_INIT_PULSE_POS
			if work1 = 1 then
				if upDownGearSwitch = GEAR_SW_UP then
					gosub gearDown
				else 
					gosub gearUp
				endif
			else 
				; fixed bloken door(failed sequence) 2015/7/18 
				; out gear position same s/w postion for move gear(*1)
				; beacue not move gear up when following case.
				;  1.gear DOWN, s/w DOWN
				;  2.all door open
				;  3.when s/w UP
				;  4.gear UP(when not move this time) <- *1
				;  5.proceed gear up procedure
				;     (main rear door closing, but this time(status) is gear down
				;      and bloken main rear door) 
				if upDownGearSwitch = GEAR_SW_UP then
					gosub gearUp
				else 
					gosub gearDown
				endif
			endif
			
			;initilize pulse out of door open
			work1 = START_SEQUENCE_WAITE
			if work1 >= 20 then
				countWaitStartSequece = START_SEQUENCE_WAITE / 20
			else
				countWaitStartSequece = 1
			endif
			statusGear = ST_INIT_WATING_START ;2: start wait for
			
		endif
		
	;2: init wait for start sequence and set status of start sequece
	elseif statusGear = ST_INIT_WATING_START then 
		;decrement count wait
		countWaitStartSequece = countWaitStartSequece - 1;
		if countWaitStartSequece <= 0 then
			if  upDownGearSwitch = GEAR_SW_UP then
				statusGear = ST_GEAR_UP;80:gear UP
				
			elseif upDownGearSwitch = GEAR_SW_DOWN then

				work1 = NOT_MOVE_INIT_PULSE_POS
				if work1 = 1 then
					gosub gearDown ; gear DOWN
					gosub setWaitCountGearUpDown ; set wait count gear up/down
					
					statusGear = ST_INIT_WATING_GEAR_DOWN ; 3: gear down waiting for initilial when gear s/w si down.
				else
					statusGear = ST_GEAR_DOWN ; 10:gear down 
				endif

			endif
		endif
	;3: gear down waiting for initilial when gear s/w is down. 
	elseif statusGear = ST_INIT_WATING_GEAR_DOWN then 
		countWaitStartSequece = countWaitStartSequece - 1;
		if countWaitStartSequece <= 0 then
			statusGear = ST_GEAR_DOOR_CLOSING_FOR_DOWN; 66: door(MAIN) closing for DOWN
		endif

	; 5:gear down / door close complete
	elseif statusGear = ST_GEAR_DOWN_FIN then 
		if  upDownGearSwitch = GEAR_SW_UP then
			statusGear = ST_GEAR_OPENING_FOR_UP ; 20:door is opening(gear is uping) for UP 
		endif

	; 10:gear down 
	elseif statusGear = ST_GEAR_DOWN then 
		if  upDownGearSwitch = GEAR_SW_UP then
			gosub gearUp ; gear UP out
			gosub calCountGearDoorClose ; calculate count of door(REAR) open for wait
			statusGear = ST_GEAR_UP ; -> gear UP
		elseif upDownGearSwitch = GEAR_SW_DOWN then
			gosub gearDown ; gear DOWN out
			gosub calCountGearDoorOpen ; calculate count of door(REAR) open for wait
			statusGear = ST_GEAR_DOWING ; 70:gear is downing
		endif
		
	; 20:door(MAIN/NOSE) opening for UP 
	elseif statusGear = ST_GEAR_OPENING_FOR_UP then
		if  upDownGearSwitch = GEAR_SW_UP then
			; GEAR_SW_UP
			gosub doorOpeningCalculation
			gosub doorOpenedClosedCheck
			if statusDoor = DOOR_OPENED then ; if door opened
				statusGear = ST_GEAR_OPENED_FOR_UP ; 30:door open complete for UP
			endif
		elseif upDownGearSwitch = GEAR_SW_DOWN then
			;  GEAR_SW_DOWN
			statusGear = ST_GEAR_DOOR_CLOSING_FOR_DOWN ; door(REAR) closing for UP
		endif


	; 22:door(MAIN/NOSE) opening for DOWN 
	elseif statusGear = ST_GEAR_OPENING_FOR_DOWN then
		if  upDownGearSwitch = GEAR_SW_UP then
			; GEAR_SW_UP
			statusGear = ST_GEAR_DOOR_CLOSING_FOR_UP ; 66:door(REAR) closing for UP
		elseif upDownGearSwitch = GEAR_SW_DOWN then
			;  GEAR_SW_DOWN
			gosub doorOpeningCalculation
			gosub doorOpenedClosedCheck
			if statusDoor = DOOR_OPENED then ; if door opened
				statusGear = ST_GEAR_OPENED_FOR_DOWN ; 32:door(MAIN/NOSE) open complete for DOWN
			endif
		endif

	; 30:door open complete for UP
	elseif statusGear = ST_GEAR_OPENED_FOR_UP then
		if  upDownGearSwitch = GEAR_SW_UP then
			; GEAR_SW_UP
			statusGear = ST_GEAR_UP ; 80:gear UP
		elseif upDownGearSwitch = GEAR_SW_DOWN then
			;  GEAR_SW_DOWN
			statusGear = ST_GEAR_DOOR_CLOSING_FOR_DOWN ; door(REAR) closing for UP
		endif
		
	; 32:door open complete for DOWN
	elseif statusGear = ST_GEAR_OPENED_FOR_DOWN then
		if  upDownGearSwitch = GEAR_SW_UP then
			; GEAR_SW_UP
			statusGear = ST_GEAR_DOOR_CLOSING_FOR_UP ; door(REAR) closing for UP
		elseif upDownGearSwitch = GEAR_SW_DOWN then
			;  GEAR_SW_DOWN
			statusGear = ST_GEAR_DOWN ; 10:gear down 
		endif
		
	; 40:gear uping for up(wait for start of door close) 
	elseif statusGear = ST_GEAR_UPING then
		if  upDownGearSwitch = GEAR_SW_UP then
			; GEAR_SW_UP
			gosub doorCloseStartDecrimentCount ;decriment count of door(REAR) open start wait
			if countWaitCloseDoor  <= 0 then ; if time up gear door close wait
				; if s/w is UP when power on and not gear down 
				if upDownGearSwitchPowerOn = GEAR_SW_UP and  countGearDown = 0 then
					; dot close rear door beauce retract gear not move to up.(move to up next down and up) 
					; gosub setWaitCountGearUpDown ; set wait count gear up/down
					statusGear = ST_GEAR_DOOR_CLOSING_FOR_UP ; 60:door closing for UP
				else 
					statusGear = ST_GEAR_DOOR_CLOSING_2 ; 50:door(REAR) closing
				endif
			endif
		elseif upDownGearSwitch = GEAR_SW_DOWN then
			;  GEAR_SW_DOWN
			statusGear = ST_GEAR_OPENING_FOR_UP ; door is opening(gear is uping) for UP
			
		endif
	
	; 50:door(REAR) closing for up
	elseif statusGear = ST_GEAR_DOOR_CLOSING_2 then
		if  upDownGearSwitch = GEAR_SW_UP then
			; GEAR_SW_UP
			gosub door2ClosingCalculation ; decriment pulse door(REAR) for close
			gosub door2OpenedClosedCheck ; check close for pulse door(REAR)
			if statusDoor = DOOR_CLOSED then ; if door(REAR) close
				statusGear = ST_GEAR_DOOR_CLOSING_FOR_UP ; 60:door closing for UP
			endif
		elseif upDownGearSwitch = GEAR_SW_DOWN then
			;  GEAR_SW_DOWN
			gosub gearDown ; gear DOWN
			gosub calCountGearDoorOpen ; calculate count of door(REAR) open for wait
			statusGear = ST_GEAR_DOOR_OPENING_2 ; door(REAR) opening
		endif

	; 60:door closing for up
	elseif statusGear = ST_GEAR_DOOR_CLOSING_FOR_UP then
		if  upDownGearSwitch = GEAR_SW_UP then
			; GEAR_SW_UP
			gosub doorClosingCalculation; decrement pulse door(MAIN/NOSE)
			gosub doorOpenedClosedCheck; check closed 
			if statusDoor = DOOR_CLOSED then ; if door closed
				statusGear = ST_GEAR_UP_FIN ; 99:gear UP complete / door close complete
			endif
		elseif upDownGearSwitch = GEAR_SW_DOWN then
			;  GEAR_SW_DOWN
			statusGear = ST_GEAR_OPENING_FOR_DOWN ; 22:door(MAIN/NOSE) is opening(gear is uping) for DOWN
			
		endif

	; 62:door(REAR) opening for down 
	elseif statusGear = ST_GEAR_DOOR_OPENING_2 then
		if  upDownGearSwitch = GEAR_SW_UP then
			; GEAR_SW_UP
			statusGear = ST_GEAR_UP; 80:ST_GEAR_UP
		elseif upDownGearSwitch = GEAR_SW_DOWN then
			;  GEAR_SW_DOWN
			gosub door2OpeningCalculation ; increment pulse door(REAR)
			gosub door2OpenedClosedCheck ; check opened
			if statusDoor = DOOR_OPENED then ; if door opened
				statusGear = ST_GEAR_DOOR_OPENED_2 ; 64:door(REAR) open complete
			endif
		endif


	; 64:door(REAR) open complete for down
	elseif statusGear = ST_GEAR_DOOR_OPENED_2 then
		if  upDownGearSwitch = GEAR_SW_UP then
			; GEAR_SW_UP
			statusGear = ST_GEAR_UP; 80:ST_GEAR_UP
		elseif upDownGearSwitch = GEAR_SW_DOWN then
			;  GEAR_SW_DOWN
			statusGear = ST_GEAR_DOOR_CLOSING_FOR_DOWN ; 66:door(MAIN) closing for DOWN
		endif
		
	; 66:door(MAIN) closing for down
	elseif statusGear = ST_GEAR_DOOR_CLOSING_FOR_DOWN then
		if  upDownGearSwitch = GEAR_SW_UP then
			; GEAR_SW_UP
			statusGear = ST_GEAR_OPENING_FOR_UP; door is opening(gear is uping) for UP
		elseif upDownGearSwitch = GEAR_SW_DOWN then
			;  GEAR_SW_DOWN
			gosub doorClosingCalculation; decrement count for door(MAIN/NOSE)
			gosub doorOpenedClosedCheck ; check closed count 
			if statusDoor = DOOR_CLOSED then ; if door opened
				statusGear = ST_GEAR_DOWN_FIN ; 5:gear down / door close complete
			endif
		endif
		
	; 70:gear is downing for down
	elseif statusGear = ST_GEAR_DOWING then
		if  upDownGearSwitch = GEAR_SW_UP then
			; GEAR_SW_UP
			statusGear = ST_GEAR_UP;  80:gear UP
		elseif upDownGearSwitch = GEAR_SW_DOWN then
			;  GEAR_SW_DOWN
			
			gosub doorCloseStartDecrimentCount ;decrement count of door(REAR) open start wait
			if countWaitCloseDoor  <= 0 then ; if time up gear door open wait			
				; 1st gear down which s/w is UP when power on and not gear down 
				if upDownGearSwitchPowerOn = GEAR_SW_UP and  countGearDown = 1 then
					gosub setWaitCountGearUpDown
					statusGear = ST_GEAR_WAITING_DOWNING ;  72:wait for gear down complete for up
				else
					statusGear = ST_GEAR_DOOR_OPENING_2 ; 62:door(REAR) opening
				endif
			endif

		endif

	
	; 72:wait for gear down complete for up
	elseif statusGear = ST_GEAR_WAITING_DOWNING then
		countWaitStartSequece = countWaitStartSequece - 1;
		if countWaitStartSequece <= 0 then
			statusGear = ST_GEAR_DOOR_OPENING_2 ; 62:door(REAR) opening
		endif	
		
	; 80:gear UP
	elseif statusGear = ST_GEAR_UP then
		if  upDownGearSwitch = GEAR_SW_UP then
			; GEAR_SW_UP
			gosub gearUp ; gear UP
			gosub calCountGearDoorClose ; calculate count of door(REAR) open for wait
			statusGear = ST_GEAR_UPING; 40: gear doing up(wait for start of door close) 
		elseif upDownGearSwitch = GEAR_SW_DOWN then
			;  GEAR_SW_DOWN
			statusGear = ST_GEAR_DOOR_CLOSING_FOR_DOWN; 60:door(REAR) closing for UP	
		endif

	; 99:gear UP complete / door close complete
	elseif statusGear = ST_GEAR_UP_FIN then
		if  upDownGearSwitch = GEAR_SW_DOWN then
			;  GEAR_SW_DOWN
			statusGear = ST_GEAR_OPENING_FOR_DOWN; 22:door is opening(gear is uping) for DOWN
		endif

	endif
	
	goto main

; init LED
ledInit:
	work1 = AVAILABLE_LED;
	if work1 = 1 then
		low LED_PIN
		low LED_PIN2
	endif
	return	
;LED on
ledOn:

	work1 = AVAILABLE_LED;
	if work1 = 1 then
		high LED_PIN
		high LED_PIN2
	endif
	return
; LED off
ledOff:
	work1 = AVAILABLE_LED;
	if work1 = 1 then
		low LED_PIN
		low LED_PIN2
	endif
	return
; set wait count gear up/down
setWaitCountGearUpDown:
	work1 = INIT_GEAR_UP_DOWN_WAIT
	if work1 >= 20 then
		countWaitStartSequece = INIT_GEAR_UP_DOWN_WAIT / 20;
	else 
		countWaitStartSequece = 1
	endif
	return
; output to pulse gear and doors
outPulseGearDoors:
	if pulseGear > 0 then 
		pulsout GEAR_PIN, pulseGear ; gear
	endif
	if pulseDoor > 0 then
		pulsout DOOR_PIN, pulseDoor ; door (NOSE)
	endif
	if pulseDoor2 > 0 then
		pulsout DOOR2_PIN, pulseDoor2 ; door(Main-REAR) 
	endif
	if pulseDoorMainFront > 0 then
		pulsout DOOR_MAIN_F_PIN, pulseDoorMainFront ; door(Main-FRONT) 
	endif
	return
	
; calculate count of door(REAR) close wait
calCountGearDoorClose:
	work1 = DOOR2_CLOSE_WAIT
	if work1 >= 20 then
		countWaitCloseDoor = DOOR2_CLOSE_WAIT / 20
	else
		countWaitCloseDoor = 1
	endif
	return
; calculate count of door(REAR) open wait
calCountGearDoorOpen:
	work1 = DOOR2_OPEN_WAIT
	if work1 >= 20 then
		countWaitCloseDoor = DOOR2_OPEN_WAIT / 20
	else
		countWaitCloseDoor = 1
	endif
	return
; decriment count of door(REAR) open/close start wait
doorCloseStartDecrimentCount:
	let countWaitCloseDoor = countWaitCloseDoor -1;
	return
; door(MAIN-Front/NOSE) Open
doorOpen:
	work1 = DOOR_REVERSE;
	if work1 = 0  then
		pulseDoor = DOOR_MAX_POS
	else
		pulseDoor = DOOR_MIN_POS
	endif
	
	work1 = DOOR_MAIN_F_REVERSE;
	if work1 = 0  then
		pulseDoorMainFront = DOOR_MAIN_F_MAX_POS
	else
		pulseDoorMainFront = DOOR_MAIN_F_MIN_POS
	endif
	return
; door(MAIN-Front/NOSE) Close
doorClose:
	work1 = DOOR_REVERSE;
	if work1 = 0  then
		pulseDoor = DOOR_MIN_POS
	else
		pulseDoor = DOOR_MAX_POS
	endif	
	
	work1 = DOOR_MAIN_F_REVERSE;
	if work1 = 0  then
		pulseDoorMainFront = DOOR_MAIN_F_MIN_POS
	else
		pulseDoorMainFront = DOOR_MAIN_F_MAX_POS
	endif
	return
; door closing calculation for pulse	
doorClosingCalculation:
	work1 = DOOR_REVERSE;
	if work1 = 0  then
		gosub doorPulseDecrement
	else
		gosub doorPulseIncrement
	endif
	
	if statusGear = ST_GEAR_DOOR_CLOSING_FOR_DOWN then
		work1 = DOOR_MAIN_F_REVERSE;
		if work1 = 0  then
			gosub doorPulseMainFrontDwnDecrement
		else
			gosub doorPulseMainFrontDwnIncrement
		endif
	else 
		work1 = DOOR_MAIN_F_REVERSE;
		if work1 = 0  then
			gosub doorPulseMainFrontDecrement
		else
			gosub doorPulseMainFrontIncrement
		endif
	endif
	return	
; door opening calculation for pulse	
doorOpeningCalculation:
	work1 = DOOR_REVERSE;
	if work1 = 0  then
		gosub doorPulseIncrement
	else 
		gosub doorPulseDecrement
	endif

	work1 = DOOR_MAIN_F_REVERSE;
	if work1 = 0  then
		gosub doorPulseMainFrontIncrement
	else 
		gosub doorPulseMainFrontDecrement
	endif

	return
; door(nose) pulse decrement for open/close
doorPulseDecrement:
	if pulseDoor > DOOR_MIN_POS then ; if not close door
		let pulseDoor = pulseDoor - DOOR_PLUSE_INCREMENT ; door pulse descriment
	endif
	return
; door(main-front)decrement for open/close
doorPulseMainFrontDecrement:
	if pulseDoorMainFront > DOOR_MAIN_F_MIN_POS then ; if not close door
		let pulseDoorMainFront = pulseDoorMainFront - DOOR_PLUSE_MAIN_F_INCREMENT ; door pulse descriment
	endif
	return
; door(main-front)decrement for gear down close
doorPulseMainFrontDwnDecrement:
	if pulseDoorMainFront > DOOR_MAIN_F_G_DOWN_MIN_POS then ; if not close door
		let pulseDoorMainFront = pulseDoorMainFront - DOOR_PLUSE_MAIN_F_INCREMENT ; door pulse descriment
	endif
	return
; door(nose) pulse increment for open/close
doorPulseIncrement:
	if pulseDoor < DOOR_MAX_POS then
		pulseDoor = pulseDoor + DOOR_PLUSE_INCREMENT ; door pulse increment
	endif
	return
; door(main-front) pulse increment for open/close
doorPulseMainFrontIncrement:
	if pulseDoorMainFront < DOOR_MAIN_F_MAX_POS then
		pulseDoorMainFront = pulseDoorMainFront + DOOR_PLUSE_MAIN_F_INCREMENT ; door pulse increment
	endif
	return
; door(main-front) pulse increment for gear down close
doorPulseMainFrontDwnIncrement:
	if pulseDoorMainFront < DOOR_MAIN_F_G_DOWN_MAX_POS then
		pulseDoorMainFront = pulseDoorMainFront + DOOR_PLUSE_MAIN_F_INCREMENT ; door pulse increment
	endif
	return
; door open/close check
; resut -> statusDoor
doorOpenedClosedCheck:
	work1 = DOOR_REVERSE;
	statusDoor = 0
	if pulseDoor <= DOOR_MIN_POS then
		if work1 = 0  then
			statusDoor = DOOR_CLOSED
		else
			statusDoor = DOOR_OPENED
		endif
	elseif pulseDoor >= DOOR_MAX_POS then
		if work1 = 0  then
			statusDoor = DOOR_OPENED
		else
			statusDoor = DOOR_CLOSED
		endif
	endif
	return
	
; door(REAR) Open
door2Open:
	work1 = DOOR2_REVERSE;
	if work1 = 0  then
		pulseDoor2 = DOOR2_MAX_POS
	else
		pulseDoor2 = DOOR2_MIN_POS
	endif
	return
; doo(REAR) Close
door2Close:
	work1 = DOOR2_REVERSE;
	if work1 = 0  then
		pulseDoor2 = DOOR2_MIN_POS
	else
		pulseDoor2 = DOOR2_MAX_POS
	endif
	return
			
; door(REAR) closing calculation for pulse	
door2ClosingCalculation:
	work1 = DOOR2_REVERSE;
	if work1 = 0  then
		gosub door2PulseDecrement
	else
		gosub door2PulseIncrement
		
	endif
	return	
; door(REAR) opening calculation for pulse	
door2OpeningCalculation:
	work1 = DOOR2_REVERSE;
	if work1 = 0  then
		gosub door2PulseIncrement
	else 
		gosub door2PulseDecrement
	endif
	return
; door(REAR) pulse decrement for open/close
door2PulseDecrement:
	if pulseDoor2 > DOOR2_MIN_POS then ; if not close door
		let pulseDoor2 = pulseDoor2 - DOOR2_PLUSE_INCREMENT ; door(REAR) pulse descriment
	endif
	return
; door(REAR) pulse increment for open/close
door2PulseIncrement:
	if pulseDoor2 < DOOR2_MAX_POS then
		pulseDoor2 = pulseDoor2 + DOOR2_PLUSE_INCREMENT ; door(REAR) pulse increment
	endif
	return
; door(REAR) open/close check
; resut -> statusDoor
door2OpenedClosedCheck:
	work1 = DOOR2_REVERSE;
	statusDoor = 0
	if pulseDoor2 <= DOOR2_MIN_POS then
		if work1 = 0  then
			statusDoor = DOOR_CLOSED
		else
			statusDoor = DOOR_OPENED
		endif
	elseif pulseDoor2 >= DOOR2_MAX_POS then
		if work1 = 0  then
			statusDoor = DOOR_OPENED
		else
			statusDoor = DOOR_CLOSED
		endif
	endif
	return
	
; up gear out
gearUp:
	gosub ledOff ; led off
	work1 = GEAR_REVERSE;
	if work1 = 0  then
		pulseGear = GEAR_MIN_POS
	else 
		pulseGear = GEAR_MAX_POS
	endif
	return
	
; down gear out
gearDown:
	countGearDown = countGearDown + 1; inrement count of gear down
	gosub ledOn ; led ON
	work1 = GEAR_REVERSE;
	if work1 = 0 then
		pulseGear = GEAR_MAX_POS
	else
		pulseGear = GEAR_MIN_POS
	endif
	return
; Check status and chattering for Transmitter Gear switch up/down
; result-> upDownGearSwitch
checkSwitchGear:
	work1 = 0
	work2 = 0
	; move to previouse pulse 
	pulseSwithPrvPrv = pulseSwithPrv
	pulseSwithPrv = pulseSwith
	; pulse input from Tranmitter gear s/w
	pulsin SW_PIN,1,pulseSwith
	; calculater for check chattering
	if pulseSwithPrvPrv < pulseSwithPrv then 
		work2 = pulseSwithPrv - pulseSwithPrvPrv 
	else 
		work2 = pulseSwithPrvPrv - pulseSwithPrv 
	endif
	if pulseSwithPrv < pulseSwith then 
		work1 = pulseSwith - pulseSwithPrvPrv 
	else 
		work1 = pulseSwithPrvPrv - pulseSwith 
	endif
	work2 = work2 + work1
	; check chattering
	if work2 < 10 then
		if pulseSwith < SERVO_NEUTRAL_POS then
			upDownGearSwitch = GEAR_SW_UP
		elseif pulseSwith > GEAR_MIN_POS then 
			upDownGearSwitch = GEAR_SW_DOWN	
		endif
	endif
	return