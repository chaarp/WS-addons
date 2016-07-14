local VERSION = "0.8.5"

local ThreatMeter = Apollo.GetPackage("DaiAddon-1.0").tPackage:NewAddon("ThreatMeter", true, {})
ThreatMeter.Version = VERSION

ThreatMeter.db = {
  nWarningSoundId             = 162,
  crNormalText                = "White",
  crPlayer                    = "xkcdLavender",
  crPlayerPet                 = "xkcdLightIndigo",
  crGroupMember               = "xkcdLightForestGreen",
  crNotPlayer                 = "xkcdScarlet",
  nTPSWindow                  = 10,
  fWarningThreshold           = 90,
  fWarningOpacity             = 100,
  fMainWindowOpacity          = 100,
  fArtWorkOpacity             = 100,
  bLockWarningWindow          = true,
  bLockMainWindow             = false,
  bShowWhenInGroup            = true,
  bShowWhenHavePet            = true,
  bShowWhenInRaid             = true,
  bShowWhenAlone              = false,
  bHideWhenNotInCombat        = false,
  bHideWarningWhenNotInCombat = true,
  bHideWhenInPvP              = true,
  bWarningUseSound            = true,
  bWarningUseMessage          = true,
  bWarningTankDisable         = true,
  bThreatTotalPrecision       = false,
}
