const fs = require('fs');
let out = `data 'PICT' (128) {\n`;
const contents = fs.readFileSync('titles/163.pict').toString('hex');
const lineLength = 32;

console.log(contents.length);

let remain = contents.length;
for (let k = 0; k < contents.length - lineLength; k += lineLength) {
  remain -= lineLength;
  out += `$"${contents.substring(k, k + lineLength)}"\n`;
}

if (remain > 0) {
  out += `$"${contents.substring(contents.length - remain, contents.length)}"`;
}

out += `};`;
fs.writeFileSync('out.r', out);