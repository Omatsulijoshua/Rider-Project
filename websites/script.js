const header = document.querySelector("[data-header]");
const demoButton = document.querySelector("[data-demo-button]");

function syncHeader() {
  header?.classList.toggle("is-scrolled", window.scrollY > 24);
}

window.addEventListener("scroll", syncHeader, { passive: true });
syncHeader();

demoButton?.addEventListener("click", () => {
  const eta = 4 + Math.floor(Math.random() * 9);
  demoButton.closest(".tracking-status")?.querySelector("small")?.replaceChildren(`ON_DELIVERY / ETA ${eta} min`);
});
