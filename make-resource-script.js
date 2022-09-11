
const fs = require('fs');
const PNG = require('pngjs').PNG;

/*

Tech Note 21: https://www.docjava.com/posterous/file/2012/07/9621873-out3.pdf
QuickDraw's Internal Picture Definition

rect order is top left bottom right

'PICT' (3) 0048 {size} OOOA 0014 OOAF 0078 {picFrame}
1101 {version 1} 01 OOOA 0000 0000 OOFA 0190 {clipRgn - 10 byte region}
31 OOOA 0014 OOAF 0078 {paintRect rectangle}
90 0002 OOOA 0014 OOOF 001C {BitsRect rowbytes bounds (note that bounds is
wider than smallr) }
OOOA 0014 OOOF 0019 {srcRect}
0000 0000 0014 001E {dstRect}
00 06 {mode=notSrcXor}
0000 0000 0000 0000 0000 {5 rows of empty bitmap (we copied from a
still-blank window) }
FF {fin}


  width: 97,
  height: 18,
  depth: 1,
  interlace: false,
  palette: false,
  color: false,
  alpha: false,
  bpp: 1,
  colorType: 0,
*/

function convertToPict(filename) {
  const image = PNG.sync.read(fs.readFileSync(filename));
  const out = Buffer.alloc(262144);
  let off = 0;
  function write16(k) {
    out.writeInt16BE(k, off);
    off += 2;
  }
  
  function write8(k) {
    // if (k < 0)
    //   out.writeInt8(k, off);
    //   else
    out.writeUInt8(k, off);
    off++;
  }

  const rowBytes = 2 * Math.floor((image.width + 15) / 16);
  
  write16(0); // size placeholder
  write16(0); // top
  write16(0); // left
  write16(image.height); // bottom
  write16(image.width); // right
  
  write16(0x1101); // version
  
  // clip rect
  write8(1);
  write16(10); // length of clip region
  write16(0); // top of clip region
  write16(0); // left
  write16(image.height); // bottom
  write16(image.width); // right
  
  write8(0x98); // packed bitmap
  write16(rowBytes); // row bytes
  
  // bounds
  write16(0); // top of bits
  write16(0); // left
  write16(image.height); // bottom
  write16(image.width); // right
  
  // srcRect
  write16(0); // top
  write16(0); // left
  write16(image.height); // bottom
  write16(image.width); // right
  
  // dstRect
  write16(0); // top
  write16(0); // left
  write16(image.height); // bottom
  write16(image.width); // right
  
  write16(0); // mode (srcCopy)
  
  //let unpacked = [], count = 0;
  for (let y = 0; y < image.height; y++) {
    // "packed" scanlines
    write8(rowBytes + 1);
    write8(rowBytes - 1);
    for (let x = 0; x < rowBytes; x++) {
      //let val = y % 2 ? 0x55 : 0xaa;
      let val = 0;
      for (let bit = 0; bit < 8; bit++) {
        if (8 * x + bit >= image.width) {
          continue;
        }
  
        const pix = image.data[4 * (y * image.width + 8 * x + bit)];
        if (pix) {
          val |= 1 << (7 - bit);
        }
      }
      write8(val);
    }
  }
  
  write8(0xff); // end
  out.writeInt16BE(off, 0); // fill in size
  //fs.writeFileSync('out.pict', out.subarray(0, off));
  
  const contents = out.subarray(0, off).toString('hex');
  let res = `data 'PICT' (128) {\n`;
  const lineLength = 32;
  
  let remain = contents.length;
  for (let k = 0; k < contents.length - lineLength; k += lineLength) {
    remain -= lineLength;
    res += `$"${contents.substring(k, k + lineLength)}"\n`;
  }
  
  if (remain > 0) {
    res += `$"${contents.substring(contents.length - remain, contents.length)}"`;
  }
  
  res += `};\n\n`;
  return res;
}

const dir = fs.readdirSync('titles/');
console.log(dir);

fs.writeFileSync('out.r', convertToPict('titles/163.png'));