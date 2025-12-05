console.log('[DJ] ========================================');
console.log('[DJ] DJ System NUI Initializing...');
console.log('[DJ] Howler.js available:', typeof Howl !== 'undefined');
console.log('[DJ] ========================================');

const app = document.getElementById('app');

// Multi-Zone Audio State
let activeZones = {};
// Structure: activeZones[zoneId] = {
//   deck_a: { playing: false, volume: 0.8, url: '', type: 'none', howl: null, yt: null, spatialVolume: 1.0 },
//   deck_b: { playing: false, volume: 0.8, url: '', type: 'none', howl: null, yt: null, spatialVolume: 1.0 }
// }

// Current zone (for UI)
let currentZone = null;

// Backward compatibility - single deck state for UI
let decks = {
    a: { playing: false, volume: 0.8, url: '', type: 'none', howl: null, yt: null },
    b: { playing: false, volume: 0.8, url: '', type: 'none', howl: null, yt: null }
};

// YouTube API Ready Flag
let youtubeAPIReady = false;

// Load YouTube IFrame API
var tag = document.createElement('script');
tag.src = "https://www.youtube.com/iframe_api";
var firstScriptTag = document.getElementsByTagName('script')[0];
firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

console.log('[DJ YouTube] Loading YouTube IFrame API...');

// Initialize YouTube Players
function onYouTubeIframeAPIReady() {
    console.log('[DJ YouTube] ✓ YouTube IFrame API Ready!');
    youtubeAPIReady = true;
    
    decks.a.yt = new YT.Player('youtube-player-a', {
        height: '0',
        width: '0',
        events: {
            'onReady': onPlayerReady,
            'onStateChange': (event) => onPlayerStateChange(event, 'a'),
            'onError': (event) => onPlayerError(event, 'a')
        }
    });
    decks.b.yt = new YT.Player('youtube-player-b', {
        height: '0',
        width: '0',
        events: {
            'onReady': onPlayerReady,
            'onStateChange': (event) => onPlayerStateChange(event, 'b'),
            'onError': (event) => onPlayerError(event, 'b')
        }
    });
    
    console.log('[DJ YouTube] ✓ Default players created');
}

function onPlayerReady(event) {
    console.log('[DJ YouTube] Player ready:', event.target);
}

function onPlayerStateChange(event, deckId) {
    const metaEl = document.getElementById(`meta-${deckId}`);
    if (event.data == YT.PlayerState.PLAYING) {
        const player = decks[deckId].yt;
        const data = player.getVideoData();
        metaEl.innerText = data.title.substring(0, 30) + "...";
        metaEl.style.color = "#00f2ff";
        document.getElementById(`deck-${deckId}`).classList.add('playing');
    } else if (event.data == YT.PlayerState.ENDED) {
        document.getElementById(`deck-${deckId}`).classList.remove('playing');
        metaEl.innerText = "Track Ended";
    }
}

function onPlayerError(event, deckId) {
    console.error(`[DJ] YouTube Error on Deck ${deckId}:`, event.data);
    const metaEl = document.getElementById(`meta-${deckId}`);
    metaEl.innerText = "YouTube Error (Restricted?)";
    metaEl.style.color = "#ff0000";
}

// Listen for NUI Messages
window.addEventListener('message', (event) => {
    const data = event.data;
    if (data.type === 'toggle') {
        if (data.status) {
            app.classList.remove('hidden');
            document.querySelectorAll('.interface-container').forEach(el => el.classList.add('hidden'));
            if (data.mode === 'builder') {
                document.getElementById('builder-interface').classList.remove('hidden');
            } else {
                document.getElementById('dj-interface').classList.remove('hidden');
            }
        } else {
            app.classList.add('hidden');
        }
    } else if (data.type === 'updateZoneVolume') {
        // Apply 3D audio volume to specific zone
        const zoneId = data.zoneId;
        const spatialVolume = data.volume;

        if (activeZones[zoneId]) {
            // Update spatial volume for this zone
            activeZones[zoneId].deck_a.spatialVolume = spatialVolume;
            activeZones[zoneId].deck_b.spatialVolume = spatialVolume;

            // Apply to Deck A
            const deckA = activeZones[zoneId].deck_a;
            if (deckA.type === 'howler' && deckA.howl) {
                deckA.howl.volume(deckA.volume * spatialVolume);
            } else if (deckA.type === 'youtube' && deckA.yt && deckA.yt.setVolume) {
                deckA.yt.setVolume(deckA.volume * spatialVolume * 100);
            }

            // Apply to Deck B
            const deckB = activeZones[zoneId].deck_b;
            if (deckB.type === 'howler' && deckB.howl) {
                deckB.howl.volume(deckB.volume * spatialVolume);
            } else if (deckB.type === 'youtube' && deckB.yt && deckB.yt.setVolume) {
                deckB.yt.setVolume(deckB.volume * spatialVolume * 100);
            }
        }
    } else if (data.type === 'playAudio') {
        window.playAudioZone(data.zoneId, data.deck, data.url, data.time);
    } else if (data.type === 'stopAudio') {
        window.stopAudioZone(data.zoneId, data.deck);
    } else if (data.type === 'pauseAudio') {
        window.pauseAudioZone(data.zoneId, data.deck);
    } else if (data.type === 'setDeckVolume') {
        window.setDeckVolume(data.deck, data.volume);
    } else if (data.type === 'openEffectModal') {
        app.classList.remove('hidden');
        document.querySelectorAll('.interface-container').forEach(el => el.classList.add('hidden'));
        document.getElementById('effect-modal').classList.remove('hidden');
        // Store pending prop data
        window.pendingProp = data.propData;
    } else if (data.type === 'checkBeatSystem') {
        // Debug: Check beat system state
        console.log("========================================");
        console.log("[DJ Beat Check] BEAT SYSTEM STATE:");
        console.log("[DJ Beat Check] enabled:", beatDetector.enabled);
        console.log("[DJ Beat Check] bpm:", beatDetector.bpm);
        console.log("[DJ Beat Check] beatCount:", beatDetector.beatCount);
        console.log("[DJ Beat Check] beatDetectionInterval:", beatDetectionInterval);
        console.log("[DJ Beat Check] beatDetectionInterval type:", typeof beatDetectionInterval);
        console.log("[DJ Beat Check] beatDetectionInterval is null:", beatDetectionInterval === null);
        
        if (beatDetectionInterval) {
            console.log("[DJ Beat Check] ✓ Beat system is RUNNING");
        } else {
            console.log("[DJ Beat Check] ✗ Beat system is STOPPED");
            console.log("[DJ Beat Check] Attempting to restart...");
            const currentBPM = bpmSlider ? parseInt(bpmSlider.value) : 128;
            startSimpleBeatSystem(currentBPM);
        }
        console.log("========================================");
    }
});

// Effect Modal Logic
document.querySelectorAll('.btn-effect-select').forEach(btn => {
    btn.addEventListener('click', () => {
        const effect = btn.dataset.effect;
        if (window.pendingProp) {
            fetch(`https://${GetParentResourceName()}/confirmPlacement`, {
                method: 'POST',
                body: JSON.stringify({
                    prop: window.pendingProp.prop,
                    coords: window.pendingProp.coords,
                    heading: window.pendingProp.heading,
                    effect: effect
                })
            });
            window.pendingProp = null;
        }
        document.getElementById('effect-modal').classList.add('hidden');
        app.classList.add('hidden');
        // Re-open builder? Or just close. Let's just close for now.
        fetch(`https://${GetParentResourceName()}/close`, { method: 'POST' });
    });
});

document.querySelector('.close-modal-btn').addEventListener('click', () => {
    document.getElementById('effect-modal').classList.add('hidden');
    app.classList.add('hidden');
    window.pendingProp = null;
    fetch(`https://${GetParentResourceName()}/close`, { method: 'POST' });
});

// Close Button
document.querySelectorAll('.close-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        // Stop beat detection when closing UI
        stopBeatDetection();
        
        fetch(`https://${GetParentResourceName()}/close`, { method: 'POST' });
        app.classList.add('hidden');
    });
});

// Deck Controls
document.querySelectorAll('.btn-control').forEach(btn => {
    btn.addEventListener('click', (e) => {
        const deckId = btn.dataset.deck;
        const action = btn.classList.contains('play-btn') ? 'play' :
            btn.classList.contains('pause-btn') ? 'pause' : 'stop';
        handleDeckControl(deckId, action);
    });
});

function handleDeckControl(deckId, action) {
    const deckEl = document.getElementById(`deck-${deckId}`);
    const input = document.getElementById(`url-${deckId}`);
    const metaEl = document.getElementById(`meta-${deckId}`);
    const url = input.value.trim();

    if (action === 'play') {
        if (!url) {
            metaEl.innerText = "⚠️ Insira uma URL primeiro!";
            metaEl.style.color = "#ff0000";
            setTimeout(() => {
                metaEl.innerText = "Waiting for track...";
                metaEl.style.color = "#00f2ff";
            }, 3000);
            return;
        }
        
        // Validate URL
        if (!isValidMediaURL(url)) {
            metaEl.innerText = "⚠️ URL inválida! Use YouTube ou link direto de áudio";
            metaEl.style.color = "#ff0000";
            setTimeout(() => {
                metaEl.innerText = "Waiting for track...";
                metaEl.style.color = "#00f2ff";
            }, 3000);
            return;
        }
        
        metaEl.innerText = "🎵 Carregando: " + getURLDisplayName(url);
        metaEl.style.color = "#ffff00";
        
        fetch(`https://${GetParentResourceName()}/playAudio`, {
            method: 'POST',
            body: JSON.stringify({ deck: deckId, url: url, action: 'play' })
        });
        
        deckEl.classList.add('playing');
        
        // Update meta after 2 seconds with URL info
        setTimeout(() => {
            metaEl.innerText = "♪ " + getURLDisplayName(url);
            metaEl.style.color = "#00ff00";
        }, 2000);
        
    } else if (action === 'pause') {
        fetch(`https://${GetParentResourceName()}/playAudio`, {
            method: 'POST',
            body: JSON.stringify({ deck: deckId, action: 'pause' })
        });
        metaEl.innerText = "⏸️ Pausado";
        metaEl.style.color = "#ffaa00";
        
    } else if (action === 'stop') {
        fetch(`https://${GetParentResourceName()}/playAudio`, {
            method: 'POST',
            body: JSON.stringify({ deck: deckId, action: 'stop' })
        });
        deckEl.classList.remove('playing');
        metaEl.innerText = "⏹️ Parado";
        metaEl.style.color = "#ff0000";
    }
}

