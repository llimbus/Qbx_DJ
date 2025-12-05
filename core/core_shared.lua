-- ============================================
-- QBXDJ - CORE SHARED MODULE
-- ============================================
-- Variáveis globais e constantes compartilhadas
-- DEVE ser carregado PRIMEIRO
-- ============================================
-- Data de Criação: 05/12/2025
-- Versão: 2.0.0
-- Autor: llimbus
-- ============================================

print("[DJ Core] Loading shared module...")

-- ============================================
-- SISTEMA PRINCIPAL
-- ============================================

DJSystem = {}
DJSystem.Version = "1.0.0"
DJSystem.Name = "Qbx_DJ System"
DJSystem.Author = "llimbus"
DJSystem.Ready = false

-- ============================================
-- VARIÁVEIS GLOBAIS DE ESTADO
-- ============================================

-- Estado da música e batidas
DJSystem.MusicBeat = {
    bpm = 128,
    beat = 0,
    intensity = 0.5,
    lastBeatTime = 0,
    isPlaying = false
}

-- Efeitos ativos por entidade
-- Estrutura: DJSystem.ActiveEffects[entity] = { effects = { [effectId] = { config = config } } }
DJSystem.ActiveEffects = {}

-- Zonas de áudio
-- Estrutura: DJSystem.AudioZones[zoneId] = { djTable = entity, speakers = {}, effects = {} }
DJSystem.AudioZones = {}

-- Props spawnados
-- Estrutura: DJSystem.SpawnedProps[entity] = { model = model, coords = coords, heading = heading }
DJSystem.SpawnedProps = {}

-- Estado da UI
DJSystem.UI = {
    isOpen = false,
    mode = nil, -- 'dj', 'builder', 'playlist'
    currentZone = nil
}

-- Estado de colocação
DJSystem.Placement = {
    active = false,
    model = nil,
    ghostEntity = nil,
    coords = nil,
    heading = 0.0
}

-- Playlist atual
DJSystem.Playlist = {
    name = "My Playlist",
    tracks = {},
    currentIndex = 0,
    shuffle = false,
    repeat = false
}

-- ============================================
-- CONSTANTES
-- ============================================

DJSystem.Constants = {
    -- Limites
    MAX_PROPS_PER_PLAYER = 50,
    MAX_EFFECTS_PER_PROP = 5,
    MAX_TRACKS_PER_PLAYLIST = 100,
    MAX_AUDIO_DISTANCE = 100.0,
    
    -- Tempos (ms)
    BEAT_WINDOW = 150,
    EFFECT_UPDATE_RATE = 100,
    AUDIO_UPDATE_RATE = 100,
    NETWORK_UPDATE_RATE = 100,
    
    -- Distâncias
    PROP_PLACEMENT_DISTANCE = 5.0,
    TARGET_DISTANCE = 2.5,
    EFFECT_RENDER_DISTANCE = 50.0,
    
    -- Multiplicadores
    EFFECT_INTENSITY_MULTIPLIER = 3.0,
    VOLUME_FALLOFF = 1.5,
    
    -- BPM
    MIN_BPM = 60,
    MAX_BPM = 180,
    DEFAULT_BPM = 128,
    
    -- Volume
    MIN_VOLUME = 0.0,
    MAX_VOLUME = 1.0,
    DEFAULT_VOLUME = 0.8
}

-- ============================================
-- TIPOS DE PROPS
-- ============================================

DJSystem.PropTypes = {
    DJ_TABLE = 'dj_table',
    SPEAKER = 'speaker',
    EFFECT = 'effect',
    DECORATION = 'decoration'
}

-- ============================================
-- TIPOS DE EFEITOS
-- ============================================

DJSystem.EffectTypes = {
    LIGHTS = 'lights',
    LASERS = 'lasers',
    SMOKE = 'smoke',
    CONFETTI = 'confetti',
    BUBBLES = 'bubbles',
    PYRO = 'pyro',
    CO2 = 'co2',
    UV = 'uv',
    FIREWORK = 'firework',
    NONE = 'none'
}

