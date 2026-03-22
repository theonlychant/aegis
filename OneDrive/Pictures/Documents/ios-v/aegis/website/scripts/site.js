document.addEventListener('DOMContentLoaded', function(){
  // simple staged reveal on load
  document.querySelectorAll('.reveal').forEach(function(el){
    var delay = parseInt(el.getAttribute('data-delay')||0,10);
    setTimeout(function(){ el.classList.add('animated'); }, 80 * delay);
  });

  // reveal on scroll for cards
  var io = new IntersectionObserver(function(entries){
    entries.forEach(function(entry){
      if(entry.isIntersecting){
        entry.target.classList.add('visible');
        io.unobserve(entry.target);
      }
    });
  }, {threshold:0.12});

  document.querySelectorAll('.reveal-on-scroll, .card.reveal').forEach(function(el){
    io.observe(el);
  });

  // subtle hover micro-interactions
  document.querySelectorAll('.btn').forEach(function(b){
    b.addEventListener('pointerenter', function(){ b.style.transform='translateY(-3px)'; });
    b.addEventListener('pointerleave', function(){ b.style.transform=''; });
  });
});
