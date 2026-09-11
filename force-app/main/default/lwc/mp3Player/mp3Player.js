import { LightningElement, api, wire, track } from 'lwc';
import getAudioAttachments from '@salesforce/apex/Mp3PlayerController.getAudioAttachments';

export default class Mp3Player extends LightningElement {
    // Auto-populated when placed on a record page
    @api recordId;

    // Optional: used only if no attachments are found on the record
    @api audioUrl;

    @track tracks = [];
    @track currentIndex = 0;
    @track currentTime = 0;
    @track duration = 0;
    @track isPlaying = false;
    @track volume = 1;
    @track isLoading = true;
    @track loadError = false;

    @wire(getAudioAttachments, { recordId: '$recordId' })
    wiredTracks({ data, error }) {
        this.isLoading = false;
        if (data) {
            this.tracks = data;
            this.loadError = false;
        } else if (error) {
            this.loadError = true;
            this.tracks = [];
        }
    }

    get audioElement() {
        return this.template.querySelector('audio');
    }

    get hasTracks() {
        return this.tracks && this.tracks.length > 0;
    }

    get hasAudio() {
        return this.hasTracks || !!this.audioUrl;
    }

    get showTrackList() {
        return this.tracks && this.tracks.length > 1;
    }

    get currentTrack() {
        return this.hasTracks ? this.tracks[this.currentIndex] : null;
    }

    get resolvedAudioUrl() {
        return this.currentTrack ? this.currentTrack.url : this.audioUrl;
    }

    get playerTitle() {
        return this.currentTrack ? this.currentTrack.name : 'MP3 Player';
    }

    get displayTracks() {
        return this.tracks.map((t, idx) => ({
            ...t,
            key: t.id,
            rowClass: idx === this.currentIndex ? 'track-row active' : 'track-row'
        }));
    }

    get playIcon() {
        return this.isPlaying ? 'utility:pause' : 'utility:play';
    }

    get playLabel() {
        return this.isPlaying ? 'Pause' : 'Play';
    }

    get progressPercent() {
        if (!this.duration) return 0;
        return (this.currentTime / this.duration) * 100;
    }

    get currentTimeDisplay() {
        return this.formatTime(this.currentTime);
    }

    get durationDisplay() {
        return this.formatTime(this.duration);
    }

    formatTime(seconds) {
        if (!seconds || isNaN(seconds)) return '0:00';
        const m = Math.floor(seconds / 60);
        const s = Math.floor(seconds % 60)
            .toString()
            .padStart(2, '0');
        return `${m}:${s}`;
    }

    handlePlayPause() {
        const audio = this.audioElement;
        if (!audio) return;
        if (this.isPlaying) {
            audio.pause();
            this.isPlaying = false;
        } else {
            audio.play();
            this.isPlaying = true;
        }
    }

    handleTrackClick(event) {
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        if (idx === this.currentIndex) {
            this.handlePlayPause();
            return;
        }
        this.currentIndex = idx;
        this.currentTime = 0;
        this.isPlaying = false;
        Promise.resolve().then(() => this.playCurrent());
    }

    handleLoadedMetadata(event) {
        this.duration = event.target.duration;
    }

    handleTimeUpdate(event) {
        this.currentTime = event.target.currentTime;
    }

    handleEnded() {
        this.isPlaying = false;
        this.currentTime = 0;
        if (this.hasTracks && this.currentIndex < this.tracks.length - 1) {
            this.currentIndex += 1;
            Promise.resolve().then(() => this.playCurrent());
        }
    }

    handleSeek(event) {
        const audio = this.audioElement;
        if (!audio || !this.duration) return;
        const pct = parseFloat(event.target.value);
        const newTime = (pct / 100) * this.duration;
        audio.currentTime = newTime;
        this.currentTime = newTime;
    }

    handleVolumeChange(event) {
        const vol = parseFloat(event.target.value);
        this.volume = vol;
        const audio = this.audioElement;
        if (audio) {
            audio.volume = vol;
        }
    }

    playCurrent() {
        const audio = this.audioElement;
        if (audio) {
            audio.play();
            this.isPlaying = true;
        }
    }
}