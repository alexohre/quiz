import consumer from "./consumer";

consumer.subscriptions.create("QuizChannel", {
	connected() {
		// Called when the subscription is ready for use on the server
		console.log("Connected to QuizChannel");
	},

	disconnected() {
		console.log("diconnected to QuizChannel");
		// Called when the subscription has been terminated by the server
	},

	received(data) {
		// Called when there's incoming data on the websocket for this channel
		const quizElement = document.getElementById("quiz_content");
		if (quizElement) {
			quizElement.innerHTML = data.html;
		}
	},
});