// Volume Sliders
document.querySelectorAll('.volume-slider').forEach(slider => {
    slider.addEventListener('input', (e) => {
        const deckId = e.target.dataset.deck;
        const val = e.target.value / 100;
        decks[deckId].volume = val;
        fetch(`https://${GetParentResourceName()}/updateVolume`, {
            method: 'POST',
            body: JSON.stringify({ deck: deckId, volume: val })
        });
        // Local update immediately
        window.setDeckVolume(deckId, val);
    });
});

// EQ Knobs (Visual + Data send)
document.querySelectorAll('.knob').forEach(knob => {
    knob.addEventListener('input', (e) => {
        const deckId = e.target.dataset.deck;
        const eqType = e.target.dataset.eq;
        const val = e.target.value;
        // Send EQ update
        fetch(`https://${GetParentResourceName()}/updateEQ`, {
            method: 'POST',
            body: JSON.stringify({ deck: deckId, eq: eqType, value: val })
        });
    });
});

// BPM Control
const bpmSlider = document.getElementById('bpm-slider');
const bpmDisplay = document.getElementById('bpm-display');

if (bpmSlider && bpmDisplay) {
    bpmSlider.addEventListener('input', (e) => {
        const bpm = parseInt(e.target.value);
        bpmDisplay.textContent = bpm;
        beatDetector.bpm = bpm;
        
        console.log('[DJ Beat] BPM slider changed to:', bpm);
        
        // Restart beat system with new BPM if music is playing
        if (beatDetector.enabled) {
            console.log('[DJ Beat] Restarting beat system with new BPM');
            startSimpleBeatSystem(bpm);
        }
    });
}

// Effects
document.querySelectorAll('.btn-effect').forEach(btn => {
    btn.addEventListener('click', () => {
        const effect = btn.dataset.effect;
        fetch(`https://${GetParentResourceName()}/triggerEffect`, {
            method: 'POST',
            body: JSON.stringify({ effect: effect })
        });
    });
});

// Tabs
document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
        btn.classList.add('active');
        document.getElementById(btn.dataset.tab).classList.add('active');
    });
});

// Stage Builder & Visuals
document.querySelectorAll('.grid-item').forEach(item => {
    item.addEventListener('click', () => {
        console.log('[DJ NUI] Grid item clicked:', item.dataset);

        if (item.dataset.prop) {
            const resourceName = GetParentResourceName();
            console.log('[DJ NUI] Resource name:', resourceName);
            console.log('[DJ NUI] Sending startPlacement for:', item.dataset.prop);
            console.log('[DJ NUI] Full URL:', `https://${resourceName}/startPlacement`);
            // Close UI and start placement
            fetch(`https://${resourceName}/startPlacement`, {
                method: 'POST',
                body: JSON.stringify({ prop: item.dataset.prop })
            }).then(() => {
                console.log('[DJ NUI] startPlacement sent successfully');
                app.classList.add('hidden');
            }).catch(err => {
                console.error('[DJ NUI] Error sending startPlacement:', err);
            });
        } else if (item.dataset.visual) {
            fetch(`https://${GetParentResourceName()}/spawnVisual`, {
                method: 'POST',
                body: JSON.stringify({ visual: item.dataset.visual })
            });
        } else if (item.dataset.action === 'delete_last') {
            fetch(`https://${GetParentResourceName()}/removeLastProp`, {
                method: 'POST',
                body: JSON.stringify({})
            });
        }
    });
});

// Helper: Extract YouTube ID - Improved to support more URL formats
function getYouTubeID(url) {
    // Support various YouTube URL formats
    const patterns = [
        /(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/|youtube\.com\/v\/)([a-zA-Z0-9_-]{11})/,
        /youtube\.com\/watch\?.*v=([a-zA-Z0-9_-]{11})/,
        /^([a-zA-Z0-9_-]{11})$/ // Direct video ID
    ];
    
    for (let pattern of patterns) {
        const match = url.match(pattern);
        if (match && match[1]) {
            return match[1];
        }
    }
    
    return false;
}

