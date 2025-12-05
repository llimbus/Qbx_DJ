-- ============================================
-- FiveM DJ System - Configuration
-- ============================================

Config = {}

-- ============================================
-- GENERAL SETTINGS
-- ============================================

-- Enable debug mode (prints to console)
Config.Debug = false

-- Default BPM for beat system
Config.DefaultBPM = 128

-- Maximum audio distance (in meters)
Config.MaxAudioDistance = 100.0

-- Volume falloff curve (1.0 = linear, 2.0 = quadratic)
Config.VolumeFalloff = 1.5

-- ============================================
-- PERMISSIONS
-- ============================================

-- Enable permission system
Config.UsePermissions = false

-- Allowed player identifiers (if UsePermissions = true)
Config.AllowedPlayers = {
    -- 'steam:110000xxxxxxxx',
    -- 'license:xxxxxxxxxxxxxxxx',
    -- 'discord:123456789012345678'
}

-- ACE Permission name (if using ACE)
Config.AcePermission = 'dj.use'

-- ============================================
-- COMMANDS
-- ============================================

-- Command to open DJ console
Config.CommandDJ = 'dj'

-- Command to open Stage Builder
Config.CommandBuilder = 'djbuilder'

-- Command to check beat system
Config.CommandBeatCheck = 'djbeatcheck'

-- Command to show beat info
Config.CommandBeatInfo = 'djbeatinfo'

-- Command to test beat system
Config.CommandBeatTest = 'djbeattest'

-- Command to fix UI
Config.CommandFix = 'djfix'

-- ============================================
-- KEYBINDS
-- ============================================

-- Key to open Stage Builder (F6 = 167)
Config.BuilderKey = 167

-- Enable hotkeys (F5-F12)
Config.EnableHotkeys = false

-- Hotkey configuration
Config.Hotkeys = {
    -- F5 = Play/Pause Deck A
    [166] = 'deck_a_play',
    -- F6 = Play/Pause Deck B
    [167] = 'deck_b_play',
    -- F7 = Stop All
    [168] = 'stop_all',
    -- F8 = Next Track (Playlist)
    [169] = 'next_track',
    -- F9 = Shuffle Toggle
    [170] = 'shuffle_toggle',
    -- F10 = Repeat Toggle
    [171] = 'repeat_toggle',
}

-- ============================================
-- ZONES
-- ============================================

-- Pre-configured DJ zones
Config.Zones = {
    {
        name = "Vanilla Unicorn",
        coords = vector3(120.0, -1280.0, 29.0),
        radius = 50.0,
        blip = {
            enabled = true,
            sprite = 136,
            color = 27,
            scale = 0.8
        }
    },
    {
        name = "Bahama Mamas",
        coords = vector3(-1387.0, -618.0, 30.0),
        radius = 50.0,
        blip = {
            enabled = true,
            sprite = 136,
            color = 27,
            scale = 0.8
        }
    },
    -- Add more zones here
}

-- ============================================
-- PROPS
-- ============================================

-- Maximum props per player
Config.MaxPropsPerPlayer = 50

-- Prop placement distance
Config.PropPlacementDistance = 5.0

-- Prop rotation speed (degrees per frame)
Config.PropRotationSpeed = 2.0

-- Enable prop collision
Config.PropCollision = true

-- Freeze props after placement
Config.FreezeProps = true

-- ============================================
-- EFFECTS
-- ============================================

-- Maximum effects per prop
Config.MaxEffectsPerProp = 5

-- Effect intensity multiplier
Config.EffectIntensityMultiplier = 3.0

-- Effect sync with music
Config.EffectSyncEnabled = true

-- Effect update rate (ms)
Config.EffectUpdateRate = 100

-- ============================================
-- AUDIO
-- ============================================

-- Default volume (0.0 - 1.0)
Config.DefaultVolume = 0.8

-- Maximum volume (0.0 - 1.0)
Config.MaxVolume = 1.0

-- Enable 3D audio
Config.Enable3DAudio = true

-- Audio update rate (ms)
Config.AudioUpdateRate = 100

