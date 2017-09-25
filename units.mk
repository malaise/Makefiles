# This makefile is standalone because it might be included by
#  the client makefile in order to define units before including
#  ada.mk
ALLUNITS := $(subst -,.,$(sort $(basename $(wildcard *.ads *.adb *.aps *.apb))))

