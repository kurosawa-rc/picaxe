;
; RC Gear door seaquencer with Power LED(1Wx2) Controler for PICAXE 14M2.
;		2022/04/17 ver 1.04 for SMD (production)
;
; 1-door left-open seaquencer in M346 rc e-Jets.
; and Power LED(1Wx2) controler.
;	becon light is strobe light while the power is on. 
; 	landing light is controled by transmiter light s/w. this light is off while gear up. 
;
; video of seaquencer:
; https://youtu.be/fWwQTgveKxI
;
; flight video:
; https://youtu.be/S9m3Q8LO02o

; M-346 64mm twin Red Color
; https://kurosawa.e-rc.jp/plane?pc=1266K9vmNodb4EagPwp
;
; Copyright (c) 2022 Hiroyuki Kurosawa
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
; Revision
;
;	2022/04/17 reverse gear s/w input
;	2021/10/02 add Power LED(1Wx2, becon and strobe light) control. and chip change to 12M2 from 08M2.
;       	     multi task for strobe light at running 4MHz.
;
;	2015/8/23 change gear door reverse ON(DOOR_REVERSE = 1) for FUTABA S3101
;	2015/8/9 change gear reverse ON(GEAR_REVERSE=1) for retract gear.
; 
;Variables - General information.
;
;08M2: 28 Bytes, bit Name:bit0-31, Byte Name: b0-27, Word Name:w0-13
;
;w0 =  b1 : b0
;w1 =  b3 : b2
;w2 =  b5 : b4
;w3 =  b7 : b6
;w4 =  b9 : b8
;w5 =  b11 : b10
;w6 =  b13 : b12
;w7 =  b15 : b14
;w8 =  b17 : b16
;w9 =  b19 : b18
;w10 = b21 : b20
;w11 = b22 : b23
;w12 = b24 : b25
;w13 = b26 : b27
;
;b0 =  bit7: bit6: bit5: bit4: bit3: bit2: bit1: bit0
;b1 =  bit15: bit14: bit13: bit12: bit11: bit10: bit9: bit8
;etc...
;
; see also, https://picaxe.com/docs/picaxe_manual2.pdf [Variables - General] section for other informations.
;
;
; Task0 For multitasking(), the Task0 runs at 4MHz. StartX(0->) is required fist line for multitasking.
;
start0:

;Setfreq M32
;Setfreq M16

; Pins for SMD
symbol DOOR_PIN = c.2 ; pulse out for gear door
symbol GEAR_PIN = c.1 ; pulse out for retract gear
symbol SW_PIN_GEAR = c.4 ; pulse input from Gear up/down switch in transmitter
symbol SW_PIN_LANDING_LIGHT = c.3 ; pulse input from Landing light on/off switch in transmitter  
symbol LED_PIN_LANDING_LIGHT = b.1 ; LED on/offout for Landind light controled by landing light s/w.
symbol LED_PIN_BECON_LIGHT = b.2 ; LED on/offout for becon light(strobe)
;
; Vaiables & Constant
;	
;
; reverse
symbol GEAR_REVERSE = 1 ; 1: reverse 0;non
symbol DOOR_REVERSE = 1 ; 1: reverse 0;non
symbol LANDING_LIGHT_REVERSE = 1; high or low to pin by light on/off 1:revese(low by on) 0:non(high by on), caution NOT input reverse.

;usage Byte Name: b0-27, Word Name:w0-13

; Light switch pulse input from RX
symbol lightPulseSwith = w0 
symbol lightPulseSwithPrv = w1 
symbol lightPulseSwithPrvPrv = w2 


; Gear switch pulse input from RX
symbol pulseSwith = w3 
symbol pulseSwithPrv = w4 
symbol pulseSwithPrvPrv = w5 

; Current gear pulse
symbol pulseGear = w6
	; 32MHz 1.25us unit
;	symbol GEAR_MAX_POS = 1524; down
;	symbol GEAR_MIN_POS = 882; up
;	symbol SERVO_NEUTRAL_POS = 1203;
	
	; 16MHz 2.50us unit	
