const fs = require('fs');
const spawnSync = require('child_process').spawnSync;
const levenshtein = require('js-levenshtein');

const bistro_db = JSON.parse(fs.readFileSync('omnibistro1.json'));
const atwiki_db = JSON.parse(fs.readFileSync('sp12.json'));

function runConvert(text, filename) {
  spawnSync('convert', [
    '-colorspace',
    'gray',
    '-background',
    'black',
    '-fill',
    'white',
    '-font',
    'Hiragino-Sans-W3',
    '-pointsize',
    '16',
    '+antialias',
    'label:' + text,
    filename,
  ]);
}

function isAscii(title) {
  for (let k = 0; k < title.length; k++) {
    if (title.charCodeAt(k) > 0x7f) {
      return false;
    }
  }
  return true;
}

function findMusicDbSong(title) {
  if (title.endsWith('(L)')) {
    title = title.substring(0, title.length - 3);
  }
  let result = bistro_db['data'].filter(song => song.title === title);
  if (result.length) {
    return result[0];
  }

  result = bistro_db['data'].filter(song => levenshtein(song.title, title) < 4);
  if (result.length) {
    console.warn(`using approximate match ${result[0].title} for ${title}`);
    return result[0];
  }

  return null;
}

let notFound = 0;
let titleId = 256;
let artistId = 512;
let genreId = 768;

for (let k = 0; k < atwiki_db.length; k++) {
  const atwiki_song = atwiki_db[k];
  if (atwiki_song.version > 28) {
    continue;
  }

  const lookup = findMusicDbSong(atwiki_song.title);
  if (!lookup) {
    console.log('not found: ' + atwiki_song.title);
    notFound++;
    continue;
  }

  atwiki_song.artist = lookup.artist;
  atwiki_song.genre = lookup.genre;
  atwiki_song.title_ascii = lookup.title_ascii;

  if (!isAscii(atwiki_song.title)) {
    console.log('generating title image for ' + atwiki_song.title);
    runConvert(atwiki_song.title, `titles/${titleId}.png`);
    atwiki_song.title_pict = titleId++;
  }

  if (!isAscii(atwiki_song.artist)) {
    console.log('generating artist image for ' + atwiki_song.artist);
    runConvert(atwiki_song.artist, `artists/${artistId}.png`);
    atwiki_song.artist_pict = artistId++;
  }

  if (!isAscii(atwiki_song.genre)) {
    console.log('generating genre image for ' + atwiki_song.genre);
    runConvert(atwiki_song.genre, `genres/${genreId}.png`);
    atwiki_song.genre_pict = genreId++;
  }
}

fs.writeFileSync('out.json', JSON.stringify(atwiki_db));
console.log(`processed ${atwiki_db.length - notFound} / ${atwiki_db.length}`);