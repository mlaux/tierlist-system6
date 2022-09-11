var h4s = document.getElementsByTagName('h4');
var tables = document.getElementsByTagName('table');
var columns = ['version', 'title', 'bpm', 'notes', '', 'radar', ];
var songs = [];

for (var k = 0; k < h4s.length; k++) {
  var ind_diff = false;
  var tier = h4s[k].innerText;
  if (tier.indexOf('個人差') !== -1) {
    tier = tier.substring(3, 5).trim();
    ind_diff = true;
  } else {
    tier = tier.substring(2, 4).trim();
  }
  if (tier === '(') {
    tier = 'undecided';
  }

  var table = tables[k].getElementsByTagName('tr');
  for (var rn = 1; rn < table.length; rn++) {
    var row = table[rn].getElementsByTagName('td');
    var song = { tier, ind_diff, level: 12, };
    for (var col = 0; col < 6; col++) {
      if (col != 4) {
        var value;
        if (col == 0 || col == 3) {
          value = parseInt(row[col].innerText);
        } else {
          value = row[col].innerText;
        }
        song[columns[col]] = value;
      }
    }

    songs.push(song);
  }
}
console.log(JSON.stringify(songs));

