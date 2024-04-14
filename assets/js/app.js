// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix";
import {LiveSocket} from "phoenix_live_view";
import topbar from "../vendor/topbar";

window.Alpine.start();

let Hooks = {};

// Ungrouped cards are draggable
// Stack bottoms and ungrouped cards are drag targets
Hooks.GroupableCard = {
  mounted() {
    if (this.el.getAttribute("draggable") === "true") {
      this.el.addEventListener("dragstart", (event) => {
        // Need to get id here rather than on mount.
        // Sometimes the id goes missing when we do it on mount.
        const id = event.target.getAttribute("data-card-id");
        event.dataTransfer.setData("text/plain", id);
        event.dataTransfer.dropEffect = "move";
      });
    }
    if (this.el.hasAttribute("data-dragtarget")) {
      this.el.addEventListener("dragover", (event) => {
        event.preventDefault();
      });
      this.el.addEventListener("drop", (event) => {
        event.preventDefault();
        const id = event.dataTransfer.getData("text/plain");
        const onto = this.el.getAttribute("data-card-id");
        if (onto !== id) {
          document.getElementById(`groupable-card-${id}`).classList.add("invisible");
          this.pushEvent("group_cards", {"card-id": id, "onto": onto});
        }
      });
    }
  }
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  dom: {
    onBeforeElUpdated(from, to) {
      if (from._x_dataStack) {
        window.Alpine.clone(from, to);
      }
    }
  },
  hooks: Hooks,
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken}
});

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"});
window.addEventListener("phx:page-loading-start", _info => topbar.show(300));
window.addEventListener("phx:page-loading-stop", _info => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