// Helper: Detect if URL is a valid audio/video source
function isValidMediaURL(url) {
    if (!url || url.trim() === '') return false;
    
    // Check if it's a YouTube URL
    if (getYouTubeID(url)) return true;
    
    // Check if it's a direct media file (mp3, mp4, ogg, wav, webm, etc.)
    const mediaExtensions = /\.(mp3|mp4|ogg|wav|webm|m4a|aac|flac|opus)(\?.*)?$/i;
    if (mediaExtensions.test(url)) return true;
    
    // Check if it's a valid HTTP/HTTPS URL
    if (/^https?:\/\/.+/i.test(url)) return true;
    
    // Check if it's a local file path
    if (/^file:\/\//i.test(url)) return true;
    
    return false;
}

// Helper: Get display name from URL
function getURLDisplayName(url) {
    if (!url) return 'Unknown';
    
    // Check if YouTube
    const ytId = getYouTubeID(url);
    if (ytId) {
        return `YouTube: ${ytId}`;
    }
    
    // Extract filename from URL
    try {
        const urlObj = new URL(url);
        const pathname = urlObj.pathname;
        const filename = pathname.split('/').pop();
        if (filename) {
            // Decode and limit length
            const decoded = decodeURIComponent(filename);
            return decoded.length > 35 ? decoded.substring(0, 35) + '...' : decoded;
        }
    } catch (e) {
        // If URL parsing fails, just use the last part
        const parts = url.split('/');
        const last = parts[parts.length - 1];
        if (last) {
            return last.length > 35 ? last.substring(0, 35) + '...' : last;
        }
    }
    
    // Fallback: show truncated URL
    return url.length > 35 ? url.substring(0, 35) + '...' : url;
}

// Helper: Format Time
function formatTime(secs) {
    const minutes = Math.floor(secs / 60) || 0;
    const seconds = Math.floor(secs - minutes * 60) || 0;
    return (minutes < 10 ? '0' : '') + minutes + ':' + (seconds < 10 ? '0' : '') + seconds;
}

// Play Audio Logic
window.playAudio = function (deckId, url, startTime) {
    const metaEl = document.getElementById(`meta-${deckId}`);
    const timeEl = document.getElementById(`time-${deckId}`);

    // Stop existing
    if (decks[deckId].type === 'howler' && decks[deckId].howl) {
        decks[deckId].howl.unload();
    } else if (decks[deckId].type === 'youtube' && decks[deckId].yt) {
        decks[deckId].yt.stopVideo();
    }

    decks[deckId].url = url;
    decks[deckId].playing = true;

    const ytId = getYouTubeID(url);

    if (ytId) {
        // YouTube Mode
        decks[deckId].type = 'youtube';
        metaEl.innerText = "🎵 Carregando: YouTube - " + ytId;
        metaEl.style.color = "#ffff00";

        if (decks[deckId].yt && decks[deckId].yt.loadVideoById) {
            decks[deckId].yt.loadVideoById(ytId, startTime);
            decks[deckId].yt.setVolume(decks[deckId].volume * 100);
            
            // Update meta when loaded
            setTimeout(() => {
                metaEl.innerText = "♪ YouTube: " + ytId;
                metaEl.style.color = "#00ff00";
            }, 2000);
        } else {
            metaEl.innerText = "⚠️ YouTube Player Not Ready";
            metaEl.style.color = "#ff0000";
        }
    } else {
        // Howler Mode (supports any audio URL)
        decks[deckId].type = 'howler';
        const displayName = getURLDisplayName(url);
        metaEl.innerText = "🎵 Carregando: " + displayName;
        metaEl.style.color = "#ffff00";

        decks[deckId].howl = new Howl({
            src: [url],
            html5: true,
            volume: decks[deckId].volume,
            onload: function () {
                metaEl.innerText = "♪ " + displayName;
                metaEl.style.color = "#00ff00";
                console.log(`[DJ] ✓ Audio loaded on Deck ${deckId}: ${displayName}`);
            },
            onplay: function () {
                console.log(`[DJ] ✓ Audio playing on Deck ${deckId}`);
            },
            onend: function () {
                document.getElementById(`deck-${deckId}`).classList.remove('playing');
                metaEl.innerText = "⏹️ Track Ended";
                metaEl.style.color = "#888888";
            },
            onloaderror: function (id, err) {
                console.error(`[DJ] ✗ Load Error on Deck ${deckId}:`, err);
                metaEl.innerText = "⚠️ Erro ao carregar áudio";
                metaEl.style.color = "#ff0000";
            },
            onplayerror: function (id, err) {
                console.error(`[DJ] ✗ Play Error on Deck ${deckId}:`, err);
                metaEl.innerText = "⚠️ Erro ao reproduzir";
                metaEl.style.color = "#ff0000";
            }
        });
        decks[deckId].howl.play();
        if (startTime > 0) decks[deckId].howl.seek(startTime);
    }

    document.getElementById(`deck-${deckId}`).classList.add('playing');

    // Timer Loop - Show URL and time
    if (decks[deckId].timer) clearInterval(decks[deckId].timer);
    decks[deckId].timer = setInterval(() => {
        let currentTime = 0;
        let duration = 0;

        if (decks[deckId].type === 'youtube' && decks[deckId].yt && decks[deckId].yt.getCurrentTime) {
            currentTime = decks[deckId].yt.getCurrentTime();
            duration = decks[deckId].yt.getDuration();
        } else if (decks[deckId].type === 'howler' && decks[deckId].howl && decks[deckId].howl.playing()) {
            currentTime = decks[deckId].howl.seek();
            duration = decks[deckId].howl.duration();
        }

        // Update time display with URL info
        const displayName = getURLDisplayName(url);
        timeEl.innerHTML = `
            <div style="font-size: 0.85em; color: #00f2ff; margin-bottom: 2px;">
                ${displayName}
            </div>
            <div style="font-size: 1em;">
                ${formatTime(currentTime)} / ${formatTime(duration)}
            </div>
        `;
    }, 1000);
}

window.stopAudio = function (deckId) {
    if (decks[deckId].type === 'howler' && decks[deckId].howl) {
        decks[deckId].howl.stop();
    } else if (decks[deckId].type === 'youtube' && decks[deckId].yt) {
        decks[deckId].yt.stopVideo();
    }

    if (decks[deckId].timer) clearInterval(decks[deckId].timer);
    document.getElementById(`deck-${deckId}`).classList.remove('playing');
    document.getElementById(`meta-${deckId}`).innerText = "Stopped";
    document.getElementById(`time-${deckId}`).innerText = "00:00 / 00:00";
    decks[deckId].playing = false;
}

window.pauseAudio = function (deckId) {
    if (decks[deckId].type === 'howler' && decks[deckId].howl) {
        decks[deckId].howl.pause();
    } else if (decks[deckId].type === 'youtube' && decks[deckId].yt) {
        decks[deckId].yt.pauseVideo();
    }
    document.getElementById(`deck-${deckId}`).classList.remove('playing');
    document.getElementById(`meta-${deckId}`).innerText = "Paused";
}

window.setDeckVolume = function (deckId, vol) {
    decks[deckId].volume = vol;
    if (decks[deckId].type === 'howler' && decks[deckId].howl) {
        decks[deckId].howl.volume(vol);
    } else if (decks[deckId].type === 'youtube' && decks[deckId].yt) {
        decks[deckId].yt.setVolume(vol * 100);
    }
}

function GetParentResourceName() {
    // Remove 'cfx-nui-' prefix if present
    let resourceName = window.location.hostname;
    if (resourceName.startsWith('cfx-nui-')) {
        resourceName = resourceName.replace('cfx-nui-', '');
    }
    return resourceName;
}

// Multi-Zone Audio Functions
window.playAudioZone = function (zoneId, deckId, url, startTime = 0) {
    console.log('[DJ Zone] playAudioZone called - Zone:', zoneId, 'Deck:', deckId);
    
    // Initialize zone if it doesn't exist
    if (!activeZones[zoneId]) {
        activeZones[zoneId] = {
            deck_a: { playing: false, volume: 0.8, url: '', type: 'none', howl: null, yt: null, spatialVolume: 1.0 },
            deck_b: { playing: false, volume: 0.8, url: '', type: 'none', howl: null, yt: null, spatialVolume: 1.0 }
        };
    }

    const deckKey = `deck_${deckId}`;
    const deck = activeZones[zoneId][deckKey];

    // Stop existing audio
    if (deck.howl) {
        deck.howl.stop();
        deck.howl.unload();
    }
    if (deck.yt && deck.yt.stopVideo) {
        deck.yt.stopVideo();
    }

    deck.url = url;
    deck.playing = true;
    
    // Start beat system when music starts playing
    if (!beatDetector.enabled) {
        const currentBPM = bpmSlider ? parseInt(bpmSlider.value) : 128;
        console.log('[DJ Zone] Starting beat system with BPM:', currentBPM);
        setTimeout(() => {
            startSimpleBeatSystem(currentBPM);
        }, 500);
    }

    // Check if YouTube using improved detection
    const ytId = getYouTubeID(url);

    if (ytId) {
        // YouTube Mode
        deck.type = 'youtube';
        
        console.log('[DJ Zone] YouTube detected - Video ID:', ytId);
        console.log('[DJ Zone] URL:', url);
        console.log('[DJ Zone] YT API ready:', youtubeAPIReady);

        // Check if YouTube API is loaded
        if (!youtubeAPIReady || typeof YT === 'undefined' || !YT.Player) {
            console.error('[DJ Zone] YouTube API not ready! Waiting...');
            // Wait for API to load
            let attempts = 0;
            const checkInterval = setInterval(() => {
                attempts++;
                if (youtubeAPIReady && typeof YT !== 'undefined' && YT.Player) {
                    console.log('[DJ Zone] ✓ YouTube API now ready, retrying...');
                    clearInterval(checkInterval);
                    window.playAudioZone(zoneId, deckId, url, startTime);
                } else if (attempts > 10) {
                    console.error('[DJ Zone] ✗ YouTube API failed to load after 10 seconds');
                    clearInterval(checkInterval);
                }
            }, 1000);
            return;
        }

        // Create YouTube player if it doesn't exist
        if (!deck.yt || !deck.yt.playVideo) {
            console.log('[DJ Zone] Creating new YouTube player...');
            const playerDiv = document.createElement('div');
            playerDiv.id = `yt-zone-${zoneId}-${deckId}`;
            playerDiv.style.display = 'none';
            document.body.appendChild(playerDiv);

            deck.yt = new YT.Player(playerDiv.id, {
                height: '0',
                width: '0',
                videoId: ytId,
                playerVars: {
                    autoplay: 1,
                    controls: 0,
                    disablekb: 1,
                    fs: 0,
                    modestbranding: 1,
                    playsinline: 1
                },
                events: {
                    'onReady': (event) => {
                        console.log('[DJ Zone] YouTube player ready!');
                        event.target.playVideo();
                        event.target.seekTo(startTime);
                        event.target.setVolume(deck.volume * deck.spatialVolume * 100);
                    },
                    'onStateChange': (event) => {
                        console.log('[DJ Zone] YouTube state changed:', event.data);
                        if (event.data === YT.PlayerState.PLAYING) {
                            console.log('[DJ Zone] ✓ YouTube is playing!');
                        }
                    },
                    'onError': (event) => {
                        console.error('[DJ Zone] YouTube error:', event.data);
                    }
                }
            });
        } else {
            console.log('[DJ Zone] Using existing YouTube player...');
            deck.yt.loadVideoById(ytId, startTime);
            deck.yt.setVolume(deck.volume * deck.spatialVolume * 100);
            deck.yt.playVideo();
        }
    } else {
        // Howler Mode (supports any audio URL)
        deck.type = 'howler';
        
        const displayName = getURLDisplayName(url);
        console.log('[DJ Zone] Using Howler.js for audio playback');
        console.log('[DJ Zone] URL:', url);
        console.log('[DJ Zone] Display name:', displayName);

        deck.howl = new Howl({
            src: [url],
            html5: true,
            volume: deck.volume * deck.spatialVolume,
            onload: function () {
                console.log(`[DJ Zone ${zoneId}] ✓ Audio loaded on ${deckId}: ${displayName}`);
            },
            onplay: function () {
                console.log(`[DJ Zone ${zoneId}] ✓ Audio playing on ${deckId}: ${displayName}`);
            },
            onloaderror: function (id, err) {
                console.error(`[DJ Zone ${zoneId}] ✗ Load Error on ${deckId}:`, err);
                console.error(`[DJ Zone ${zoneId}] Failed URL:`, url);
            },
            onplayerror: function (id, err) {
                console.error(`[DJ Zone ${zoneId}] ✗ Play Error on ${deckId}:`, err);
            }
        });
        deck.howl.play();
        if (startTime > 0) deck.howl.seek(startTime);
    }

    console.log(`[DJ Zone ${zoneId}] ✓ Playing ${deckId}: ${getURLDisplayName(url)}`);
};

window.stopAudioZone = function (zoneId, deckId) {
    if (!activeZones[zoneId]) return;

    const deckKey = `deck_${deckId}`;
    const deck = activeZones[zoneId][deckKey];

    if (deck.howl) {
        deck.howl.stop();
        deck.howl.unload();
        deck.howl = null;
    }
    if (deck.yt && deck.yt.stopVideo) {
        deck.yt.stopVideo();
    }

    deck.playing = false;
    deck.type = 'none';
    console.log(`[DJ Zone ${zoneId}] Stopped ${deckId}`);
    
    // Check if all decks in all zones are stopped
    let anyPlaying = false;
    for (let zone in activeZones) {
        if (activeZones[zone].deck_a.playing || activeZones[zone].deck_b.playing) {
            anyPlaying = true;
            break;
        }
    }
    
    // Stop beat system if nothing is playing
    if (!anyPlaying) {
        console.log('[DJ Zone] All music stopped, stopping beat system');
        stopBeatDetection();
        
        fetch(`https://${GetParentResourceName()}/updateMusicState`, {
            method: 'POST',
            body: JSON.stringify({
                playing: false,
                bpm: 0
            })
        });
    }
};

window.pauseAudioZone = function (zoneId, deckId) {
    if (!activeZones[zoneId]) return;

    const deckKey = `deck_${deckId}`;
    const deck = activeZones[zoneId][deckKey];

    if (deck.howl) {
        deck.howl.pause();
    }
    if (deck.yt && deck.yt.pauseVideo) {
        deck.yt.pauseVideo();
    }

    deck.playing = false;
    console.log(`[DJ Zone ${zoneId}] Paused ${deckId}`);
};


// Effect Configuration Modal Logic
let pendingPropData = null;
let currentEffectConfig = {
    type: 'none',
    syncWithMusic: false,
    lights: {
        color: '#00ffff',
        intensity: 5.0,
        mode: 'movinghead',
        speed: 1.0,
        syncWithMusic: false
    },
    lasers: {
        color: '#00ff00',
        pattern: 'beams',
        count: 4,
        speed: 1.0,
        syncWithMusic: false
    },
    smoke: {
        color: '#ffffff',
        density: 1.0,
        mode: 'continuous',
        syncWithMusic: false
    },
    confetti: {
        style: 'colorful',
        intensity: 1.0,
        mode: 'cannon',
        frequency: 3.0,
        syncWithMusic: false
    },
    bubbles: {
        size: 'medium',
        amount: 1.0,
        mode: 'continuous',
        syncWithMusic: false
    },
    pyro: {
        color: '#ff4400',
        type: 'flame',
        intensity: 1.0,
        height: 3.0,
        syncWithMusic: false
    },
    co2: {
        mode: 'vertical',
        pressure: 1.0,
        duration: 2.0,
        syncWithMusic: false
    },
    uv: {
        color: '#9900ff',
        pattern: 'static',
        intensity: 5.0,
        range: 15,
        syncWithMusic: false
    }
};

// Config Tab Switching
document.querySelectorAll('.config-tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const tab = btn.dataset.configTab;
        
        console.log('[DJ NUI] Tab clicked:', tab);
        
        // Update active tab
        document.querySelectorAll('.config-tab-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        
        // Update active panel
        document.querySelectorAll('.config-panel').forEach(p => p.classList.remove('active'));
        document.getElementById(`config-${tab}`).classList.add('active');
        
        // Update effect type
        currentEffectConfig.type = tab;
        
        console.log('[DJ NUI] Effect type updated to:', currentEffectConfig.type);
    });
});

