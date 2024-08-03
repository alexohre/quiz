import consumer from "./consumer";

consumer.subscriptions.create("TimerChannel", {
	connected() {
		// Called when the subscription is ready for use on the server
		console.log("Connected to TimerChannel");
	},

	disconnected() {
		// Called when the subscription has been terminated by the server
		console.log("disonnected to TimerChannel");
	},

	received(data) {
		// Called when there's incoming data on the websocket for this channel
	},
});
