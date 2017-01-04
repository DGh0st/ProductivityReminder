export ARCHS = armv7 arm64
export TARGET = iphone:clang:latest:latest

PACKAGE_VERSION = 0.0.2

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ProductivityReminder
ProductivityReminder_FILES = Tweak.xm
ProductivityReminder_FRAMEWORKS = UIKit
ProductivityReminder_LDFlags += -Wl,-segalign,4000

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += productivityreminder
include $(THEOS_MAKE_PATH)/aggregate.mk
