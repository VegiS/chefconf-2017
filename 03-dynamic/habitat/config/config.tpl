#
# This file is here due to an oversight in Habitat. Habitat only restarts a
# running service if there is a configuration file. Our service does not use a
# configuration file, so we have a "fake" one here to force-restart the service
# on configuration change.
#
# See https://github.com/habitat-sh/habitat/issues/2448 for more information.
#

{{cfg.text}}
{{cfg.port}}
