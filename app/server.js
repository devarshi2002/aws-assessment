const http = require("http");
const os = require("os");

const port = Number(process.env.PORT || 8080);
const html = `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>AWS DevOps Assessment</title>
<style>body{font:16px system-ui;max-width:760px;margin:8vh auto;padding:24px;color:#172033}main{border:1px solid #d7deea;border-radius:16px;padding:28px}code{background:#f2f5fa;padding:3px 6px;border-radius:5px}</style></head>
<body><main><h1>AWS Terraform DevOps Assessment</h1>
<p>Application served from a private EC2 instance behind an Application Load Balancer.</p>
<p>Instance: <code>${os.hostname()}</code></p><p>Health endpoint: <code>/health</code></p>
<p>Infrastructure: Terraform · Auto Scaling · ALB · private subnets</p></main></body></html>`;

http.createServer((req, res) => {
  if (req.url === "/health") {
    res.writeHead(200, { "content-type": "application/json" });
    return res.end(JSON.stringify({ status: "healthy", host: os.hostname() }));
  }
  res.writeHead(200, { "content-type": "text/html; charset=utf-8" });
  res.end(html);
}).listen(port, "0.0.0.0", () => console.log(`Listening on ${port}`));