// Range Input Updates (with safety checks)
const lightIntensity = document.getElementById('light-intensity');
if (lightIntensity) {
    lightIntensity.addEventListener('input', (e) => {
        document.getElementById('light-intensity-val').textContent = e.target.value;
        currentEffectConfig.lights.intensity = parseFloat(e.target.value);
    });
}

const lightSpeed = document.getElementById('light-speed');
if (lightSpeed) {
    lightSpeed.addEventListener('input', (e) => {
        document.getElementById('light-speed-val').textContent = e.target.value + 'x';
        currentEffectConfig.lights.speed = parseFloat(e.target.value);
    });
}

const lightSyncMusic = document.getElementById('light-sync-music');
if (lightSyncMusic) {
    lightSyncMusic.addEventListener('change', (e) => {
        currentEffectConfig.lights.syncWithMusic = e.target.checked;
        console.log('[DJ NUI] Light sync with music:', e.target.checked);
    });
}

// Laser controls
const laserColor = document.getElementById('laser-color');
if (laserColor) {
    laserColor.addEventListener('change', (e) => {
        currentEffectConfig.lasers.color = e.target.value;
    });
}

const laserPattern = document.getElementById('laser-pattern');
if (laserPattern) {
    laserPattern.addEventListener('change', (e) => {
        currentEffectConfig.lasers.pattern = e.target.value;
    });
}

const laserCount = document.getElementById('laser-count');
if (laserCount) {
    laserCount.addEventListener('input', (e) => {
        document.getElementById('laser-count-val').textContent = e.target.value;
        currentEffectConfig.lasers.count = parseInt(e.target.value);
    });
}

const laserSpeed = document.getElementById('laser-speed');
if (laserSpeed) {
    laserSpeed.addEventListener('input', (e) => {
        document.getElementById('laser-speed-val').textContent = e.target.value + 'x';
        currentEffectConfig.lasers.speed = parseFloat(e.target.value);
    });
}

const laserSyncMusic = document.getElementById('laser-sync-music');
if (laserSyncMusic) {
    laserSyncMusic.addEventListener('change', (e) => {
        currentEffectConfig.lasers.syncWithMusic = e.target.checked;
        console.log('[DJ NUI] Laser sync with music:', e.target.checked);
    });
}

// Confetti controls
const confettiStyle = document.getElementById('confetti-style');
if (confettiStyle) {
    confettiStyle.addEventListener('change', (e) => {
        currentEffectConfig.confetti.style = e.target.value;
    });
}

const confettiIntensity = document.getElementById('confetti-intensity');
if (confettiIntensity) {
    confettiIntensity.addEventListener('input', (e) => {
        document.getElementById('confetti-intensity-val').textContent = e.target.value;
        currentEffectConfig.confetti.intensity = parseFloat(e.target.value);
    });
}

const confettiMode = document.getElementById('confetti-mode');
if (confettiMode) {
    confettiMode.addEventListener('change', (e) => {
        currentEffectConfig.confetti.mode = e.target.value;
    });
}

const confettiFrequency = document.getElementById('confetti-frequency');
if (confettiFrequency) {
    confettiFrequency.addEventListener('input', (e) => {
        document.getElementById('confetti-freq-val').textContent = e.target.value + 's';
        currentEffectConfig.confetti.frequency = parseFloat(e.target.value);
    });
}

const confettiSyncMusic = document.getElementById('confetti-sync-music');
if (confettiSyncMusic) {
    confettiSyncMusic.addEventListener('change', (e) => {
        currentEffectConfig.confetti.syncWithMusic = e.target.checked;
        console.log('[DJ NUI] Confetti sync with music:', e.target.checked);
    });
}

// Bubble controls
const bubbleSize = document.getElementById('bubble-size');
if (bubbleSize) {
    bubbleSize.addEventListener('change', (e) => {
        currentEffectConfig.bubbles.size = e.target.value;
    });
}

const bubbleAmount = document.getElementById('bubble-amount');
if (bubbleAmount) {
    bubbleAmount.addEventListener('input', (e) => {
        document.getElementById('bubble-amount-val').textContent = e.target.value;
        currentEffectConfig.bubbles.amount = parseFloat(e.target.value);
    });
}

const bubbleMode = document.getElementById('bubble-mode');
if (bubbleMode) {
    bubbleMode.addEventListener('change', (e) => {
        currentEffectConfig.bubbles.mode = e.target.value;
    });
}

const bubbleSyncMusic = document.getElementById('bubble-sync-music');
if (bubbleSyncMusic) {
    bubbleSyncMusic.addEventListener('change', (e) => {
        currentEffectConfig.bubbles.syncWithMusic = e.target.checked;
        console.log('[DJ NUI] Bubble sync with music:', e.target.checked);
    });
}

// Pyro controls
const pyroColor = document.getElementById('pyro-color');
if (pyroColor) {
    pyroColor.addEventListener('change', (e) => {
        currentEffectConfig.pyro.color = e.target.value;
    });
}

const pyroType = document.getElementById('pyro-type');
if (pyroType) {
    pyroType.addEventListener('change', (e) => {
        currentEffectConfig.pyro.type = e.target.value;
    });
}

const pyroIntensity = document.getElementById('pyro-intensity');
if (pyroIntensity) {
    pyroIntensity.addEventListener('input', (e) => {
        document.getElementById('pyro-intensity-val').textContent = e.target.value;
        currentEffectConfig.pyro.intensity = parseFloat(e.target.value);
    });
}

const pyroHeight = document.getElementById('pyro-height');
if (pyroHeight) {
    pyroHeight.addEventListener('input', (e) => {
        document.getElementById('pyro-height-val').textContent = e.target.value + 'm';
        currentEffectConfig.pyro.height = parseFloat(e.target.value);
    });
}

const pyroSyncMusic = document.getElementById('pyro-sync-music');
if (pyroSyncMusic) {
    pyroSyncMusic.addEventListener('change', (e) => {
        currentEffectConfig.pyro.syncWithMusic = e.target.checked;
        console.log('[DJ NUI] Pyro sync with music:', e.target.checked);
    });
}

// CO2 controls
const co2Mode = document.getElementById('co2-mode');
if (co2Mode) {
    co2Mode.addEventListener('change', (e) => {
        currentEffectConfig.co2.mode = e.target.value;
    });
}

const co2Pressure = document.getElementById('co2-pressure');
if (co2Pressure) {
    co2Pressure.addEventListener('input', (e) => {
        document.getElementById('co2-pressure-val').textContent = e.target.value;
        currentEffectConfig.co2.pressure = parseFloat(e.target.value);
    });
}

const co2Duration = document.getElementById('co2-duration');
if (co2Duration) {
    co2Duration.addEventListener('input', (e) => {
        document.getElementById('co2-duration-val').textContent = e.target.value + 's';
        currentEffectConfig.co2.duration = parseFloat(e.target.value);
    });
}

const co2SyncMusic = document.getElementById('co2-sync-music');
if (co2SyncMusic) {
    co2SyncMusic.addEventListener('change', (e) => {
        currentEffectConfig.co2.syncWithMusic = e.target.checked;
        console.log('[DJ NUI] CO2 sync with music:', e.target.checked);
    });
}

// UV controls
const uvColor = document.getElementById('uv-color');
if (uvColor) {
    uvColor.addEventListener('change', (e) => {
        currentEffectConfig.uv.color = e.target.value;
    });
}

const uvPattern = document.getElementById('uv-pattern');
if (uvPattern) {
    uvPattern.addEventListener('change', (e) => {
        currentEffectConfig.uv.pattern = e.target.value;
    });
}

const uvIntensity = document.getElementById('uv-intensity');
if (uvIntensity) {
    uvIntensity.addEventListener('input', (e) => {
        document.getElementById('uv-intensity-val').textContent = e.target.value;
        currentEffectConfig.uv.intensity = parseFloat(e.target.value);
    });
}

const uvRange = document.getElementById('uv-range');
if (uvRange) {
    uvRange.addEventListener('input', (e) => {
        document.getElementById('uv-range-val').textContent = e.target.value + 'm';
        currentEffectConfig.uv.range = parseFloat(e.target.value);
    });
}

const uvSyncMusic = document.getElementById('uv-sync-music');
if (uvSyncMusic) {
    uvSyncMusic.addEventListener('change', (e) => {
        currentEffectConfig.uv.syncWithMusic = e.target.checked;
        console.log('[DJ NUI] UV sync with music:', e.target.checked);
    });
}

document.getElementById('smoke-density').addEventListener('input', (e) => {
    document.getElementById('smoke-density-val').textContent = e.target.value;
    currentEffectConfig.smoke.density = parseFloat(e.target.value);
});



// Color and Select Updates
document.getElementById('light-color').addEventListener('change', (e) => {
    currentEffectConfig.lights.color = e.target.value;
});

document.getElementById('light-mode').addEventListener('change', (e) => {
    currentEffectConfig.lights.mode = e.target.value;
});

document.getElementById('smoke-color').addEventListener('change', (e) => {
    currentEffectConfig.smoke.color = e.target.value;
});

document.getElementById('smoke-mode').addEventListener('change', (e) => {
    currentEffectConfig.smoke.mode = e.target.value;
});

