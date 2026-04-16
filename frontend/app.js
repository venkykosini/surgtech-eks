const apiStatus = document.getElementById("api-status");
const canvas = document.getElementById("orbits");
const context = canvas.getContext("2d");

async function loadStatus() {
  try {
    const response = await fetch("/api/health");
    const data = await response.json();
    apiStatus.textContent = data.status;
  } catch (error) {
    apiStatus.textContent = "Unavailable";
  }
}

function drawOrbitScene(time) {
  const width = canvas.width;
  const height = canvas.height;
  context.clearRect(0, 0, width, height);

  const gradient = context.createLinearGradient(0, 0, width, height);
  gradient.addColorStop(0, "#11263e");
  gradient.addColorStop(1, "#091521");
  context.fillStyle = gradient;
  context.fillRect(0, 0, width, height);

  const centerX = width / 2;
  const centerY = height / 2;

  for (let i = 0; i < 3; i += 1) {
    context.beginPath();
    context.strokeStyle = "rgba(122, 231, 199, 0.22)";
    context.lineWidth = 1.5;
    context.ellipse(centerX, centerY, 70 + i * 50, 30 + i * 24, 0, 0, Math.PI * 2);
    context.stroke();
  }

  const planets = [
    { radius: 70, size: 8, color: "#7ae7c7", speed: 0.0011 },
    { radius: 120, size: 10, color: "#ffcf70", speed: 0.0008 },
    { radius: 170, size: 7, color: "#8bc4ff", speed: 0.0006 }
  ];

  planets.forEach((planet, index) => {
    const angle = time * planet.speed + index;
    const x = centerX + Math.cos(angle) * planet.radius;
    const y = centerY + Math.sin(angle) * (28 + index * 24);
    context.beginPath();
    context.fillStyle = planet.color;
    context.arc(x, y, planet.size, 0, Math.PI * 2);
    context.fill();
  });

  context.beginPath();
  context.fillStyle = "#f4fbff";
  context.arc(centerX, centerY, 18, 0, Math.PI * 2);
  context.fill();

  requestAnimationFrame(drawOrbitScene);
}

loadStatus();
requestAnimationFrame(drawOrbitScene);
