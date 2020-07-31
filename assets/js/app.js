// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import scss from "../css/app.scss";

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html";
import {Socket} from "phoenix";
import NProgress from "nprogress";
import {LiveSocket} from "phoenix_live_view";
import DiffViewerComponent from "./diff_viewer_component";
import DiffSelectorComponent from "./diff_selector_component";

let Hooks = {
  DiffViewerComponent: DiffViewerComponent,
  DiffSelectorComponent: DiffSelectorComponent
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks, params: {_csrf_token: csrfToken}});

// Show progress bar on live navigation and form submit
window.addEventListener("phx:page-loading-start", info => NProgress.start());
window.addEventListener("phx:page-loading-stop", info => NProgress.done());

// Show loading spinner when loading diff
window.addEventListener("phx-diff:diff-loading-start", info => {
  let element = document.getElementById("landing-page");
  if(element) {
    element.classList.remove("phx-diff-loaded-diff");
  }
});
window.addEventListener("phx-diff:diff-loading-stop", info => {
  let element = document.getElementById("landing-page");
  if(element) {
    element.classList.add("phx-diff-loaded-diff");
  }
});

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket;
