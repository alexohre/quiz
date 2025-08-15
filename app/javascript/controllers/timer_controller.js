import { Controller } from "@hotwired/stimulus";
import consumer from "../channels/consumer";

// Connects to data-controller="timer"
export default class extends Controller {
	static targets = ["countdown", "overlay", "overlayButton", "startButton"];

	connect() {
		console.log("connected to timer controller.js", this.element);

		// Read timer value from data attribute
		this.timerDuration = this.element.dataset.timerDuration || 0;
		console.log("Timer duration from data attribute:", this.timerDuration);

		this.channel = consumer.subscriptions.create("TimerChannel", {
			connected: () => {
				console.log("Timer controller connected to TimerChannel");
			},
			disconnected: () => {
				console.log("Timer controller disconnected from TimerChannel");
			},
			received: (data) => {
				console.log("Timer channel received data:", data);
				if (data.action === "start_timer") {
					console.log("Starting timer with duration:", data.duration);
					this.startCountdown(data.duration);
				} else {
					console.log("Unknown action received:", data.action);
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
		console.log("Manual timer start requested with duration:", countdownDuration);

		// Disable the start button immediately when clicked
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

		console.log("Manual start button clicked and disabled!");
	}

	startCountdown(duration) {
		if (!this.hasCountdownTarget) {
			console.log("No countdown target found, cannot start timer");
			return;
		}

		console.log("Starting countdown with duration:", duration);
		
		// Clear any existing interval
		if (this.interval) {
			clearInterval(this.interval);
		}

		this.timer = duration;
		this.totalDuration = duration;
		
		// Reset countdown styling
		this.countdownTarget.classList.remove('warning', 'danger');
		
		// Display initial value
		this.countdownTarget.textContent = this.timer;
		this.updateCountdownStyling();
		
		this.interval = setInterval(() => {
			this.timer--;
			
			if (this.timer < 0) {
				clearInterval(this.interval);
				this.countdownTarget.textContent = "0";
				this.updateCountdownStyling();
				this.showOverlay();
			} else {
				this.countdownTarget.textContent = this.timer;
				this.updateCountdownStyling();
			}
		}, 1000);
	}

	showOverlay() {
		this.overlayTarget.style.display = "flex";
	}

	hideOverlay() {
		this.overlayTarget.style.display = "none";
	}

	updateCountdownStyling() {
		if (!this.totalDuration) {
			return;
		}

		// Calculate remaining time percentage
		const progress = Math.max(0, this.timer) / this.totalDuration;
		const timePercentage = progress * 100;
		
		// Remove existing classes
		this.countdownTarget.classList.remove('warning', 'danger');
		
		if (timePercentage <= 10) {
			// Last 10% - Red/Danger with shake animation
			this.countdownTarget.classList.add('danger');
		} else if (timePercentage <= 25) {
			// Last 25% - Yellow/Warning
			this.countdownTarget.classList.add('warning');
		}
		// Above 25% stays default (white)
	}
}
