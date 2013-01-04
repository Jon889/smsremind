export ARCHS=armv7
export TARGET=iphone:latest:4.3
TARGET_CC=clang
TARGET_CXX=clang
GO_EASY_ON_ME=1
THEOS_BUILD_DIR = build

include theos/makefiles/common.mk

TWEAK_NAME = SMSRemind
SMSRemind_FILES = Tweak.xm
SMSRemind_FRAMEWORKS = UIKit EventKit

include $(THEOS_MAKE_PATH)/tweak.mk