const smokeSyncMusic = document.getElementById('smoke-sync-music');
if (smokeSyncMusic) {
    smokeSyncMusic.addEventListener('change', (e) => {
        currentEffectConfig.smoke.syncWithMusic = e.target.checked;
        console.log('[DJ NUI] Smoke sync with music:', e.target.checked);
    });
}



// Confirm Effect Configuration
document.getElementById('confirm-effect-config').addEventListener('click', () => {
    console.log('[DJ NUI] Confirm button clicked');
    
    // Check if this is a reconfiguration or new placement
    if (window.reconfigureNetId) {
        // Reconfiguring existing effect
        console.log('[DJ NUI] Reconfiguring effect - NetId:', window.reconfigureNetId);
        console.log('[DJ NUI] New config:', currentEffectConfig);
        
        fetch(`https://${GetParentResourceName()}/reconfigureEffect`, {
            method: 'POST',
            body: JSON.stringify({
                netId: window.reconfigureNetId,
                effectConfig: currentEffectConfig
            })
        }).then(() => {
            console.log('[DJ NUI] reconfigureEffect sent successfully');
        }).catch(err => {
            console.error('[DJ NUI] Error sending reconfigureEffect:', err);
        });
        
        window.reconfigureNetId = null;
    } else if (pendingPropData) {
        // New placement
        console.log('[DJ NUI] Pending prop data:', pendingPropData);
        console.log('[DJ NUI] Current effect config:', currentEffectConfig);
        
        const payload = {
            prop: pendingPropData.prop,
            coords: pendingPropData.coords,
            heading: pendingPropData.heading,
            effectConfig: currentEffectConfig
        };
        
        console.log('[DJ NUI] Sending payload:', payload);
        
        fetch(`https://${GetParentResourceName()}/confirmPlacement`, {
            method: 'POST',
            body: JSON.stringify(payload)
        }).then(() => {
            console.log('[DJ NUI] confirmPlacement sent successfully');
        }).catch(err => {
            console.error('[DJ NUI] Error sending confirmPlacement:', err);
        });
        
        pendingPropData = null;
    } else {
        console.error('[DJ NUI] No pending prop data or reconfigure NetId!');
    }
    
    // Close modal
    document.getElementById('effect-config-modal').classList.add('hidden');
    app.classList.add('hidden');
    fetch(`https://${GetParentResourceName()}/close`, { method: 'POST' });
});

// Close Modal Button
document.querySelectorAll('.close-modal-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.getElementById('effect-config-modal').classList.add('hidden');
        pendingPropData = null;
    });
});

// Listen for openEffectConfig from client
window.addEventListener('message', (event) => {
    const data = event.data;
    
    if (data.type === 'openEffectConfig') {
        pendingPropData = data.propData;
        
        // Reset to lights tab by default
        currentEffectConfig.type = 'lights';
        document.querySelectorAll('.config-tab-btn').forEach(b => b.classList.remove('active'));
        document.querySelector('.config-tab-btn[data-config-tab="lights"]').classList.add('active');
        document.querySelectorAll('.config-panel').forEach(p => p.classList.remove('active'));
        document.getElementById('config-lights').classList.add('active');
        
        app.classList.remove('hidden');
        document.querySelectorAll('.interface-container').forEach(el => el.classList.add('hidden'));
        document.getElementById('effect-config-modal').classList.remove('hidden');
        
        console.log('[DJ NUI] Effect config modal opened, default type:', currentEffectConfig.type);
    } else if (data.type === 'openEffectReconfigure') {
        // Reconfigure existing effect
        window.reconfigureNetId = data.netId;
        const config = data.currentConfig;
        
        console.log('[DJ NUI] Opening reconfigure modal for NetId:', data.netId);
        console.log('[DJ NUI] Current config:', config);
        
        // Load current configuration
        if (config) {
            currentEffectConfig = JSON.parse(JSON.stringify(config)); // Deep copy
            
            // Switch to the correct tab
            const effectType = config.type || 'lights';
            document.querySelectorAll('.config-tab-btn').forEach(b => b.classList.remove('active'));
            document.querySelector(`.config-tab-btn[data-config-tab="${effectType}"]`).classList.add('active');
            document.querySelectorAll('.config-panel').forEach(p => p.classList.remove('active'));
            document.getElementById(`config-${effectType}`).classList.add('active');
            
            // Update UI controls with current values
            updateUIFromConfig(config);
        }
        
        app.classList.remove('hidden');
        document.querySelectorAll('.interface-container').forEach(el => el.classList.add('hidden'));
        document.getElementById('effect-config-modal').classList.remove('hidden');
    }
});

// Helper function to update UI controls from config
function updateUIFromConfig(config) {
    // Update lights controls
    if (config.lights) {
        const lightColor = document.getElementById('light-color');
        if (lightColor) lightColor.value = config.lights.color || '#00ffff';
        
        const lightMode = document.getElementById('light-mode');
        if (lightMode) lightMode.value = config.lights.mode || 'movinghead';
        
        const lightIntensity = document.getElementById('light-intensity');
        if (lightIntensity) {
            lightIntensity.value = config.lights.intensity || 5;
            document.getElementById('light-intensity-val').textContent = lightIntensity.value;
        }
        
        const lightSpeed = document.getElementById('light-speed');
        if (lightSpeed) {
            lightSpeed.value = config.lights.speed || 1;
            document.getElementById('light-speed-val').textContent = lightSpeed.value + 'x';
        }
        
        const lightSync = document.getElementById('light-sync-music');
        if (lightSync) lightSync.checked = config.lights.syncWithMusic || false;
    }
    
    // Update other effect types similarly...
    // (Add more as needed)
}


// ========================================
// MUSIC BEAT DETECTION & SYNCHRONIZATION
// ========================================

let audioContext = null;
let analyser = null;
let beatDetector = {
    enabled: false,
    bpm: 128,
    lastBeatTime: 0,
    beatThreshold: 0.8,
    energyHistory: [],
    maxHistoryLength: 43 // ~1 second at 60fps
};

// Initialize Audio Context for beat detection
function initAudioContext() {
    if (!audioContext) {
        audioContext = new (window.AudioContext || window.webkitAudioContext)();
        analyser = audioContext.createAnalyser();
        analyser.fftSize = 2048;
        analyser.smoothingTimeConstant = 0.8;
        
        console.log('[DJ Beat] Audio context initialized');
    }
}

// Simplified beat detection using volume analysis
function analyzeAudioVolume() {
    if (!analyser || !beatDetector.enabled) return 0;
    
    try {
        const bufferLength = analyser.frequencyBinCount;
        const dataArray = new Uint8Array(bufferLength);
        analyser.getByteFrequencyData(dataArray);
        
        // Calculate average volume
        let sum = 0;
        for (let i = 0; i < bufferLength; i++) {
            sum += dataArray[i];
        }
        return sum / bufferLength / 255; // Normalize to 0-1
    } catch (e) {
        return 0;
    }
}

// Detect beat from audio data
function detectBeat() {
    if (!analyser || !beatDetector.enabled) return false;
    
    const bufferLength = analyser.frequencyBinCount;
    const dataArray = new Uint8Array(bufferLength);
    analyser.getByteFrequencyData(dataArray);
    
    // Calculate energy in bass frequencies (0-250Hz)
    let bassEnergy = 0;
    const bassRange = Math.floor(bufferLength * 0.1); // First 10% of spectrum
    
    for (let i = 0; i < bassRange; i++) {
        bassEnergy += dataArray[i];
    }
    bassEnergy /= bassRange;
    
    // Normalize energy (0-1)
    const normalizedEnergy = bassEnergy / 255;
    
    // Add to history
    beatDetector.energyHistory.push(normalizedEnergy);
    if (beatDetector.energyHistory.length > beatDetector.maxHistoryLength) {
        beatDetector.energyHistory.shift();
    }
    
    // Calculate average energy
    const avgEnergy = beatDetector.energyHistory.reduce((a, b) => a + b, 0) / beatDetector.energyHistory.length;
    
    // Detect beat if current energy is significantly higher than average
    const currentTime = Date.now();
    const timeSinceLastBeat = currentTime - beatDetector.lastBeatTime;
    const minBeatInterval = (60000 / beatDetector.bpm) * 0.5; // Minimum time between beats
    
    if (normalizedEnergy > avgEnergy * beatDetector.beatThreshold && 
        timeSinceLastBeat > minBeatInterval) {
        beatDetector.lastBeatTime = currentTime;
        return true;
    }
    
    return false;
}

// Estimate BPM from beat intervals
let bpmHistory = [];
function updateBPM() {
    if (bpmHistory.length < 2) return;
    
    // Calculate intervals between beats
    let intervals = [];
    for (let i = 1; i < bpmHistory.length; i++) {
        intervals.push(bpmHistory[i] - bpmHistory[i-1]);
    }
    
    // Average interval
    const avgInterval = intervals.reduce((a, b) => a + b, 0) / intervals.length;
    
    // Convert to BPM
    const estimatedBPM = Math.round(60000 / avgInterval);
    
    // Validate BPM (typical range 60-180)
    if (estimatedBPM >= 60 && estimatedBPM <= 180) {
        beatDetector.bpm = estimatedBPM;
        console.log('[DJ Beat] Estimated BPM:', estimatedBPM);
    }
}

// Beat detection loop
let beatDetectionInterval = null;
function startBeatDetection() {
    if (beatDetectionInterval) return;
    
    beatDetector.enabled = true;
    console.log('[DJ Beat] Beat detection started');
    
    beatDetectionInterval = setInterval(() => {
        if (detectBeat()) {
            console.log('[DJ Beat] Beat detected!');
            
            // Add to BPM history
            bpmHistory.push(Date.now());
            if (bpmHistory.length > 8) {
                bpmHistory.shift();
                updateBPM();
            }
            
            // Send beat to client
            fetch(`https://${GetParentResourceName()}/musicBeat`, {
                method: 'POST',
                body: JSON.stringify({
                    bpm: beatDetector.bpm,
                    timestamp: Date.now()
                })
            });
        }
    }, 1000 / 60); // 60 FPS
}

