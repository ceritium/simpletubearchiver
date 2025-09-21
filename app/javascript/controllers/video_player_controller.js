import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="video-player"
export default class extends Controller {
    static targets = ["thumbnail", "video"]
    static values = { videoId: Number }

    connect() {
        console.log("Video player controller connected")
        this.setupVideoEventListeners()
    }

    setupVideoEventListeners() {
        if (this.hasVideoTarget) {
            // Load saved settings when video metadata is loaded
            this.videoTarget.addEventListener('loadedmetadata', () => {
                this.loadVideoSettings()
            })

            // Save progress periodically while playing
            this.videoTarget.addEventListener('timeupdate', () => {
                this.saveVideoProgress()
            })

            // Save volume and muted state when changed
            this.videoTarget.addEventListener('volumechange', () => {
                this.saveVolumeSettings()
                this.saveMutedState()
            })

            // Save final progress when video ends or is paused
            this.videoTarget.addEventListener('pause', () => {
                this.saveVideoProgress()
            })

            this.videoTarget.addEventListener('ended', () => {
                this.clearVideoProgress() // Clear progress when video finishes
            })
        }
    }

    playVideo() {
        // Hide the thumbnail with a smooth fade effect
        this.thumbnailTarget.style.transition = "opacity 0.3s ease-in-out"
        this.thumbnailTarget.style.opacity = "0"

        // After fade out, hide thumbnail and show video
        setTimeout(() => {
            this.thumbnailTarget.style.display = "none"
            this.videoTarget.style.display = "block"
            this.videoTarget.style.opacity = "0"

            // Fade in the video
            requestAnimationFrame(() => {
                this.videoTarget.style.transition = "opacity 0.3s ease-in-out"
                this.videoTarget.style.opacity = "1"

                // Load settings and start playing
                this.loadVideoSettings()
                this.videoTarget.play()
            })
        }, 300)
    }

    loadVideoSettings() {
        const videoId = this.videoIdValue
        if (!videoId) return

        // Load volume setting
        const savedVolume = localStorage.getItem(`video_${videoId}_volume`)
        if (savedVolume !== null) {
            this.videoTarget.volume = parseFloat(savedVolume)
        }

        // Load muted state
        const savedMuted = localStorage.getItem(`video_${videoId}_muted`)
        if (savedMuted !== null) {
            this.videoTarget.muted = savedMuted === 'true'
        }

        // Load progress
        const savedProgress = localStorage.getItem(`video_${videoId}_progress`)
        if (savedProgress !== null) {
            const progress = parseFloat(savedProgress)
            // Only restore progress if it's more than 5 seconds and less than 95% of the video
            if (progress > 5 && progress < (this.videoTarget.duration * 0.95)) {
                this.videoTarget.currentTime = progress
                this.showProgressNotification(progress)
            }
        }
    }

    saveVideoProgress() {
        const videoId = this.videoIdValue
        if (!videoId || !this.videoTarget.duration) return

        // Only save if we're more than 5 seconds in
        if (this.videoTarget.currentTime > 5) {
            localStorage.setItem(`video_${videoId}_progress`, this.videoTarget.currentTime.toString())
        }
    }

    saveVolumeSettings() {
        const videoId = this.videoIdValue
        if (!videoId) return

        localStorage.setItem(`video_${videoId}_volume`, this.videoTarget.volume.toString())
    }

    saveMutedState() {
        const videoId = this.videoIdValue
        if (!videoId) return

        localStorage.setItem(`video_${videoId}_muted`, this.videoTarget.muted.toString())
    }

    clearVideoProgress() {
        const videoId = this.videoIdValue
        if (!videoId) return

        localStorage.removeItem(`video_${videoId}_progress`)
    }

    showProgressNotification(progress) {
        // Create a temporary notification to inform user about restored progress
        const notification = document.createElement('div')
        notification.className = 'alert alert-info alert-dismissible fade show position-fixed'
        notification.style.cssText = 'top: 20px; right: 20px; z-index: 1050; max-width: 300px;'
        notification.innerHTML = `
      <small>
        <i class="bi bi-info-circle me-2"></i>
        Resumed from ${this.formatTime(progress)}
      </small>
      <button type="button" class="btn-close btn-close-sm" data-bs-dismiss="alert"></button>
    `

        document.body.appendChild(notification)

        // Auto-remove after 3 seconds
        setTimeout(() => {
            if (notification.parentNode) {
                notification.remove()
            }
        }, 3000)
    }

    formatTime(seconds) {
        const minutes = Math.floor(seconds / 60)
        const secs = Math.floor(seconds % 60)
        return `${minutes}:${secs.toString().padStart(2, '0')}`
    }
}