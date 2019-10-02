export ARCHS = armv7 arm64 arm64e
export TARGET = iphone:clang:latest:8.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ProductivityReminder
ProductivityReminder_FILES = Tweak.xm
ProductivityReminder_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += productivityreminder
include $(THEOS_MAKE_PATH)/aggregate.mk
