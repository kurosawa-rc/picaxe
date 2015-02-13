;
; RC Gear door seaquencer for PICAXE 08M2
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

Setfreq M32

; Pins
symbol DOOR_PIN = 1 ; gear door pulse out
symbol GEAR_PIN = 2 ; gear pulse out
symbol SW_PIN = 3 ; Gear switch pulse input 
symbol LED_PIN = 4 ; LED on/offout
;
; Vaiables & Constant
;
; reverse
symbol GEAR_REVERSE = 0 ; 1: reverse 0;non
symbol DOOR_REVERSE = 0 ; 1: reverse 0;non

; LED for Landing light
symbol isOnLED = w1
	symbol LED_OFF = 0
	symbol LED_ON = 1
; Gear switch
symbol pulseSwith = w2 
symbol pulseSwithPrv = w3 
symbol pulseSwithPrvPrv = w4 

; Current gear pulse
symbol pulseGear = w5
	symbol GEAR_MAX_POS = 1524; down
	symbol GEAR_MIN_POS = 882; up
	symbol SERVO_NEUTRAL_POS = 1203; 146
	
; Current door pulse
symbol pulseDoor = w6
	symbol DOOR_MAX_POS =  1660; 2.1ms
	symbol DOOR_MIN_POS =  666; 0.8ms

; Transmitter gear up/down
symbol upDownGearSwitch = w7;
	symbol GEAR_SW_UP = 1 ;  UP
	symbol GEAR_SW_DOWN = 2 ; DOWN

; Gear status
symbol statusGear = w8 
	symbol ST_GEAR_DOWN = 1 ; gear down complete
	symbol ST_GEAR_UPING = 2 ; gear doing up(wait for start of door close) 
	symbol ST_GEAR_DOOR_CLOSING = 3 ; door closing
	symbol ST_GEAR_UP = 9 ; gear up and door close complete  
	symbol ST_GEAR_DOOR_OPENING = 8 ; door openinig
	symbol ST_GEAR_DOOR_OPEN = 7 ; door open complete
 
 ; Gear door close wait count from gear down out to start door close
 symbol countWaitCloseDoor = w9 
	symbol DOOR_CLOSE_WAIT = 2000 ; msec wait for from output gear up to start of door close
	symbol DOOR_PLUSE_INCREMENT = 12 ; incriment next pulse out for door open/close speed
	
; result check door open by 'gosub doorOpenCloseCheck'
symbol statusDoor = w10 
	symbol DOOR_CLOSED = 1
	symbol DOOR_OPENED = 2

; work
symbol work1 = w11
symbol work2 = w12

; intial 
init:
	; init variables
	pulseGear = 0
	pulseDoor = 0
	statusGear = 0
	pulseSwithPrv = 0
	pulseSwithPrvPrv = 0
	gosub ledInit
	
