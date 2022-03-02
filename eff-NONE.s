;; NONE effect
;;
;; This effect is not entered into the "built-in effects"
;; table, but is instead used whenever an effect name
;; can't be found.
;;
;; Just silently collects
;; (and discards) input characters.

.macpack apple2

.export TE_NONE

.include "taki-effect.inc"
.include "a2-monitor.inc"
.include "taki-public.inc"
.include "taki-debug.inc"

.import TakiVarCommandBufferPage

TAKI_EFFECT "", 0, 0
TE_NONE:
	rts
