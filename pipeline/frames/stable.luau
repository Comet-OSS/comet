--!nolint
--!nocheck
--!optimize 2
--!native

--[[
    @link https://github.com/biggaboy212/Comet
    @author biggaboy212
    @repository Comet

    @generatedAt __COMPOSER.Insert(__COMPOSER.genDate)
    @target __COMPOSER.Insert(__COMPOSER.cfg)
    @tag __COMPOSER.Insert(__COMPOSER.vers)

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
