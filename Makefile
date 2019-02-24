include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BetterHUD
BetterHUD_FILES = $(wildcard *.xm)
BetterHUD_FRAMEWORKS = UIKit
BetterHUD_PRIVATE_FRAMEWORKS = MediaRemote
BetterHUD_CFLAGS = -fobjc-arc


include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += betterhudprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
