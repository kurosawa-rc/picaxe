;
; Tester proguram for Gear door sequenser with Power LED
; 
; gear s/w on/off the out pulse on(1msec)/off(2msec) for receiver input GEAR in gear door sequenser
; light s/w on/off the out pulse on(1msec)/off(2msec) for receiver input LIGHT in gear door sequenser
;
; version 0.92 2022/02/09 kurosawa
;
;	0.92 reverse output pluse
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
#Picaxe 08M2
#No_Data

; Pins
symbol GEAR_OUT_PIN = 1 ; Gear pulse out 
symbol LIGTH_OUT_PIN = 2 ; light pulseout

symbol LIGHT_SW_PIN = pin3 ; light s/w in
symbol GEAR_SW_PIN = pin4 ; gear s/w in

;gear pulse out value
symbol pulseGear = w0
	symbol GEAR_MAX_POS = 200; 2msec pulse
	symbol GEAR_MIN_POS = 100; 1msec pulse
	
;light pulse out value
symbol pulseLight = w1

; intial 
init:

	; init variables
	pulseGear = GEAR_MIN_POS
	servo GEAR_OUT_PIN,pulseGear
	
	pulseLight = GEAR_MIN_POS
	servo LIGTH_OUT_PIN,pulseLight
	
'main loop
main:

	; gear s/w ON ?  
	if GEAR_SW_PIN = 0  then
		if pulseGear <> GEAR_MAX_POS then
			pulseGear = GEAR_MAX_POS
			servopos GEAR_OUT_PIN,pulseGear	
		endif
	else
		; gear s/w OFF
		if pulseGear <> GEAR_MIN_POS then
			pulseGear = GEAR_MIN_POS
			servopos GEAR_OUT_PIN,pulseGear
		endif
	endif
	
	; light s/w ON ?
	if LIGHT_SW_PIN = 0  then
		if pulseLight <> GEAR_MIN_POS then
			pulseLight = GEAR_MIN_POS
			servopos LIGTH_OUT_PIN,pulseLight
		endif
	else
		; light s/w OFF
		if pulseLight <> GEAR_MAX_POS then
			pulseLight = GEAR_MAX_POS
			servopos LIGTH_OUT_PIN,pulseLight
		endif
	endif
	
goto main
