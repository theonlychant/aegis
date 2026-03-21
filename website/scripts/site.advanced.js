"use strict";
(() => {
  // scripts/site.advanced.ts
  var prefersReduced = typeof window !== "undefined" && matchMedia("(prefers-reduced-motion: reduce)").matches;
  function staggerReveal(elements, delay = 80, duration = 420) {
    if (prefersReduced)
      return;
    elements.forEach((el, i) => {
      const d = i + 1;
      el.animate([
        { opacity: 0, transform: "translateY(10px)" },
        { opacity: 1, transform: "translateY(0)" }
      ], { duration, easing: "cubic-bezier(.2,.9,.2,1)", delay: d * delay, fill: "forwards" });
    });
  }
  function parallaxHero() {
    const hero = document.querySelector(".hero-preview");
    const preview = document.querySelector(".hero-preview .card");
    if (!hero || !preview || prefersReduced)
      return;
    hero.addEventListener("pointermove", (ev) => {
      const r = hero.getBoundingClientRect();
      const cx = (ev.clientX - r.left) / r.width - 0.5;
      const cy = (ev.clientY - r.top) / r.height - 0.5;
      preview.style.transform = `translate3d(${cx * 10}px, ${cy * 8}px, 0) rotate(${cx * 1}deg)`;
    });
    hero.addEventListener("pointerleave", () => {
      preview.style.transform = "";
    });
  }
  function initAdvanced() {
    const reveals = Array.from(document.querySelectorAll(".reveal"));
    staggerReveal(reveals, 70, 420);
    const io = new IntersectionObserver((entries) => {
      entries.forEach((e) => {
        if (e.isIntersecting) {
          e.target.animate([{ opacity: 0, transform: "translateY(10px)" }, { opacity: 1, transform: "translateY(0)" }], { duration: 420, easing: "cubic-bezier(.2,.9,.2,1)", fill: "forwards" });
          io.unobserve(e.target);
        }
      });
    }, { threshold: 0.12 });
    document.querySelectorAll(".card, .hero .reveal").forEach((el) => io.observe(el));
    parallaxHero();
  }
  document.addEventListener("DOMContentLoaded", () => {
    try {
      initAdvanced();
    } catch (e) {
    }
  });
})();
//# sourceMappingURL=site.advanced.js.map
