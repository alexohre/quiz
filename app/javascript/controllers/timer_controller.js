import { Controller } from "@hotwired/stimulus";
import consumer from "../channels/consumer";

// Connects to data-controller="timer"
export default class extends Controller {
	static targets = ["countdown", "overlay", "overlayButton", "startButton"];

	connect() {
		console.log("connected to timer controller.js", this.element);

		// Read timer value from data attribute
		this.timerDuration = this.element.dataset.timerDuration || 0;

		this.channel = consumer.subscriptions.create("TimerChannel", {
			connected: () => {
				console.log("Timer controller connected to TimerChannel");
			},
			disconnected: () => {
				console.log("Timer controller disconnected from TimerChannel");
			},
			received: (data) => {
				if (data.action === "start_timer") {
					this.startCountdown(data.duration);
				}
			},
		});
	}

	disconnect() {
		if (this.channel) {
			this.channel.unsubscribe();
		}
		if (this.interval) {
			clearInterval(this.interval);
		}
	}

	startTimer() {
		const countdownDuration = parseInt(this.timerDuration, 10);

		if (this.hasStartButtonTarget) {
			this.startButtonTarget.disabled = true;
			this.startButtonTarget.classList.remove("btn-primary", "btn-success");
			this.startButtonTarget.classList.add("btn-secondary");
		}

		fetch("/start_timer", {
			method: "POST",
			headers: {
				"Content-Type": "application/json",
				"X-CSRF-Token": document
					.querySelector('meta[name="csrf-token"]')
					.getAttribute("content"),
			},
			body: JSON.stringify({ duration: countdownDuration }),
		});
	}

	startCountdown(duration) {
		if (!this.hasCountdownTarget) {
			return;
		}
		
		if (this.interval) {
			clearInterval(this.interval);
		}

		this.timer = duration;
		this.totalDuration = duration;
		
		this.countdownTarget.classList.remove('warning', 'danger', 'text-danger', 'text-warning');
		this.countdownTarget.textContent = this.timer;
		this.updateCountdownStyling();
		
		this.interval = setInterval(() => {
			this.timer--;
			
			if (this.timer < 0) {
				clearInterval(this.interval);
				if (this.hasOverlayTarget) {
					this.countdownTarget.textContent = "0";
					this.showOverlay();
				} else {
					this.countdownTarget.textContent = "TIME UP!";
				}
				this.updateCountdownStyling();
			} else {
				this.countdownTarget.textContent = this.timer;
				this.updateCountdownStyling();
			}
		}, 1000);
	}

	showOverlay() {
		if (this.hasOverlayTarget) {
			this.overlayTarget.style.display = "flex";
		}
	}

	hideOverlay() {
		if (this.hasOverlayTarget) {
			this.overlayTarget.style.display = "none";
		}
	}

	updateCountdownStyling() {
		if (!this.totalDuration) {
			return;
		}

		const progress = Math.max(0, this.timer) / this.totalDuration;
		const timePercentage = progress * 100;
		
		this.countdownTarget.classList.remove('warning', 'danger', 'text-danger', 'text-warning');
		
		if (this.timer < 0 || this.timer === 0 || this.countdownTarget.textContent === "TIME UP!") {
			this.countdownTarget.classList.add('danger', 'text-danger');
		} else if (timePercentage <= 15 || this.timer <= 5) {
			this.countdownTarget.classList.add('danger', 'text-danger');
		} else if (timePercentage <= 35) {
			this.countdownTarget.classList.add('warning', 'text-warning');
		}
	}
}
