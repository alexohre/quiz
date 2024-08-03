function createConfetti(x, y, color, duration) {
	const confetti = document.createElement("div");
	confetti.classList.add("confetti");
	confetti.style.backgroundColor = color;
	confetti.style.left = "50%";
	confetti.style.top = "50%";
	confetti.style.width = "3px"; // Thin width
	confetti.style.height = `${Math.random() * 20 + 10}px`; // Random height
	confetti.style.setProperty("--x", `${(Math.random() - 0.5) * 400}px`);
	confetti.style.setProperty("--y", `${(Math.random() - 0.5) * 400}px`);
	confetti.style.animation = `zigzag ${duration}s linear`;
	document.getElementById("buzzer").appendChild(confetti);

	confetti.addEventListener("animationend", () => {
		confetti.remove();
	});
}

function generateConfetti() {
	const colors = [
		"#f5b542",
		"#ff6347",
		"#ffa07a",
		"#ff4500",
		"#ff1493",
		"#7fff00",
		"#00ff7f",
	];
	const duration = 1.5; // Duration of the confetti animation

	for (let i = 0; i < 100; i++) {
		const color = colors[Math.floor(Math.random() * colors.length)];
		createConfetti(0, 0, color, duration);
	}
}

document
	.getElementById("buzzer")
	.addEventListener("animationiteration", generateConfetti);

// Generate confetti initially and then repeat on each animation iteration
generateConfetti();
