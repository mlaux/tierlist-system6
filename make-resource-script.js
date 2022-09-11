const fs = require('fs');
const { write } = require('pngjs/lib/png-sync');
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

function formatResourceData(arr) {
  let res = '';
  const hex = arr.toString('hex');
  const lineLength = 32;
  let remain = hex.length;
  for (let k = 0; k < hex.length - lineLength; k += lineLength) {
    remain -= lineLength;
    res += `$"${hex.substring(k, k + lineLength)}"\n`;
  }
  
  if (remain > 0) {
    res += `$"${hex.substring(hex.length - remain, hex.length)}"`;
  }
  return res;
}

function convertToPict(filename) {
  const image = PNG.sync.read(fs.readFileSync(filename));
  const out = Buffer.alloc(262144);
  let off = 0;
  function write16(k) {
    out.writeInt16BE(k, off);
    off += 2;
  }
  
  function write8(k) {
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
  
  write8(rowBytes >= 8 ? 0x98 : 0x90); // packed if 8 or more rowBytes
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
    if (rowBytes >= 8) {
      // "packed" scanlines with no packing
      write8(rowBytes + 1);
      write8(rowBytes - 1);
    }
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
  
  const contents = out.subarray(0, off);
  const id = filename.substring(filename.indexOf('/') + 1, filename.indexOf('.'));
  let res = `data 'PICT' (${id}) {\n`;
  
  res += formatResourceData(contents);

  res += `};\n\n`;
  return res;
}

function makeSongList(db) {
  /*
    data 'TMPL' (128, "slst") {
      $"084E 756D 536F 6E67 734F 434E 5405 2A2A"            /* .NumSongsOCNT.** 
      $"2A2A 2A4C 5354 4307 5665 7273 696F 6E44"            /* ***LSTC.VersionD 
      $"4259 5405 5469 746C 6550 5354 5206 4172"            /* BYT.TitlePSTR.Ar 
      $"7469 7374 5053 5452 0547 656E 7265 5053"            /* tistPSTR.GenrePS 
      $"5452 0954 6974 6C65 5069 6374 4457 5244"            /* TR.TitlePictDWRD 
      $"0A41 7274 6973 7450 6963 7444 5752 4409"            /* .ArtistPictDWRD. 
      $"4765 6E72 6550 6963 7444 5752 4404 5469"            /* GenrePictDWRD.Ti 
      $"6572 5053 5452 0749 6E64 4469 6666 424F"            /* erPSTR.IndDiffBO 
      $"4F4C 0342 504D 5053 5452 094E 6F74 6543"            /* OL.BPMPSTR.NoteC 
      $"6F75 6E74 4457 5244 0952 6164 6172 5479"            /* ountDWRD.RadarTy 
      $"7065 5053 5452 052A 2A2A 2A2A 4C53 5445"            /* pePSTR.*****LSTE 
    };

    data 'slst' (128) {
      $"0001 1422 5468 6520 7472 6176 656C 6572"            /* ..."The traveler 
      $"7320 6F66 2076 6972 7475 616C 2073 7061"            /* s of virtual spa 
      $"6365 2028 4C29 0B44 4A20 4D55 5241 5341"            /* ce (L).DJ MURASA 
      $"4D45 0654 4543 484E 4F00 A300 0000 0001"            /* ME.TECHNO.�..... 
      $"4100 0003 3135 3107 9705 4348 4F52 44"              /* A...151.�.CHORD 
    };
  */
  const out = Buffer.alloc(262144);
  let off = 0;
  function write16(k) {
    out.writeInt16BE(k, off);
    off += 2;
  }
  
  function write8(k) {
    out.writeUInt8(k, off);
    off++;
  }

  function writePstr(str) {
    write8(str.length);
    out.write(str, off);
    off += str.length;
  }

  write16(db.length);
  for (let k = 0; k < 16 && k < db.length; k++) {
    const song = db[k];
    if (song.version > 28) {
      continue;
    }

    write8(song.version);
    if (song.title_pict) {
      writePstr(song.title_ascii);
    } else {
      writePstr(song.title);
    }
    if (song.artist_pict) {
      writePstr('');
    } else {
      writePstr(song.artist);
    }
    if (song.genre_pict) {
      writePstr('');
    } else {
      writePstr(song.genre);
    }
    write16(song.title_pict ? song.title_pict : 0);
    write16(song.artist_pict ? song.artist_pict : 0);
    write16(song.genre_pict ? song.genre_pict : 0);
    writePstr(song.tier);
    write16(song.ind_diff ? 1 : 0);
    writePstr(song.bpm);
    write16(song.notes);
    writePstr(song.radar);
  }
  return `data 'slst' (128) {\n${formatResourceData(out.subarray(0, off))}\n};`;
}

const dir = fs.readdirSync('titles/');
let result = '';
for (let k = 0; k < dir.length; k++) {
  result += convertToPict(`titles/${dir[k]}`);
}

result += makeSongList(JSON.parse(fs.readFileSync('out.json')));

fs.writeFileSync('out.r', result);