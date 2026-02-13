// Simple test of stdin reading
console.error('Script started');
console.error('stdin.isTTY:', process.stdin.isTTY);
console.error('stdin.readable:', process.stdin.readable);
console.error('stdin.readableEnded:', process.stdin.readableEnded);

const chunks = [];

process.stdin.on('data', (chunk) => {
  console.error('Got data:', chunk.length, 'bytes');
  chunks.push(chunk);
});

process.stdin.on('end', () => {
  console.error('Got end event');
  const result = Buffer.concat(chunks).toString('utf-8');
  console.log('Result:', result);
});

process.stdin.on('error', (err) => {
  console.error('Got error:', err);
});

console.error('Calling resume()');
process.stdin.resume();
console.error('Waiting for data...');