;	symbol GEAR_MAX_POS = 762; down
;	symbol GEAR_MIN_POS = 441; up
;	symbol SERVO_NEUTRAL_POS = 601;
	
	; 4MHz 10us unit(for multi task)
	symbol GEAR_MAX_POS = 190; down
	symbol GEAR_MIN_POS = 110; up
	symbol SERVO_NEUTRAL_POS = 145; (190-110)/2=40 -> 110+40=150 -> 145(just 5 below from center pos due to If it is neutral, it may blink)   
	
; Current door pulse
symbol pulseDoor = w7
	; 32MHz 1.25us unit
;	symbol DOOR_MAX_POS =  1660; 2.1ms(1.25us x 1660 = 2.075ms)
;	symbol DOOR_MIN_POS =  666; 0.8ms(1.25us x 666 = 0.832ms)

	; 16MHz 2.50us unit
;	symbol DOOR_MAX_POS =  830; 2.1ms(2.50us x 830 = 2.075ms)
;	symbol DOOR_MIN_POS =  333; 0.8ms(2.50us x 333 = 0.832ms)

	; 4MHz 10us unit(for multi task)
	symbol DOOR_MAX_POS =  205; 2.1ms(10us x 210 - 5(adjust) = 2.1ms)
	symbol DOOR_MIN_POS =  78; 0.8ms(10us x 80 -2(adjust) = 0.8ms)
 
; Gear door close wait count from gear down out to start door close
symbol countWaitCloseDoor = w8 

 	; 32MHz
;	symbol DOOR_CLOSE_WAIT = 2000 ; msec wait for from output gear up to start of door close
;	symbol DOOR_PLUSE_INCREMENT = 12 ; incriment next pulse out for door open/close speed

	; 16MHz
;	symbol DOOR_PLUSE_INCREMENT = 8

	; 4MHz(for multi task)
	symbol DOOR_CLOSE_WAIT = 1000
	symbol DOOR_PLUSE_INCREMENT = 4
;	
;w9 =  b19 : b18
; Transmitter gear up/down
symbol upDownGearSwitch = b18;
	symbol GEAR_SW_UP = 1 ;  UP
	symbol GEAR_SW_DOWN = 2 ; DOWN

; Gear status
symbol statusGear = b19
	symbol ST_GEAR_DOWN = 1 ; gear down complete
	symbol ST_GEAR_UPING = 2 ; gear doing up(wait for start of door close) 
	symbol ST_GEAR_DOOR_CLOSING = 3 ; door closing
	symbol ST_GEAR_UP = 9 ; gear up and door close complete  
	symbol ST_GEAR_DOOR_OPENING = 8 ; door openinig
	symbol ST_GEAR_DOOR_OPEN = 7 ; door open complete	
	
;w10 = b21 : b20
; result check door open by 'gosub doorOpenCloseCheck'
symbol statusDoor = b20 
	symbol DOOR_CLOSED = 1
	symbol DOOR_OPENED = 2

; LED for Landing light isOnLED
symbol statusLandingLight = b21
	symbol LIGHT_OFF = 0
	symbol LIGHT_ON = 1

; work
symbol work1 = w11
symbol work2 = w12

; S/W input available status(1: use , 0:Not use)
symbol useSwitchGear = b26
	symbol PIN_USED = 1;
	symbol PIN_NOT_USED = 0;
	
symbol useSwitchLight = b27

; intial 
init:
	; init variables
	pulseGear = 0
	pulseDoor = 0
	statusGear = 0
	lightPulseSwith = 0
	lightPulseSwithPrv = 0 
	lightPulseSwithPrvPrv = 0 
	pulseSwith = 0
	pulseSwithPrv = 0
	pulseSwithPrvPrv = 0
	useSwitchGear = PIN_USED;
	useSwitchLight = PIN_USED;
	gosub initLandingLight ;initilize light led status
	

	pause 700
	gosub checkSwitchLandingLight
	w11 = lightPulseSwith;
	if w11 = 0 then
		useSwitchLight = PIN_NOT_USED
	endif
	
