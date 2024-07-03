import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="show"
export default class extends Controller {
	static targets = ["answerSection", "backButton"];

	connect() {
		// console.log("connected", this.element);
		this.answerSectionTarget.classList.add("d-none");
		this.backButtonTarget.classList.add("d-none");
	}

	toggleAnswer() {
		this.answerSectionTarget.classList.toggle("d-none");
		this.backButtonTarget.classList.toggle("d-none");
	}
}
