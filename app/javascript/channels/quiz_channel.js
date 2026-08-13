import consumer from "./consumer";

consumer.subscriptions.create("QuizChannel", {
	connected() {
		console.log("Connected to QuizChannel");
	},

	disconnected() {
		console.log("Disconnected from QuizChannel");
	},

	received(data) {
		// 1. Quiz Question updates
		if (data.html) {
			const quizElement = document.getElementById("quiz_content");
			if (quizElement) {
				quizElement.innerHTML = data.html;
			}
		}

		// 2. Live Score Updates via ActionCable
		if (data.type === "score_update") {
			const userRole = document.body.dataset.userRole;

			// Live update Stage & Round table cells if on scoreboard page
			const stageRoundCell = document.getElementById(`stage_round_score_${data.church_id}_${data.stage_id}_${data.round_number}`);
			if (stageRoundCell) {
				const bonusText = data.bonus_points > 0 ? `<small class="text-warning-emphasis ms-1">(+${data.bonus_points})</small>` : '';
				stageRoundCell.innerHTML = `<span class="badge bg-primary bg-opacity-10 text-primary border border-primary-subtle px-3 py-1 fw-bold fs-6">${data.round_total} ${bonusText}</span>`;
			}

			const grandTotalCell = document.getElementById(`grand_total_${data.church_id}`);
			if (grandTotalCell) {
				grandTotalCell.textContent = `${data.grand_total} pts`;
			}

			// Notify on screens EXCEPT presenter screen
			if (userRole !== "presenter") {
				showScoreNotification(data);
			}
		}

		if (data.type === "scores_reset") {
			if (window.location.pathname.includes("/scoreboard") || window.location.pathname.includes("/recorder")) {
				window.location.reload();
			}
		}
	},
});

function showScoreNotification(data) {
	let container = document.getElementById("actioncable-toast-container");
	if (!container) {
		container = document.createElement("div");
		container.id = "actioncable-toast-container";
		container.className = "position-fixed top-0 end-0 p-3";
		container.style.zIndex = "1095";
		container.style.marginTop = "75px";
		container.style.maxWidth = "400px";
		document.body.appendChild(container);
	}

	const toastEl = document.createElement("div");
	toastEl.className = "toast align-items-center text-white bg-dark border-0 show shadow-lg rounded-4 overflow-hidden mb-2";
	toastEl.setAttribute("role", "alert");
	toastEl.innerHTML = `
		<div class="d-flex p-2 align-items-center">
			<div class="toast-body d-flex align-items-center gap-3 fs-6 py-1">
				<i class="bi bi-award-fill fs-3 text-warning"></i>
				<div>
					<strong class="d-block text-warning" style="font-size: 0.8rem; letter-spacing: 0.5px; text-transform: uppercase;">Live Score Update</strong>
					<span style="font-size: 0.9rem; font-weight: 500;"><strong>${data.church_name}</strong>: ${data.round_total} pts in ${data.stage_name} (Round ${data.round_number})</span>
				</div>
			</div>
			<button type="button" class="btn-close btn-close-white me-2 m-auto" onclick="this.closest('.toast').remove()"></button>
		</div>
	`;

	container.appendChild(toastEl);

	setTimeout(() => {
		if (toastEl && toastEl.parentNode) {
			toastEl.remove();
		}
	}, 4500);
}
