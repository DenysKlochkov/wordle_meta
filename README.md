# wordle_meta

## Using basics of Information Theory on the quest to find the best [Worlde](https://www.powerlanguage.co.uk/wordle/) starting word.

# General Idea

For each word, the Relative Information Increase(RII) is defined as average uncertainty decrease for every possible "Secret" word that is being guessed, i.e.:

Testing word "apple" on the dataset ["puppy", "apple", "soapy", "poppy", "roses"] 

| Tested Word | Secret | Match | Dataset Count Before | Dataset After
|---   |---	   | ---  	| ---	| ---	|
Apple  | Apple | 🟩🟩🟩🟩🟩 | 5 | 1 
Apple  | Poppy | 🟥🟨🟩🟥🟥 | 5 | 2 ("Puppy", "Poppy")
Apple  | Puppy | 🟥🟨🟩🟥🟥 | 5 | 2 ("Puppy", "Poppy")
Apple  | Soapy | 🟨🟨🟥🟥🟥 | 5 | 1
Apple  | Roses | 🟥🟥🟥🟥🟨 | 5 | 1

The average entropy decrease is thus 

`1/5 * (log2(5/1) + log2(5/2) + log2(5/2) + log2(5/1) + log2(5/1))   ~= 1.92 bits* `

*Borrowing a classical definition from Information Theory, bit\* is defined as a unit of information that reduces the uncertainty of the receiver in half. 

## Results so far:

| Word | RII bits  |
|---   |---	|
serai | 5.4332623583616195
soare | 5.429748732844698
seral | 5.397852208791463
teras | 5.39117472300415
tears | 5.381462857481533
tares | 5.380826317399524
raise | 5.37862690306589
strae | 5.37711873670142
aeros | 5.373759863342616
salet | 5.362468369650325

[Full Results](https://github.com/DenysKlochkov/wordle_meta/blob/main/results/entropies-sorted.txt)

## Dataset Used

[word-list-json](https://www.npmjs.com/package/word-list-json) - Filtered 12595 5-letter Words

## More To Come:
 - Webpage Interface
 - Visualization
 - More efficient sub-sampling algorithms 
 - Word Combinations