-- ============================================
-- PLAYLIST
-- ============================================

-- Enable playlist system
Config.EnablePlaylist = true

-- Maximum tracks per playlist
Config.MaxTracksPerPlaylist = 100

-- Auto-play next track
Config.AutoPlayNext = true

-- Default shuffle mode
Config.DefaultShuffle = false

-- Default repeat mode
Config.DefaultRepeat = false

-- ============================================
-- UI
-- ============================================

-- UI Scale (0.5 - 2.0)
Config.UIScale = 1.0

-- UI Theme ('dark' or 'light')
Config.UITheme = 'dark'

-- Show notifications
Config.ShowNotifications = true

-- Notification duration (ms)
Config.NotificationDuration = 3000

-- ============================================
-- TARGET SYSTEM
-- ============================================

-- Target system priority: 'ox_target', 'qb-target', 'auto', 'none'
Config.TargetSystem = 'auto'

-- Target distance
Config.TargetDistance = 2.5

-- Target icon
Config.TargetIcon = 'fas fa-music'

-- ============================================
-- PERFORMANCE
-- ============================================

-- Enable performance mode (reduces visual effects)
Config.PerformanceMode = false

-- Maximum render distance for effects
Config.EffectRenderDistance = 50.0

-- Reduce particle count in performance mode
Config.ReduceParticles = true

-- ============================================
-- LOGGING
-- ============================================

-- Enable logging
Config.EnableLogging = true

-- Log level: 'debug', 'info', 'warn', 'error'
Config.LogLevel = 'info'

-- Log to file
Config.LogToFile = false

-- Log file path
Config.LogFilePath = 'logs/dj-system.log'

-- ============================================
-- ADVANCED
-- ============================================

-- Enable experimental features
Config.ExperimentalFeatures = false

-- Beat detection sensitivity (0.5 - 2.0)
Config.BeatSensitivity = 1.0

-- Sync tolerance (ms)
Config.SyncTolerance = 50

-- Network update rate (ms)
Config.NetworkUpdateRate = 100

-- ============================================
-- LOCALIZATION
-- ============================================

-- Language: 'en', 'pt', 'es', 'fr', 'de'
Config.Language = 'pt'

-- Custom translations
Config.Translations = {
    en = {
        dj_console = 'DJ Console',
        stage_builder = 'Stage Builder',
        playlist = 'Playlist',
        no_permission = 'You do not have permission to use this!',
        prop_placed = 'Prop placed successfully!',
        prop_removed = 'Prop removed!',
        track_added = 'Track added to playlist!',
        playlist_saved = 'Playlist saved!',
        playlist_loaded = 'Playlist loaded!',
    },
    pt = {
        dj_console = 'Console DJ',
        stage_builder = 'Stage Builder',
        playlist = 'Playlist',
        no_permission = 'Você não tem permissão para usar isso!',
        prop_placed = 'Prop colocado com sucesso!',
        prop_removed = 'Prop removido!',
        track_added = 'Música adicionada à playlist!',
        playlist_saved = 'Playlist salva!',
        playlist_loaded = 'Playlist carregada!',
    }
}

-- ============================================
-- FUNCTIONS
-- ============================================

-- Get translation
function Config.GetTranslation(key)
    local lang = Config.Language
    if Config.Translations[lang] and Config.Translations[lang][key] then
        return Config.Translations[lang][key]
    end
    return key
end

-- Check permission
function Config.HasPermission(source)
    if not Config.UsePermissions then
        return true
    end
    
    -- Check ACE permission
    if IsPlayerAceAllowed(source, Config.AcePermission) then
        return true
    end
    
    -- Check allowed players list
    local identifiers = GetPlayerIdentifiers(source)
    for _, identifier in ipairs(identifiers) do
        for _, allowed in ipairs(Config.AllowedPlayers) do
            if identifier == allowed then
                return true
            end
        end
    end
    
    return false
end

-- Debug print
function Config.DebugPrint(...)
    if Config.Debug then
        print('[DJ System]', ...)
    end
end

return Config
