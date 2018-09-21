; Lesson 9
;
; Posted on iamsensoria.com
; Purpose learn about a few command appling what we learned so far
; Workflow: The binary loads and wait for the user to click on the LEFT mouse button

; TIPS:
; On line 15 NO SPACE after the comma or you will get an error by vasm
; Each line, besides the label have at least one space, that will help Sublime to applying the color scheme that improves readability

; Loop is a label, kind of a go to in the old basic
loop:

; test if address has the value 6.
 btst #6,$bfe001

; if not, then sux to be you program. Go back to loop and keep repeating this logic
 bne loop

; condition met (mouse button pressed) exit (return to subroutine)
 rts