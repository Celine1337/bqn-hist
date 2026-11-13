# bqn-hist — word frequency histogram.
# Usage: bqn-hist <file> [topN]     (topN defaults to 10)
# Words are whitespace-separated tokens, lowercased, with basic punctuation
# removed. Prints "count word" lines sorted by count desc, then word asc.
# Notes for this BQN build: < is enclose (not ⊂); bindings are single-assignment.

argv ← •args
"usage: bqn-hist <file> [topN]"!(1≤≠argv)
args ← argv∾<"10"
path ← ⊑args

# Parse a non-negative integer from a string (no float parsing needed).
ParseN ← {
  "topN must be a non-negative integer"!(0<≠𝕩)∧∧´𝕩∊"0123456789"
  +´(𝕩-'0')×⌽10*↕≠𝕩
}
n ← ParseN 1⊑args

# Split one string into whitespace-separated words.
Split ← {
  m ← ¬𝕩∊" "∾9+@
  idx ← +`m∧¬»m
  1↓(m/idx)⊔(m/𝕩)
}
Lower ← {𝕩+32×(𝕩≥'A')∧𝕩≤'Z'}
punct ← ".,;:!?()[]{}"∾'"'∾"'"
Strip ← {(¬𝕩∊punct)/𝕩}

lines ← •FLines path
# Join lines into one space-separated text (flat string joins only; the
# trailing <"" keeps ∾´ happy when the file is empty).
text ← ∾´{" "∾𝕩}¨lines∾<""
toks ← Split text
low ← Strip¨Lower¨toks
words ← (0<≠¨low)/low

# Classify + group gives unique words (first-seen order) and their counts.
u ← ⊐words
g ← u⊔words
uniq ← ⊑¨g
counts ← ≠¨g

# Sort by word asc, then stable-sort by count desc: ties break on word asc.
oa ← ⍋uniq
ua ← oa⊏uniq
ca ← oa⊏counts
od ← ⍒ca
ud ← od⊏ua
cd ← od⊏ca

k ← n⌊≠ud
{•Out (•Fmt 𝕩⊑cd)∾" "∾(𝕩⊑ud)}¨↕k
•Exit 0