'main loop
main:

	gosub checkSwitchGear ; check gear switch
	if pulseGear > 0 then 
		pulsout GEAR_PIN, pulseGear
	endif
	if pulseDoor > 0 then
		pulsout DOOR_PIN, pulseDoor
	endif

	; init
	if statusGear =  0 then
		gosub calCountGearDoorClose ; calculate count of gear door  close for wait
		if  upDownGearSwitch = GEAR_SW_UP then
			gosub doorOpen ; door OPEN
			gosub gearUp ; gear UP
			statusGear = ST_GEAR_UPING ;
		elseif upDownGearSwitch = GEAR_SW_DOWN then
			gosub doorOpen ; door Open
			gosub gearDown ; gear DOWN
			statusGear = ST_GEAR_DOWN ;
		endif
	; gear down complete
	elseif statusGear = ST_GEAR_DOWN then 
		if  upDownGearSwitch = GEAR_SW_UP then
			gosub gearUp ; gear UP out
			statusGear = ST_GEAR_UPING ; gear doing up(wait for start of door close) 
			gosub calCountGearDoorClose ; calculate count of gear door  close for wait
		endif
		
	 ; gear doing up(wait for start of door close) 
	elseif statusGear = ST_GEAR_UPING then
		if  upDownGearSwitch = GEAR_SW_UP then
			; GEAR_SW_UP
			gosub doorCloseStartDecrimentCount ;decriment count of gear door close start wait
			if countWaitCloseDoor  <= 0 then ; if time up gear door close wait
				statusGear = ST_GEAR_DOOR_CLOSING ; start door close
			endif
		elseif upDownGearSwitch = GEAR_SW_DOWN then
			;  GEAR_SW_DOWN( canceled gear up)
			statusGear = ST_GEAR_DOOR_OPENING  ; door openinig
		endif

	; door closing
	elseif statusGear = ST_GEAR_DOOR_CLOSING then 
		if  upDownGearSwitch = GEAR_SW_UP then
			gosub doorClosingCalculation
			gosub doorOpenedClosedCheck
			if statusDoor = DOOR_CLOSED then ; if door closed
				statusGear = ST_GEAR_UP ; gear up and door close complete  
			endif
		elseif  upDownGearSwitch = GEAR_SW_DOWN then
			; GEAR_SW_DOWN( canceled gear up)
			statusGear = ST_GEAR_DOOR_OPENING  ; door openinig
		endif
		
	; gear up and door close complete  
	elseif statusGear = ST_GEAR_UP then 
		if  upDownGearSwitch = GEAR_SW_DOWN then
			statusGear = ST_GEAR_DOOR_OPENING
		endif
		
	; door openinig
	elseif statusGear = ST_GEAR_DOOR_OPENING then 
		if  upDownGearSwitch = GEAR_SW_DOWN then
			gosub doorOpeningCalculation
			gosub doorOpenedClosedCheck
			if statusDoor = DOOR_OPENED then ; if door opened
				statusGear = ST_GEAR_DOOR_OPEN ; gear down complete
			endif
		elseif upDownGearSwitch = GEAR_SW_UP then
		; GEAR_SW_UP( canceled gear down )
			statusGear = ST_GEAR_DOOR_CLOSING
		endif
		
	; door open complete
	elseif statusGear = ST_GEAR_DOOR_OPEN then 
		if  upDownGearSwitch = GEAR_SW_DOWN then
			gosub gearDown ; gear down out
			statusGear = ST_GEAR_DOWN ; gear down complete
		elseif upDownGearSwitch = GEAR_SW_UP then
			; GEAR_SW_UP( canceled gear down )
			statusGear = ST_GEAR_DOOR_CLOSING
		endif
	endif

	goto main
	
; init LED
ledInit:
	low LED_PIN
	isOnLED = LED_OFF
	return	
;LED on
ledOn:
	if isOnLED = LED_OFF then
		high LED_PIN
		isOnLED = LED_ON
	endif
	return
; LED off
ledOff:
	if isOnLED = LED_ON then
		low LED_PIN
		isOnLED = LED_OFF
	endif
	return
; calculate count of gear door close wait
calCountGearDoorClose:
	let countWaitCloseDoor = DOOR_CLOSE_WAIT / 20
	return

; decriment count of gear door close start wait
doorCloseStartDecrimentCount:
	let countWaitCloseDoor = countWaitCloseDoor -1;
	return
; door Open
doorOpen:
	work1 = DOOR_REVERSE;
	if work1 = 0  then
		pulseDoor = DOOR_MAX_POS
	else
		pulseDoor = DOOR_MIN_POS
	endif
	return
; door Close
doorClose:
	work1 = DOOR_REVERSE;
	if work1 = 0  then
		pulseDoor = DOOR_MIN_POS
	else
		pulseDoor = DOOR_MAX_POS
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
	return	
; door opening calculation for pulse	
doorOpeningCalculation:
	work1 = DOOR_REVERSE;
	if work1 = 0  then
		gosub doorPulseIncrement
	else 
		gosub doorPulseDecrement
	endif
	return
; door pulse decrement for open/close
doorPulseDecrement:
	if pulseDoor > DOOR_MIN_POS then ; if not close door
		let pulseDoor = pulseDoor - DOOR_PLUSE_INCREMENT ; door pulse descriment
	endif
	return
; door pulse increment for open/close
doorPulseIncrement:
	if pulseDoor < DOOR_MAX_POS then
		pulseDoor = pulseDoor + DOOR_PLUSE_INCREMENT ; door pulse increment
	endif
	return
; door open/close check
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
	gosub ledOn ; led ON
	work1 = GEAR_REVERSE;
	if work1 = 0 then
		pulseGear = GEAR_MAX_POS
	else
		pulseGear = GEAR_MIN_POS
	endif
	return
; Check for Transmitter Gear up/down
checkSwitchGear:
	work1 = 0
	work2 = 0
	; move to previouse pulse 
	pulseSwithPrvPrv = pulseSwithPrv
	pulseSwithPrv = pulseSwith
	; pulse input from gear s/w
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