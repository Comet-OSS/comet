--!nolint
--!nocheck
--!optimize 2
--!native

--[[
    @link https://github.com/Comet-OSS/Comet
    @author Comet-OSS
    @repository Comet
    @license MIT

    Copyright © 2026 Comet-OSS, MIT license.
    This file was automatically @generated with ProCMP, it is not intended for manual editing.
--]]

_P = {
	shared = {},
    
	generatedAt = __COMPOSER.Insert(__COMPOSER.genDate),
    prerelease = __COMPOSER.Insert(__COMPOSER.prerelease),
	target = __COMPOSER.Insert(__COMPOSER.cfg),
    variant = __COMPOSER.Insert(__COMPOSER.variant),
	tag = __COMPOSER.Insert(__COMPOSER.vers),
    outAt = __COMPOSER.Insert(__COMPOSER.output),
}

if not game:IsLoaded() then
	game.Loaded:Wait()
end

__COMPOSER.Insert(__COMPOSER.build)