function stopBeatDetection() {
    if (beatDetectionInterval) {
        clearTimeout(beatDetectionInterval); // Changed from clearInterval to clearTimeout
        clearInterval(beatDetectionInterval); // Also clear if it was an interval
        beatDetectionInterval = null;
        beatDetector.enabled = false;
        beatDetector.energyHistory = [];
        beatDetector.beatCount = 0;
        bpmHistory = [];
        console.log('[DJ Beat] ✓ Beat detection stopped');
    }
}

// Simplified beat system - sends beat at fixed BPM
function startSimpleBeatSystem(bpm) {
    stopBeatDetection(); // Stop any existing detection
    
    beatDetector.bpm = bpm || 128;
    beatDetector.enabled = true;
    beatDetector.beatCount = 0;
    
    console.log('[DJ Beat] 🎵 Starting beat system at', beatDetector.bpm, 'BPM');
    console.log('[DJ Beat] Beat interval:', (60000 / beatDetector.bpm).toFixed(2), 'ms');
    
    // Send initial state
    fetch(`https://${GetParentResourceName()}/updateMusicState`, {
        method: 'POST',
        body: JSON.stringify({
            playing: true,
            bpm: beatDetector.bpm
        })
    });
    
    // Send beat at regular intervals with precise timing
    const beatInterval = 60000 / beatDetector.bpm; // ms per beat
    let expectedTime = Date.now() + beatInterval;
    
    console.log('[DJ Beat] 📊 Beat system configuration:');
    console.log('[DJ Beat]   - BPM:', beatDetector.bpm);
    console.log('[DJ Beat]   - Beat interval:', beatInterval.toFixed(2), 'ms');
    console.log('[DJ Beat]   - First beat at:', new Date(expectedTime).toLocaleTimeString());
    
    function sendBeat() {
        console.log('[DJ Beat] 🔄 sendBeat() called - enabled:', beatDetector.enabled);
        
        if (!beatDetector.enabled) {
            console.log('[DJ Beat] ⚠️ Beat system disabled, stopping...');
            return;
        }
        
        const now = Date.now();
        const drift = now - expectedTime;
        
        beatDetector.beatCount++;
        const beatInBar = (beatDetector.beatCount % 4) + 1; // 1-4
        
        console.log('[DJ Beat] ♪ Sending Beat', beatInBar, '/4 | BPM:', beatDetector.bpm, '| Drift:', drift.toFixed(1), 'ms');
        
        const payload = {
            bpm: beatDetector.bpm,
            timestamp: now,
            beat: beatInBar,
            drift: drift
        };
        
        console.log('[DJ Beat] 📤 Payload:', JSON.stringify(payload));
        
        fetch(`https://${GetParentResourceName()}/musicBeat`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(payload)
        }).then(response => {
            console.log('[DJ Beat] ✓ Beat sent successfully, response:', response.status);
            return response.text();
        }).then(text => {
            console.log('[DJ Beat] 📥 Response body:', text);
        }).catch(err => {
            console.error('[DJ Beat] ✗ Error sending beat:', err);
            console.error('[DJ Beat] ✗ Error details:', err.message, err.stack);
        });
        
        // Calculate next beat time with drift correction
        expectedTime += beatInterval;
        const nextDelay = Math.max(0, expectedTime - Date.now());
        
        console.log('[DJ Beat] ⏱️ Next beat in:', nextDelay.toFixed(0), 'ms');
        console.log('[DJ Beat] 🔄 Scheduling next beat with setTimeout...');
        
        beatDetectionInterval = setTimeout(sendBeat, nextDelay);
        
        console.log('[DJ Beat] ✓ Next beat scheduled, timeout ID:', beatDetectionInterval);
    }
    
    // Start the beat loop
    console.log('[DJ Beat] 🚀 Starting beat loop...');
    beatDetectionInterval = setTimeout(sendBeat, beatInterval);
    console.log('[DJ Beat] ✓ Beat system started - First beat in', beatInterval.toFixed(0), 'ms');
}

// Override playAudio to include beat system
const originalPlayAudio = window.playAudio;
window.playAudio = function(deckId, url, startTime) {
    originalPlayAudio(deckId, url, startTime);
    
    // Start simple beat system with current BPM from slider
    setTimeout(() => {
        const currentBPM = bpmSlider ? parseInt(bpmSlider.value) : 128;
        console.log('[DJ Beat] Starting beat system with BPM:', currentBPM);
        startSimpleBeatSystem(currentBPM);
    }, 500);
};

// Override stopAudio to stop beat detection
const originalStopAudio = window.stopAudio;
window.stopAudio = function(deckId) {
    originalStopAudio(deckId);
    
    // Stop beat detection if both decks are stopped
    if (!decks.a.playing && !decks.b.playing) {
        stopBeatDetection();
        
        fetch(`https://${GetParentResourceName()}/updateMusicState`, {
            method: 'POST',
            body: JSON.stringify({
                playing: false,
                bpm: 0
            })
        });
    }
};

console.log('[DJ Beat] Beat detection system loaded');


// ============================================
// EFFECT MANAGER (Multiple Effects System)
// ============================================

let currentManagerNetId = null;
let currentEffectConfigs = {};

// Listen for openEffectManager message
window.addEventListener('message', (event) => {
    const data = event.data;
    
    if (data.type === 'openEffectManager') {
        currentManagerNetId = data.netId;
        currentEffectConfigs = data.effectConfigs || {};
        
        console.log('[DJ Manager] Opening effect manager for NetId:', data.netId);
        console.log('[DJ Manager] Current effects:', currentEffectConfigs);
        
        // Display effects list
        displayEffectsList(currentEffectConfigs);
        
        // Show manager modal
        app.classList.remove('hidden');
        document.querySelectorAll('.interface-container').forEach(el => el.classList.add('hidden'));
        document.getElementById('effect-manager-modal').classList.remove('hidden');
    }
});

// Display effects list
function displayEffectsList(effectConfigs) {
    const listContainer = document.getElementById('active-effects-list');
    listContainer.innerHTML = '';
    
    const effectsArray = Object.entries(effectConfigs);
    
    if (effectsArray.length === 0) {
        // Show no effects message
        listContainer.innerHTML = `
            <div class="no-effects-message">
                <i class="fa-solid fa-circle-info"></i>
                <p>Nenhum efeito ativo. Clique em "Adicionar Efeito" para começar.</p>
            </div>
        `;
        return;
    }
    
    // Display each effect
    effectsArray.forEach(([effectId, config]) => {
        const effectItem = createEffectItem(effectId, config);
        listContainer.appendChild(effectItem);
    });
}

// Create effect item element
function createEffectItem(effectId, config) {
    const div = document.createElement('div');
    div.className = 'effect-item';
    div.dataset.effectId = effectId;
    
    // Get effect info
    const effectInfo = getEffectInfo(config);
    
    div.innerHTML = `
        <div class="effect-info">
            <div class="effect-name">
                <i class="fa-solid ${effectInfo.icon} effect-icon-${config.type}"></i>
                ${effectInfo.name}
            </div>
            <div class="effect-details">
                ${effectInfo.details.map(detail => `
                    <div class="effect-detail-item">
                        <i class="fa-solid fa-circle"></i>
                        <span>${detail}</span>
                    </div>
                `).join('')}
            </div>
        </div>
        <div class="effect-actions">
            <button class="effect-btn edit-btn" data-effect-id="${effectId}">
                <i class="fa-solid fa-pen"></i> Editar
            </button>
            <button class="effect-btn remove-btn" data-effect-id="${effectId}">
                <i class="fa-solid fa-trash"></i> Remover
            </button>
        </div>
    `;
    
    // Add event listeners
    const editBtn = div.querySelector('.edit-btn');
    const removeBtn = div.querySelector('.remove-btn');
    
    editBtn.addEventListener('click', () => editEffect(effectId, config));
    removeBtn.addEventListener('click', () => removeEffect(effectId));
    
    return div;
}

// Get effect information for display
function getEffectInfo(config) {
    const type = config.type;
    const details = [];
    
    let name = 'Unknown Effect';
    let icon = 'fa-question';
    
    switch(type) {
        case 'lights':
            name = 'Stage Lights';
            icon = 'fa-lightbulb';
            if (config.lights) {
                details.push(`Mode: ${config.lights.mode || 'movinghead'}`);
                details.push(`Intensity: ${config.lights.intensity || 5}`);
                if (config.lights.syncWithMusic) details.push('♪ Synced');
            }
            break;
        case 'lasers':
            name = 'Laser Show';
            icon = 'fa-bolt';
            if (config.lasers) {
                details.push(`Pattern: ${config.lasers.pattern || 'beams'}`);
                details.push(`Count: ${config.lasers.count || 4}`);
                if (config.lasers.syncWithMusic) details.push('♪ Synced');
            }
            break;
        case 'smoke':
            name = 'Smoke Machine';
            icon = 'fa-smog';
            if (config.smoke) {
                details.push(`Mode: ${config.smoke.mode || 'continuous'}`);
                details.push(`Density: ${config.smoke.density || 1.0}`);
                if (config.smoke.syncWithMusic) details.push('♪ Synced');
            }
            break;
        case 'confetti':
            name = 'Confetti';
            icon = 'fa-star';
            if (config.confetti) {
                details.push(`Mode: ${config.confetti.mode || 'cannon'}`);
                details.push(`Style: ${config.confetti.style || 'colorful'}`);
                if (config.confetti.syncWithMusic) details.push('♪ Synced');
            }
            break;
        case 'bubbles':
            name = 'Bubbles';
            icon = 'fa-circle';
            if (config.bubbles) {
                details.push(`Mode: ${config.bubbles.mode || 'continuous'}`);
                details.push(`Size: ${config.bubbles.size || 'medium'}`);
            }
            break;
        case 'pyro':
            name = 'Pyrotechnics';
            icon = 'fa-fire';
            if (config.pyro) {
                details.push(`Type: ${config.pyro.type || 'flame'}`);
                details.push(`Intensity: ${config.pyro.intensity || 1.0}`);
                if (config.pyro.syncWithMusic) details.push('♪ Synced');
            }
            break;
        case 'co2':
            name = 'CO2 Jets';
            icon = 'fa-wind';
            if (config.co2) {
                details.push(`Mode: ${config.co2.mode || 'vertical'}`);
                details.push(`Intensity: ${config.co2.intensity || 1.0}`);
                if (config.co2.syncWithMusic) details.push('♪ Synced');
            }
            break;
        case 'uv':
            name = 'UV Lights';
            icon = 'fa-sun';
            if (config.uv) {
                details.push(`Pattern: ${config.uv.pattern || 'static'}`);
                details.push(`Intensity: ${config.uv.intensity || 1.0}`);
            }
            break;
    }
    
    return { name, icon, details };
}

