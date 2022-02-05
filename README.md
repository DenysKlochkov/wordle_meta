# wordle_meta

## Project aimed at using basics of Information Theory on the quest to find the best [Worlde](https://www.powerlanguage.co.uk/wordle/) starting word, best words combinations, perfect strategy, etc. 

Additional goal is to come up with heuristics and other optimizations to decrease computational complexity of calculating the information metrics for each word out of the set.

# General Idea

For each word, the Relative Information Increase(RII) is defined as average uncertainty decrease for every possible "Secret" word that is being guessed, i.e.:

Testing word "apple" on the dataset ["puppy", "apple", "soapy", "poppy", "roses"] 

| Tested Word | Secret | Match Object | Dataset Count Before Filtering | Dataset After Filtering
|---   |---	   | ---  	| ---	| ---	|
Apple  | Apple | 🟩🟩🟩🟩🟩 | 5 | 1 
Apple  | Poppy | 🟥🟨🟩🟥🟥 | 5 | 2 ("Puppy", "Poppy")
Apple  | Puppy | 🟥🟨🟩🟥🟥 | 5 | 2 ("Puppy", "Poppy")
Apple  | Soapy | 🟨🟨🟥🟥🟥 | 5 | 1
Apple  | Roses | 🟥🟥🟥🟥🟨 | 5 | 1

The average entropy decrease is thus 

`1/5 * (log2(5/1) + log2(5/2) + log2(5/2) + log2(5/1) + log2(5/1))   ~= 1.92 bits* `

*Borrowing a classical definition from Information Theory, bit\* is defined as a unit of information that reduces the uncertainty of the receiver in half. 

# Algorithm complexity

For each word out of the set, we iterate through all the secret words to determine a Match Object O(n^2). Given the Match Object, we count words in the list that conform to it O(n). The final theoretical complexity comes to be O(n^3), given the constant cost of word matching & deciding whether a word conforms to the Match Object.

# Improvements

 - Dynamic Programming-like lookup table that stores the counts of filtered words by each unique state of the "Matcher". As seen in the example above, sometimes different secrets can result in the same Match Object, which makes re-filtering the list redundant.
 
 - Parallelization in separate processes that independently calculate RII for chunks of words.

Using those improvement the effective exponent of around n^2.7 was achieved for datasets up to ~12 000 words.

## Heuristic algorithms

Another approach would be to under-sample the secrets that we test against instead of testing every possible word, - by utilizing certain heuristic algorithm. The following twoo hypotheses will be investigated:
  
  - By doing a cursory evaluation of the set using a very few (~1%) secrets first, and then using a larger set of different secrets chosen on the basis of this initial evaluation ( either only the "best" words, the "worst" ones, or a strict combination of those ), it is possible to achieve statistically better* results compared to random sampling of the equivalent quantity of secrets.

  - By starting with the small subset of secrets and updating the secret list "on the go" (which might involve re-evaluating the same word multiple times with different sets of secrets), based on the metrics of current evaluation, it is possible to achieve statistically better* results compared to random sampling of the equivalent quantity of secrets.

The quality of the under-sampling is determined by normalizing the set of results using the corresponding full-sampling values for each word, and then calculating the statistical metrics of the resulting set ( want mean and average as close to 1 as possible, and variation as small as possible). Due to randomness, this trial needs to be performed multiple times, preferably with different under-sampling percentages. 
For example:

    -- The full-sampled set results: [["abc", 2.5], ["cde", 3], ["efg", 2.75]]

    -- Under-sampling strategy A results: [["abc", 1], ["cde", 1.2], ["efg", 10]], 
                  
    after normalization: [["abc", 0.4], ["cde", 0.33], ["efg", 3.6]] (mean: 1.44, median: 0.4, variance: 2.32)

    -- Under-sampling strategy B results: [["abc", 2], ["cde", 2.7], ["efg", 3]], 
                  
    after normalization: [["abc", 0.8], ["cde", 0.9], ["efg", 1.1]] (mean: 0.93, median: 0.9, variance: 0.015)


In this trial, the Under-sampling strategy B was proven to be superior to A, since its values after normalization better represent the full-sampled results.

## Results so far (full sampling):

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


[word-list-json](https://www.npmjs.com/package/word-list-json) - Filtered 12595 only 5-letter Words 

[Final Input](https://github.com/DenysKlochkov/wordle_meta/blob/main/results/input.txt)

## More To Come:
 - Webpage Interface
 - Visualization
 - More efficient sub-sampling algorithms 
 - Word Combinations
