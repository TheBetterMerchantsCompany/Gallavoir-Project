var pattern = new RegExp("([0-9a-fA-F]{6})","g");
var all = AkelPad.GetTextRange(0,-1);
var hits = all.match(pattern);

for(i = 0; i < hits.length; i++)
  {
  var hit = hits[i];
  AkelPad.Call("Coder::HighLight", 2, "#000000", "#"+hit, 0, 0, -1, hit, -1);
  }