'main loop
main0:

	gosub checkSwitchLandingLight; check Landing light switch
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

	goto main0
	
; init Landing light
initLandingLight:
	gosub landingLightLowPin; LOW to pin
	statusLandingLight = LIGHT_OFF
	return
		
; landing light ON
landingLightOn:
	if statusLandingLight = LIGHT_OFF then
		if statusGear = ST_GEAR_DOWN then
			gosub landingLightHighPin; High(=light ON) to pin
		endif
		statusLandingLight = LIGHT_ON
	endif
	return
	
; landing light OFF
landingLightOff:
	if statusLandingLight = LIGHT_ON then
		if statusGear = ST_GEAR_DOWN then
			gosub landingLightLowPin; Low(=light OFF) to pin
		endif
		statusLandingLight = LIGHT_OFF
	endif
	return
	
; landing light HIGH to pin
landingLightHighPin:
	work1 = LANDING_LIGHT_REVERSE
	if work1 = 1 then
		low LED_PIN_LANDING_LIGHT
	else
		high LED_PIN_LANDING_LIGHT
	endif
	return
	
; landing light LOW to pin
landingLightLowPin:
	work1 = LANDING_LIGHT_REVERSE
	if work1 = 1 then
		high LED_PIN_LANDING_LIGHT
	else
		low LED_PIN_LANDING_LIGHT
	endif
	return
	
; gear up (star) light off
gearUpLightOff:
	if statusLandingLight = LIGHT_ON then
		gosub landingLightLowPin; Low(=light OFF) to pin
	endif
	return

; gear up completed light ON
gearDownLightOn:
	if statusLandingLight = LIGHT_ON then
		gosub landingLightHighPin; High(=light ON) to pin
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
	gosub gearUpLightOff
	work1 = GEAR_REVERSE;
	if work1 = 0  then
		pulseGear = GEAR_MIN_POS
	else 
		pulseGear = GEAR_MAX_POS
	endif
	return
	
; down gear out
gearDown:
	gosub gearDownLightOn
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
	pulsin SW_PIN_GEAR,1,pulseSwith
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
			upDownGearSwitch = GEAR_SW_DOWN
		elseif pulseSwith > GEAR_MIN_POS then 
			upDownGearSwitch = GEAR_SW_UP	
		endif
	endif
	return
	
; Check for Transmitter Landing ligth On/Off
checkSwitchLandingLight:
	if useSwitchLight = PIN_USED then
		work1 = 0
		work2 = 0
		; move to previouse pulse 
		lightPulseSwithPrvPrv = lightPulseSwithPrv
		lightPulseSwithPrv = lightPulseSwith
		; pulse input from gear s/w
		pulsin SW_PIN_LANDING_LIGHT,1,lightPulseSwith
		; calculater for check chattering
		if lightPulseSwithPrvPrv < lightPulseSwithPrv then 
			work2 = lightPulseSwithPrv - lightPulseSwithPrvPrv 
		else 
			work2 = lightPulseSwithPrvPrv - lightPulseSwithPrv 
		endif
		if lightPulseSwithPrv < lightPulseSwith then 
			work1 = lightPulseSwith - lightPulseSwithPrvPrv 
		else 
			work1 = lightPulseSwithPrvPrv - lightPulseSwith 
		endif
		work2 = work2 + work1
		; check chattering
		if work2 < 10 then
			;if lightPulseSwith = 0 then
			;	useSwitchLight = PIN_NOT_USED
			;else
				if lightPulseSwith < SERVO_NEUTRAL_POS then
					gosub landingLightOff
				elseif lightPulseSwith > GEAR_MIN_POS then 
					gosub landingLightOn
				endif
			;endif
		endif
	endif
	return
;
; Task 1 for Becon(strobe) blinking ligth control.
;
start1:

main1:	
	high LED_PIN_BECON_LIGHT
	pause 1500
	low LED_PIN_BECON_LIGHT
	pause 30
	goto main1
	