// Add new effect
document.getElementById('add-new-effect-btn').addEventListener('click', () => {
    console.log('[DJ Manager] Adding new effect');
    
    // Close manager modal
    document.getElementById('effect-manager-modal').classList.add('hidden');
    
    // Open effect config modal for new effect
    pendingPropData = null; // Not placing new prop
    window.addingEffectToNetId = currentManagerNetId;
    
    // Reset to lights tab by default with proper structure
    currentEffectConfig = {
        type: 'lights',
        lights: {
            color: '#00ffff',
            mode: 'movinghead',
            intensity: 5,
            speed: 1.0,
            syncWithMusic: false
        }
    };
    
    document.querySelectorAll('.config-tab-btn').forEach(b => b.classList.remove('active'));
    document.querySelector('.config-tab-btn[data-config-tab="lights"]').classList.add('active');
    document.querySelectorAll('.config-panel').forEach(p => p.classList.remove('active'));
    document.getElementById('config-lights').classList.add('active');
    
    // Reset UI controls to default values
    document.getElementById('light-color').value = '#00ffff';
    document.getElementById('light-mode').value = 'movinghead';
    document.getElementById('light-intensity').value = 5;
    document.getElementById('light-intensity-val').textContent = '5';
    document.getElementById('light-speed').value = 1;
    document.getElementById('light-speed-val').textContent = '1.0x';
    document.getElementById('light-sync-music').checked = false;
    
    document.getElementById('effect-config-modal').classList.remove('hidden');
});

// Edit effect
function editEffect(effectId, currentConfig) {
    console.log('[DJ Manager] Editing effect:', effectId);
    
    // Close manager modal
    document.getElementById('effect-manager-modal').classList.add('hidden');
    
    // Open effect config modal with current config
    window.editingEffectId = effectId;
    window.editingEffectNetId = currentManagerNetId;
    
    // Load current configuration
    currentEffectConfig = JSON.parse(JSON.stringify(currentConfig)); // Deep copy
    
    // Switch to the correct tab
    const effectType = currentConfig.type || 'lights';
    document.querySelectorAll('.config-tab-btn').forEach(b => b.classList.remove('active'));
    document.querySelector(`.config-tab-btn[data-config-tab="${effectType}"]`).classList.add('active');
    document.querySelectorAll('.config-panel').forEach(p => p.classList.remove('active'));
    document.getElementById(`config-${effectType}`).classList.add('active');
    
    // Update UI controls with current values
    updateUIFromConfig(currentConfig);
    
    document.getElementById('effect-config-modal').classList.remove('hidden');
}

// Remove effect
function removeEffect(effectId) {
    console.log('[DJ Manager] Removing effect:', effectId);
    
    // Confirm removal
    if (!confirm('Tem certeza que deseja remover este efeito?')) {
        return;
    }
    
    // Send to client
    fetch(`https://${GetParentResourceName()}/removeEffect`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            netId: currentManagerNetId,
            effectId: effectId
        })
    });
    
    // Remove from local state
    delete currentEffectConfigs[effectId];
    
    // Update display
    displayEffectsList(currentEffectConfigs);
}

// Close manager modal
document.getElementById('close-manager-btn').addEventListener('click', () => {
    document.getElementById('effect-manager-modal').classList.add('hidden');
    app.classList.add('hidden');
    
    // Send close message to client
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
});

document.getElementById('close-effect-manager').addEventListener('click', () => {
    document.getElementById('effect-manager-modal').classList.add('hidden');
    app.classList.add('hidden');
    
    // Send close message to client
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
});

// Update confirm button to handle multiple effects
const originalConfirmHandler = document.getElementById('confirm-effect-config');
originalConfirmHandler.addEventListener('click', () => {
    console.log('[DJ Effect] Confirm button clicked');
    console.log('[DJ Effect] Current config:', currentEffectConfig);
    
    // Check if we're adding to existing prop
    if (window.addingEffectToNetId) {
        console.log('[DJ Effect] Adding effect to existing prop:', window.addingEffectToNetId);
        
        fetch(`https://${GetParentResourceName()}/addEffect`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                netId: window.addingEffectToNetId,
                effectConfig: currentEffectConfig
            })
        });
        
        window.addingEffectToNetId = null;
        document.getElementById('effect-config-modal').classList.add('hidden');
        app.classList.add('hidden');
        return;
    }
    
    // Check if we're editing existing effect
    if (window.editingEffectId && window.editingEffectNetId) {
        console.log('[DJ Effect] Updating effect:', window.editingEffectId);
        
        fetch(`https://${GetParentResourceName()}/updateEffect`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                netId: window.editingEffectNetId,
                effectId: window.editingEffectId,
                effectConfig: currentEffectConfig
            })
        });
        
        window.editingEffectId = null;
        window.editingEffectNetId = null;
        document.getElementById('effect-config-modal').classList.add('hidden');
        app.classList.add('hidden');
        return;
    }
    
    // Otherwise, it's a new prop placement (original behavior)
    // ... existing code continues ...
});

console.log('[DJ Manager] Effect manager system loaded');


// ============================================
// PLAYLIST SYSTEM
// ============================================

let playlist = {
    name: 'My Playlist',
    tracks: [],
    currentIndex: -1,
    shuffle: false,
    repeat: false,
    shuffleOrder: []
};

// Add track to playlist
document.getElementById('btn-add-track').addEventListener('click', () => {
    const urlInput = document.getElementById('new-track-url');
    const url = urlInput.value.trim();
    
    if (!url) {
        alert('Por favor, insira uma URL válida!');
        return;
    }
    
    if (!isValidMediaURL(url)) {
        alert('URL inválida! Use YouTube ou link direto de áudio.');
        return;
    }
    
    // Add to playlist
    playlist.tracks.push({
        url: url,
        type: getYouTubeID(url) ? 'youtube' : 'audio',
        addedAt: Date.now()
    });
    
    // Clear input
    urlInput.value = '';
    
    // Update display
    displayPlaylist();
    
    console.log('[DJ Playlist] Track added:', url);
    console.log('[DJ Playlist] Total tracks:', playlist.tracks.length);
});

// Display playlist
function displayPlaylist() {
    const container = document.getElementById('playlist-tracks');
    
    if (playlist.tracks.length === 0) {
        container.innerHTML = `
            <div class="no-tracks-message">
                <i class="fa-solid fa-music"></i>
                <p>Nenhuma música na playlist. Adicione URLs acima.</p>
            </div>
        `;
        return;
    }
    
    container.innerHTML = '';
    
    playlist.tracks.forEach((track, index) => {
        const trackEl = createTrackElement(track, index);
        container.appendChild(trackEl);
    });
}

// Create track element
function createTrackElement(track, index) {
    const div = document.createElement('div');
    div.className = 'track-item';
    div.dataset.index = index;
    
    if (index === playlist.currentIndex) {
        div.classList.add('playing');
    }
    
    const displayUrl = track.url.length > 50 ? track.url.substring(0, 50) + '...' : track.url;
    const typeIcon = track.type === 'youtube' ? 'fa-brands fa-youtube' : 'fa-solid fa-file-audio';
    const typeName = track.type === 'youtube' ? 'YouTube' : 'Audio File';
    
    div.innerHTML = `
        <div class="track-number">${index + 1}</div>
        <div class="track-info-item">
            <div class="track-url">${displayUrl}</div>
            <div class="track-type">
                <i class="${typeIcon}"></i>
                <span>${typeName}</span>
            </div>
        </div>
        <div class="track-actions">
            <button class="track-btn play-track" title="Tocar">
                <i class="fa-solid fa-play"></i>
            </button>
            <button class="track-btn move-up" title="Mover para cima">
                <i class="fa-solid fa-arrow-up"></i>
            </button>
            <button class="track-btn move-down" title="Mover para baixo">
                <i class="fa-solid fa-arrow-down"></i>
            </button>
            <button class="track-btn remove-track" title="Remover">
                <i class="fa-solid fa-trash"></i>
            </button>
        </div>
    `;
    
    // Add event listeners
    const playBtn = div.querySelector('.play-track');
    const moveUpBtn = div.querySelector('.move-up');
    const moveDownBtn = div.querySelector('.move-down');
    const removeBtn = div.querySelector('.remove-track');
    
    playBtn.addEventListener('click', () => playTrack(index));
    moveUpBtn.addEventListener('click', () => moveTrack(index, -1));
    moveDownBtn.addEventListener('click', () => moveTrack(index, 1));
    removeBtn.addEventListener('click', () => removeTrack(index));
    
    return div;
}

// Play track from playlist
function playTrack(index) {
    if (index < 0 || index >= playlist.tracks.length) return;
    
    const track = playlist.tracks[index];
    playlist.currentIndex = index;
    
    console.log('[DJ Playlist] Playing track', index + 1, '/', playlist.tracks.length);
    console.log('[DJ Playlist] URL:', track.url);
    
    // Play on Deck A by default
    const urlInput = document.getElementById('url-a');
    urlInput.value = track.url;
    
    // Trigger play
    handleDeckControl('a', 'play');
    
    // Update display
    displayPlaylist();
}

