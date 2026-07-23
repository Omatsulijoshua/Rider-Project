const header = document.querySelector("[data-header]");
const demoButton = document.querySelector("[data-demo-button]");
const trackForm = document.querySelector("[data-track-form]");
const trackingResult = document.querySelector("[data-tracking-result]");

function syncHeader() {
  header?.classList.toggle("is-scrolled", window.scrollY > 24);
}

function escapeHtml(value) {
  const entities = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" };
  return value.replace(/[&<>"]/g, (char) => entities[char]);
}

function renderTrackingResult(trackingId) {
  const cleanId = escapeHtml(trackingId.trim() || "RID-2026-LAG-4821");
  const eta = 7 + Math.floor(Math.random() * 18);
  const stages = ["Driver assigned", "Pickup in progress", "Package in transit"];
  const currentStage = stages[Math.floor(Math.random() * stages.length)];

  trackingResult.innerHTML = `
    <div class="shipment-card__top">
      <span class="status-dot"></span>
      <div>
        <strong>${cleanId.toUpperCase()}</strong>
        <p>${currentStage} / ETA ${eta} min</p>
      </div>
    </div>
    <div class="shipment-progress" aria-label="Shipment progress">
      <span class="is-done">Booked</span>
      <span class="is-done">Pickup</span>
      <span class="is-active">In transit</span>
      <span>Delivered</span>
    </div>
    <ul class="shipment-events">
      <li><strong>Now</strong><span>Live location and ETA refreshed for this shipment.</span></li>
      <li><strong>08:42</strong><span>Assigned driver confirmed package route.</span></li>
      <li><strong>08:35</strong><span>Tracking number created after booking.</span></li>
    </ul>
  `;
}

window.addEventListener("scroll", syncHeader, { passive: true });
syncHeader();

demoButton?.addEventListener("click", () => {
  const eta = 4 + Math.floor(Math.random() * 9);
  demoButton.closest(".tracking-status")?.querySelector("small")?.replaceChildren(`ON_DELIVERY / ETA ${eta} min`);
});

trackForm?.addEventListener("submit", (event) => {
  event.preventDefault();
  const formData = new FormData(trackForm);
  renderTrackingResult(String(formData.get("tracking") || ""));
});
