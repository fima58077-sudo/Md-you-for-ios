TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MaterialYouKit

MaterialYouKit_FILES = Tweak.x
MaterialYouKit_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
MaterialYouKit_FRAMEWORKS = UIKit QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk
