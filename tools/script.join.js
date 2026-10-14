(function () {
  // The invitation code lives only in the URL fragment, which browsers never
  // send to a server. It is used here solely to hand the link to the app (and
  // to copy the link on request). Nothing is stored, logged or sent anywhere.
  var token = location.hash.replace(/^#/, "");
  var ok = /^[A-Za-z0-9]{16,128}$/.test(token);
  var open = document.getElementById("open");
  if (ok) {
    open.href = "circa://join#" + encodeURIComponent(token);
  } else {
    document.getElementById("broken").hidden = false;
    open.setAttribute("aria-disabled", "true");
    open.style.opacity = "0.5";
    open.removeAttribute("href");
    document.getElementById("copy").hidden = true;
  }
  var status = document.getElementById("status");
  document.getElementById("copy").addEventListener("click", function () {
    var link = location.href;
    function done(msg) { status.textContent = msg; }
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(link).then(function () { done("Link copied. Paste it into Notes or a message to yourself to keep it."); },
        function () { done("Couldn’t copy automatically — press and hold the address bar to copy the link."); });
    } else {
      done("Press and hold the address bar to copy the link.");
    }
  });
})();