// Play next track
function playNextTrack() {
    if (playlist.tracks.length === 0) return;
    
    let nextIndex;
    
    if (playlist.shuffle) {
        // Shuffle mode
        if (playlist.shuffleOrder.length === 0) {
            // Generate new shuffle order
            playlist.shuffleOrder = Array.from({length: playlist.tracks.length}, (_, i) => i);
            shuffleArray(playlist.shuffleOrder);
        }
        
        const currentShuffleIndex = playlist.shuffleOrder.indexOf(playlist.currentIndex);
        const nextShuffleIndex = (currentShuffleIndex + 1) % playlist.shuffleOrder.length;
        nextIndex = playlist.shuffleOrder[nextShuffleIndex];
    } else {
        // Normal mode
        nextIndex = (playlist.currentIndex + 1) % playlist.tracks.length;
    }
    
    // Check repeat mode
    if (!playlist.repeat && nextIndex === 0 && playlist.currentIndex !== -1) {
        console.log('[DJ Playlist] Playlist ended (repeat off)');
        return;
    }
    
    playTrack(nextIndex);
}

// Move track in playlist
function moveTrack(index, direction) {
    const newIndex = index + direction;
    
    if (newIndex < 0 || newIndex >= playlist.tracks.length) return;
    
    // Swap tracks
    const temp = playlist.tracks[index];
    playlist.tracks[index] = playlist.tracks[newIndex];
    playlist.tracks[newIndex] = temp;
    
    // Update current index if needed
    if (playlist.currentIndex === index) {
        playlist.currentIndex = newIndex;
    } else if (playlist.currentIndex === newIndex) {
        playlist.currentIndex = index;
    }
    
    // Update display
    displayPlaylist();
    
    console.log('[DJ Playlist] Track moved from', index, 'to', newIndex);
}

// Remove track from playlist
function removeTrack(index) {
    if (!confirm('Remover esta música da playlist?')) return;
    
    playlist.tracks.splice(index, 1);
    
    // Update current index
    if (playlist.currentIndex === index) {
        playlist.currentIndex = -1;
    } else if (playlist.currentIndex > index) {
        playlist.currentIndex--;
    }
    
    // Update display
    displayPlaylist();
    
    console.log('[DJ Playlist] Track removed at index', index);
    console.log('[DJ Playlist] Remaining tracks:', playlist.tracks.length);
}

// Shuffle button
document.getElementById('btn-shuffle').addEventListener('click', () => {
    playlist.shuffle = !playlist.shuffle;
    const btn = document.getElementById('btn-shuffle');
    
    if (playlist.shuffle) {
        btn.classList.add('active');
        playlist.shuffleOrder = []; // Reset shuffle order
        console.log('[DJ Playlist] Shuffle enabled');
    } else {
        btn.classList.remove('active');
        console.log('[DJ Playlist] Shuffle disabled');
    }
});

// Repeat button
document.getElementById('btn-repeat').addEventListener('click', () => {
    playlist.repeat = !playlist.repeat;
    const btn = document.getElementById('btn-repeat');
    
    if (playlist.repeat) {
        btn.classList.add('active');
        console.log('[DJ Playlist] Repeat enabled');
    } else {
        btn.classList.remove('active');
        console.log('[DJ Playlist] Repeat disabled');
    }
});

// Save playlist
document.getElementById('btn-save-playlist').addEventListener('click', () => {
    const name = document.getElementById('playlist-name').value.trim() || 'My Playlist';
    playlist.name = name;
    
    const playlistData = {
        name: playlist.name,
        tracks: playlist.tracks,
        createdAt: Date.now()
    };
    
    // Convert to JSON
    const json = JSON.stringify(playlistData, null, 2);
    
    // Create download link
    const blob = new Blob([json], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${playlist.name.replace(/[^a-z0-9]/gi, '_')}.json`;
    a.click();
    URL.revokeObjectURL(url);
    
    console.log('[DJ Playlist] Playlist saved:', playlist.name);
    console.log('[DJ Playlist] Tracks:', playlist.tracks.length);
});

// Load playlist
document.getElementById('btn-load-playlist').addEventListener('click', () => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.json';
    
    input.onchange = (e) => {
        const file = e.target.files[0];
        if (!file) return;
        
        const reader = new FileReader();
        reader.onload = (event) => {
            try {
                const data = JSON.parse(event.target.result);
                
                if (!data.tracks || !Array.isArray(data.tracks)) {
                    alert('Arquivo de playlist inválido!');
                    return;
                }
                
                // Load playlist
                playlist.name = data.name || 'Loaded Playlist';
                playlist.tracks = data.tracks;
                playlist.currentIndex = -1;
                
                // Update UI
                document.getElementById('playlist-name').value = playlist.name;
                displayPlaylist();
                
                console.log('[DJ Playlist] Playlist loaded:', playlist.name);
                console.log('[DJ Playlist] Tracks:', playlist.tracks.length);
                
                alert(`Playlist "${playlist.name}" carregada com ${playlist.tracks.length} músicas!`);
            } catch (err) {
                console.error('[DJ Playlist] Error loading playlist:', err);
                alert('Erro ao carregar playlist!');
            }
        };
        reader.readAsText(file);
    };
    
    input.click();
});

// Playlist name input
document.getElementById('playlist-name').addEventListener('input', (e) => {
    playlist.name = e.target.value.trim() || 'My Playlist';
});

// Helper: Shuffle array
function shuffleArray(array) {
    for (let i = array.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [array[i], array[j]] = [array[j], array[i]];
    }
}

// Auto-play next track when current ends
// Override the original stopAudio to check for playlist
const originalStopAudioPlaylist = window.stopAudio;
window.stopAudio = function(deckId) {
    originalStopAudioPlaylist(deckId);
    
    // If Deck A stopped and we have a playlist, play next
    if (deckId === 'a' && playlist.tracks.length > 0 && playlist.currentIndex !== -1) {
        console.log('[DJ Playlist] Track ended, playing next...');
        setTimeout(() => {
            playNextTrack();
        }, 1000);
    }
};

// Listen for track end from Howler
const originalPlayAudioPlaylist = window.playAudio;
window.playAudio = function(deckId, url, startTime) {
    const metaEl = document.getElementById(`meta-${deckId}`);
    const timeEl = document.getElementById(`time-${deckId}`);

    // Stop existing
    if (decks[deckId].type === 'howler' && decks[deckId].howl) {
        decks[deckId].howl.unload();
    } else if (decks[deckId].type === 'youtube' && decks[deckId].yt) {
        decks[deckId].yt.stopVideo();
    }

    decks[deckId].url = url;
    decks[deckId].playing = true;

    const ytId = getYouTubeID(url);

    if (ytId) {
        // YouTube Mode
        decks[deckId].type = 'youtube';
        metaEl.innerText = "🎵 Carregando: YouTube - " + ytId;
        metaEl.style.color = "#ffff00";

        if (decks[deckId].yt && decks[deckId].yt.loadVideoById) {
            decks[deckId].yt.loadVideoById(ytId, startTime);
            decks[deckId].yt.setVolume(decks[deckId].volume * 100);
            
            setTimeout(() => {
                metaEl.innerText = "♪ YouTube: " + ytId;
                metaEl.style.color = "#00ff00";
            }, 2000);
        } else {
            metaEl.innerText = "⚠️ YouTube Player Not Ready";
            metaEl.style.color = "#ff0000";
        }
    } else {
        // Howler Mode
        decks[deckId].type = 'howler';
        const displayName = getURLDisplayName(url);
        metaEl.innerText = "🎵 Carregando: " + displayName;
        metaEl.style.color = "#ffff00";

        decks[deckId].howl = new Howl({
            src: [url],
            html5: true,
            volume: decks[deckId].volume,
            onload: function () {
                metaEl.innerText = "♪ " + displayName;
                metaEl.style.color = "#00ff00";
                console.log(`[DJ] ✓ Audio loaded on Deck ${deckId}: ${displayName}`);
            },
            onplay: function () {
                console.log(`[DJ] ✓ Audio playing on Deck ${deckId}`);
            },
            onend: function () {
                document.getElementById(`deck-${deckId}`).classList.remove('playing');
                metaEl.innerText = "⏹️ Track Ended";
                metaEl.style.color = "#888888";
                
                // Auto-play next track if playlist is active
                if (deckId === 'a' && playlist.tracks.length > 0 && playlist.currentIndex !== -1) {
                    console.log('[DJ Playlist] Track ended, playing next...');
                    setTimeout(() => {
                        playNextTrack();
                    }, 1000);
                }
            },
            onloaderror: function (id, err) {
                console.error(`[DJ] ✗ Load Error on Deck ${deckId}:`, err);
                metaEl.innerText = "⚠️ Erro ao carregar áudio";
                metaEl.style.color = "#ff0000";
            },
            onplayerror: function (id, err) {
                console.error(`[DJ] ✗ Play Error on Deck ${deckId}:`, err);
                metaEl.innerText = "⚠️ Erro ao reproduzir";
                metaEl.style.color = "#ff0000";
            }
        });
        decks[deckId].howl.play();
        if (startTime > 0) decks[deckId].howl.seek(startTime);
    }

    document.getElementById(`deck-${deckId}`).classList.add('playing');

    // Timer Loop
    if (decks[deckId].timer) clearInterval(decks[deckId].timer);
    decks[deckId].timer = setInterval(() => {
        let currentTime = 0;
        let duration = 0;

        if (decks[deckId].type === 'youtube' && decks[deckId].yt && decks[deckId].yt.getCurrentTime) {
            currentTime = decks[deckId].yt.getCurrentTime();
            duration = decks[deckId].yt.getDuration();
        } else if (decks[deckId].type === 'howler' && decks[deckId].howl && decks[deckId].howl.playing()) {
            currentTime = decks[deckId].howl.seek();
            duration = decks[deckId].howl.duration();
        }

        const displayName = getURLDisplayName(url);
        timeEl.innerHTML = `
            <div style="font-size: 0.85em; color: #00f2ff; margin-bottom: 2px;">
                ${displayName}
            </div>
            <div style="font-size: 1em;">
                ${formatTime(currentTime)} / ${formatTime(duration)}
            </div>
        `;
    }, 1000);
    
    // Start beat system
    setTimeout(() => {
        const currentBPM = bpmSlider ? parseInt(bpmSlider.value) : 128;
        console.log('[DJ Beat] Starting beat system with BPM:', currentBPM);
        startSimpleBeatSystem(currentBPM);
    }, 500);
};

console.log('[DJ Playlist] Playlist system loaded');