-- ============================================
-- MODELOS DE PROPS NATIVOS
-- ============================================

DJSystem.PropModels = {
    -- DJ Equipment
    DJ_DECK = 'prop_dj_deck_01',
    SPEAKER_LARGE = 'prop_speaker_06',
    SPEAKER_MEDIUM = 'prop_speaker_05',
    SUBWOOFER = 'prop_speaker_08',
    
    -- Stage Lights
    SPOTLIGHT = 'prop_spot_01',
    WORK_LIGHT = 'prop_worklight_03b',
    STROBE_LIGHT = 'prop_worklight_04c',
    LED_SCREEN = 'prop_tv_flat_01',
    
    -- Effects Equipment
    SMOKE_MACHINE = 'prop_air_bigradar',
    CO2_JET = 'prop_air_towbar_01',
    FOG_MACHINE = 'prop_air_bigradar_l2',
    
    -- Bar & Furniture
    BAR_STOOL = 'prop_bar_stool_01',
    BEER_TAP = 'prop_bar_pump_06',
    TABLE_ROUND = 'prop_table_03',
    TABLE_SQUARE = 'prop_table_04',
    TABLE_VIP = 'prop_table_06',
    
    -- Decoration
    BARRIER = 'prop_barrier_work05',
    FIRE_PIT = 'prop_beach_fire',
    TV_LARGE = 'prop_tv_flat_michael',
    NEON_LIGHT = 'prop_neon_01'
}

-- ============================================
-- FUNÇÕES DO SISTEMA
-- ============================================

-- Inicializar sistema
function DJSystem.Init()
    print(string.format("[DJ Core] Initializing %s v%s", DJSystem.Name, DJSystem.Version))
    print(string.format("[DJ Core] Author: %s", DJSystem.Author))
    
    -- Carregar configurações
    if Config then
        print("[DJ Core] Config loaded successfully")
    else
        print("[DJ Core] ⚠️ WARNING: Config not found, using defaults")
    end
    
    DJSystem.Ready = true
    print("[DJ Core] ✓ System initialized successfully")
    
    return true
end

-- Obter versão
function DJSystem.GetVersion()
    return DJSystem.Version
end

-- Verificar se está pronto
function DJSystem.IsReady()
    return DJSystem.Ready
end

-- Obter informações do sistema
function DJSystem.GetInfo()
    return {
        name = DJSystem.Name,
        version = DJSystem.Version,
        author = DJSystem.Author,
        ready = DJSystem.Ready
    }
end

-- Reset do sistema (para debug)
function DJSystem.Reset()
    print("[DJ Core] Resetting system...")
    
    DJSystem.MusicBeat = {
        bpm = 128,
        beat = 0,
        intensity = 0.5,
        lastBeatTime = 0,
        isPlaying = false
    }
    
    DJSystem.ActiveEffects = {}
    DJSystem.AudioZones = {}
    DJSystem.SpawnedProps = {}
    
    DJSystem.UI = {
        isOpen = false,
        mode = nil,
        currentZone = nil
    }
    
    DJSystem.Placement = {
        active = false,
        model = nil,
        ghostEntity = nil,
        coords = nil,
        heading = 0.0
    }
    
    DJSystem.Playlist = {
        name = "My Playlist",
        tracks = {},
        currentIndex = 0,
        shuffle = false,
        repeat = false
    }
    
    print("[DJ Core] ✓ System reset complete")
end

-- ============================================
-- ALIASES PARA COMPATIBILIDADE
-- ============================================

-- Aliases para código legado (será removido na v3.0)
musicBeat = DJSystem.MusicBeat
activeEffects = DJSystem.ActiveEffects
audioZones = DJSystem.AudioZones

print("[DJ Core] ✓ Shared module loaded successfully")
print(string.format("[DJ Core] Version: %s", DJSystem.Version))
