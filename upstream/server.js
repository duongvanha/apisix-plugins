const http = require('http');

const server = http.createServer((req, res) => {
    let requestBody = '';

    req.on('data', (chunk) => {
        requestBody += chunk;
    });

    req.on('end', () => {
        const responseData = {
            method: req.method,
            url: req.url,
            headers: req.headers,
            body: requestBody
        };

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(responseData));
    });
});

const PORT = process.env.PORT || 80;
server.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
