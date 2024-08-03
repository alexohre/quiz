import consumer from "./consumer";

consumer.subscriptions.create("QuizTimerChannel", {
	connected() {
		// Called when the subscription is ready for use on the server
		console.log("Connected to QuizTimerChannel");
	},

	disconnected() {
		// Called when the subscription has been terminated by the server
		console.log("disconnected to QuizTimerChannel");
	},

	received(data) {
		// Called when there's incoming data on the websocket for this channel
		const quizElement = document.getElementById("quiz_timer_content");
		if (quizElement) {
			quizElement.innerHTML = data.html;
		}
	},
});
