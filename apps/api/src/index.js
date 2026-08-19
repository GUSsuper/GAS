const http = require("http");

const port = Number(process.env.PORT || 3000);

const server = http.createServer((req, res) => {
  res.setHeader("Content-Type", "application/json; charset=utf-8");

  if (req.url === "/health") {
    res.end(JSON.stringify({
      ok: true,
      app: "GAS AI Super App",
      version: "0.1.0"
    }));
    return;
  }

  res.end(JSON.stringify({
    name: "GAS AI Super App",
    status: "ready"
  }));
});

server.listen(port, () => {
  console.log(`GAS API running on port ${port}`);
});
