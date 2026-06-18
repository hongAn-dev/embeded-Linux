################################################################################
#
# miniguard-dashboard
#
################################################################################

MINIGUARD_DASHBOARD_VERSION = 1.0
MINIGUARD_DASHBOARD_SITE = $(BR2_EXTERNAL_MINIGUARD_PATH)/src/miniguard-dashboard
MINIGUARD_DASHBOARD_SITE_METHOD = local

define MINIGUARD_DASHBOARD_INSTALL_TARGET_CMDS
	# Install CGI scripts
	$(INSTALL) -d $(TARGET_DIR)/usr/share/miniguard/cgi-bin
	$(INSTALL) -m 0755 $(@D)/cgi-bin/system.sh   $(TARGET_DIR)/usr/share/miniguard/cgi-bin/
	$(INSTALL) -m 0755 $(@D)/cgi-bin/network.sh  $(TARGET_DIR)/usr/share/miniguard/cgi-bin/
	$(INSTALL) -m 0755 $(@D)/cgi-bin/security.sh $(TARGET_DIR)/usr/share/miniguard/cgi-bin/

	# Install HTML files
	$(INSTALL) -d $(TARGET_DIR)/usr/share/miniguard/html
	$(INSTALL) -m 0644 $(@D)/html/index.html $(TARGET_DIR)/usr/share/miniguard/html/

	# Install init script
	$(INSTALL) -d $(TARGET_DIR)/etc/init.d
	$(INSTALL) -m 0755 $(@D)/S50dashboard $(TARGET_DIR)/etc/init.d/
endef

$(eval $(generic-package))
