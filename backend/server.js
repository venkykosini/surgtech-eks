const express = require("express");

const app = express();
const port = process.env.PORT || 3000;

app.get("/health", (request, response) => {
  response.json({
    status: "Healthy",
    service: "backend",
    message: "Backend is running on Amazon EKS"
  });
});

app.get("/", (request, response) => {
  response.json({
    message: "Hello from the SurgTech EKS backend"
  });
});

app.listen(port, () => {
  console.log(`Backend listening on port ${port}`);
});
