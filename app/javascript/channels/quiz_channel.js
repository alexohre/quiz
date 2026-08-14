import consumer from "./consumer";

consumer.subscriptions.create("QuizChannel", {
	connected() {
		console.log("Connected to QuizChannel");
	},

	disconnected() {
		console.log("Disconnected from QuizChannel");
	},

	received(data) {
		// 1. Quiz Question updates on Presenter/Quiz content
		if (data.html) {
			const quizElement = document.getElementById("quiz_content");
			if (quizElement) {
				quizElement.innerHTML = data.html;
			}
		}

		// 2. Question Queued Event (Live Recorder Queue & Activation - ignore already answered questions)
		if (data.type === "question_queued" && !data.already_answered) {
			if (window.location.pathname.includes("/recorder")) {
				const activeQuizInput = document.querySelector("input[name='quiz_id']");
				const activeQuizId = activeQuizInput ? activeQuizInput.value : null;

				const waitingPlaceholder = document.getElementById("waitingForQuestionPlaceholder");
				const isWaiting = waitingPlaceholder && !waitingPlaceholder.classList.contains("d-none");

				// If recorder currently has NO active question or is waiting
				if (!activeQuizId || isWaiting || activeQuizId === "null" || activeQuizId === "") {
					updateActiveQuestionDOM(data);
				} else {
					// Recorder is busy with previous question -> Add to Queue Pill Bar & notify
					appendQuestionToQueuePillBar(data, false);
					showQueueNotification(data);
				}
			}
		}

		// 3. Live Score Updates via ActionCable
		if (data.type === "score_update") {
			const userRole = document.body.dataset.userRole;

			let cellText = "";
			if (data.points === 0 && data.bonus_points > 0) {
				cellText = `0 + ${data.bonus_points}`;
			} else if (data.points > 0 && data.bonus_points > 0) {
				cellText = `${data.points} + ${data.bonus_points}`;
			} else {
				cellText = `${data.round_total}`;
			}

			// Live update Stage & Round table cells if on scoreboard page
			const stageRoundCell = document.getElementById(`stage_round_score_${data.church_id}_${data.stage_id}_${data.round_number}`);
			if (stageRoundCell) {
				stageRoundCell.innerHTML = `<span class="badge bg-primary bg-opacity-10 text-primary border border-primary-subtle px-3 py-1 fw-bold fs-6">${cellText}</span>`;
			}

			const grandTotalCell = document.getElementById(`grand_total_${data.church_id}`);
			if (grandTotalCell) {
				grandTotalCell.textContent = `${data.grand_total} pts`;
			}

			// Live update Modal Table cells if presenter modal is open
			const modalRoundCell = document.getElementById(`modal_stage_round_score_${data.church_id}_${data.stage_id}_${data.round_number}`);
			if (modalRoundCell) {
				modalRoundCell.innerHTML = `<span class="badge bg-primary bg-opacity-10 text-primary border border-primary-subtle px-2 py-1 fw-bold">${cellText}</span>`;
			}

			const modalStageTotalCell = document.getElementById(`modal_stage_total_${data.church_id}_${data.stage_id}`);
			if (modalStageTotalCell) {
				modalStageTotalCell.textContent = `${data.stage_total} pts`;
			}

			const modalGrandTotalCell = document.getElementById(`modal_grand_total_${data.church_id}`);
			if (modalGrandTotalCell) {
				modalGrandTotalCell.textContent = `${data.grand_total} pts`;
			}

			// Notify on screens EXCEPT presenter and judges screen (judges use live ticker news feed)
			if (userRole !== "presenter" && userRole !== "judges" && !window.location.pathname.includes("/judges")) {
				showScoreNotification(data);
			}
		}

		if (data.type === "ticker_feed" && data.message) {
			updateNewsTickerFeed(data.message);
		}

		if (data.type === "scores_reset") {
			if (window.location.pathname.includes("/scoreboard") || window.location.pathname.includes("/recorder")) {
				window.location.reload();
			}
		}
	},
});

let liveFeedTimeout = null;

function updateNewsTickerFeed(message) {
	const feedContainer = document.getElementById("quizLiveFeedContainer");
	const feedMarquee = document.getElementById("quizLiveFeedMarquee");

	if (feedContainer && feedMarquee) {
		feedMarquee.innerHTML = `<i class="bi bi-lightning-fill text-warning me-1.5"></i> ${message}`;

		// Reset CSS animation
		feedMarquee.classList.remove("ticker-scroll-active");
		void feedMarquee.offsetWidth;

		// Unhide container & activate left marquee scroll
		feedContainer.classList.remove("d-none");
		feedMarquee.classList.add("ticker-scroll-active");

		if (liveFeedTimeout) {
			clearTimeout(liveFeedTimeout);
		}

		// Hide container once single left scroll finishes (8.5 seconds)
		liveFeedTimeout = setTimeout(() => {
			if (feedContainer) {
				feedContainer.classList.add("d-none");
				feedMarquee.classList.remove("ticker-scroll-active");
			}
		}, 8500);
	}
}

