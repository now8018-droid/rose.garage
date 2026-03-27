const cars = Array.from({ length: 12 }, (_, i) => ({
  id: i + 1,
  class: 'SuperSport',
  name: 'AUDI RS6 ABT',
  image: 'https://i.imgur.com/Fg7dQLe.png',
  selected: i === 0,
}));

const grid = document.getElementById('carGrid');

grid.innerHTML = cars
  .map(
    (car) => `
      <article class="car-card">
        <span class="label">${car.class}</span>
        <span class="name">${car.name}</span>
        <span class="star">☆</span>
        <img src="${car.image}" alt="${car.name}" />
        <button class="select-btn ${car.selected ? 'active' : ''}">↘ select car</button>
      </article>
    `,
  )
  .join('');
