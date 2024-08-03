import { Controller } from "@hotwired/stimulus";
import consumer from "../channels/consumer";

// Connects to data-controller="timer"
export default class extends Controller {
	static targets = ["countdown", "overlay", "overlayButton", "startButton"];

	connect() {
		console.log("connected to timer controller.js", this.element);

		this.channel = consumer.subscriptions.create("TimerChannel", {
			received: (data) => {
				if (data.action === "start_timer") {
					this.startCountdown(data.duration);
				}
			},
		});
	}

	startTimer() {
		const countdownDuration = 5; // Set the countdown duration here

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

		this.startButtonTarget.disabled = true;
		// Change the button to secondary style
		this.startButtonTarget.classList.remove("btn-primary");
		this.startButtonTarget.classList.add("btn-secondary");
		console.log("button clicked!");
	}

	startCountdown(duration) {
		if (!this.hasCountdownTarget) return;

		this.timer = duration;
		this.interval = setInterval(() => {
			this.countdownTarget.textContent = this.timer;

			if (--this.timer < 0) {
				clearInterval(this.interval);
				this.showOverlay();
			}
		}, 1000);
	}

	showOverlay() {
		this.overlayTarget.style.display = "flex";
	}

	hideOverlay() {
		this.overlayTarget.style.display = "none";
	}
}