function updateActiveQuestionDOM(data) {
	const badge = document.getElementById("activeQuestionBadge");
	const stageBadge = document.getElementById("activeQuestionStageBadge");
	const textEl = document.getElementById("activeQuestionText");
	const skipWrapper = document.getElementById("skipButtonWrapper");
	const scoreContainer = document.getElementById("scoreEntryContainer");
	const waitingPlaceholder = document.getElementById("waitingForQuestionPlaceholder");
	const banner = document.getElementById("recorderActiveQuestionBanner");
	const iconBox = document.getElementById("questionIconBox");

	if (badge) {
		badge.textContent = `Queue Item #${data.question_number} (Active)`;
		badge.className = "badge bg-warning text-dark fw-bold text-uppercase";
	}
	if (stageBadge) stageBadge.textContent = data.stage_name || "Stage";
	if (textEl) textEl.textContent = data.question_text || "Active Question loaded";

	// Update all hidden quiz_id inputs in score forms
	document.querySelectorAll("input[name='quiz_id']").forEach(input => {
		input.value = data.question_id;
	});

	if (banner) {
		banner.classList.remove("border-secondary");
		banner.classList.add("border-warning");
	}
	if (iconBox) {
		iconBox.className = "bg-warning bg-opacity-10 text-warning-emphasis p-3 rounded-circle";
		iconBox.innerHTML = '<i class="bi bi-question-circle-fill fs-2"></i>';
	}

	if (skipWrapper) skipWrapper.classList.remove("d-none");
	if (scoreContainer) scoreContainer.classList.remove("d-none");
	if (waitingPlaceholder) waitingPlaceholder.classList.add("d-none");

	appendQuestionToQueuePillBar(data, true);
}

function appendQuestionToQueuePillBar(data, isCurrentActive = false) {
	const queueContainer = document.getElementById("recorderQueueNavContainer");
	const queueItemsContainer = document.getElementById("queueItemsPills");
	const countNum = document.getElementById("queueCountNum");

	if (queueContainer) queueContainer.classList.remove("d-none");

	if (queueItemsContainer) {
		let existingPill = document.getElementById(`queue_pill_${data.question_id}`);
		if (!existingPill) {
			const pill = document.createElement("a");
			pill.id = `queue_pill_${data.question_id}`;
			pill.href = `/recorder?stage_id=${data.stage_id}&quiz_id=${data.question_id}`;
			pill.className = isCurrentActive 
				? "btn btn-warning text-dark fw-bold shadow rounded-pill px-3 py-1.5 text-nowrap small queue-pill-item"
				: "btn btn-outline-light text-white opacity-75 rounded-pill px-3 py-1.5 text-nowrap small queue-pill-item";
			pill.innerHTML = isCurrentActive 
				? `<i class="bi bi-play-circle-fill me-1"></i>Q#${data.question_number} (${data.stage_name})`
				: `Q#${data.question_number} (${data.stage_name})`;
			queueItemsContainer.appendChild(pill);
		}
	}

	if (countNum) {
		const currentCount = document.querySelectorAll(".queue-pill-item").length;
		countNum.textContent = currentCount;
	}
}

function showQueueNotification(data) {
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
	toastEl.className = "toast align-items-center text-white bg-warning text-dark border-0 show shadow-lg rounded-4 overflow-hidden mb-2";
	toastEl.setAttribute("role", "alert");
	toastEl.innerHTML = `
		<div class="d-flex p-2 align-items-center">
			<div class="toast-body d-flex align-items-center gap-3 fs-6 py-1">
				<i class="bi bi-layers-fill fs-3 text-dark"></i>
				<div>
					<strong class="d-block text-dark" style="font-size: 0.8rem; letter-spacing: 0.5px; text-transform: uppercase;">Question Added to Queue</strong>
					<span style="font-size: 0.9rem; font-weight: 500;">Question #${data.question_number} (${data.stage_name}) was opened and added to your queue.</span>
				</div>
			</div>
			<button type="button" class="btn-close me-2 m-auto" onclick="this.closest('.toast').remove()"></button>
		</div>
	`;

	container.appendChild(toastEl);

	setTimeout(() => {
		if (toastEl && toastEl.parentNode) {
			toastEl.remove();
		}
	}, 4500);
}

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
