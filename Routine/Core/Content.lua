local addonName, ns = ...
local MR = ns.MR
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

MR.tracker:InstallContent(MR, { namespace = ns, labels = L })
