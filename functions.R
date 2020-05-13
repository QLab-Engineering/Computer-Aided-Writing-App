library(quanteda)
library(readtext)
library(stringi)
library(stringr)
library(doBy)
set.seed(3245)
quanteda_options("threads" = 10)

###Load Training Corpus Set
conBlog <- file("sample/en_US.blogs.training.txt", "r")
blog <- readLines(conBlog, encoding = "UTF-8")
close(conBlog)

conNews <- file("sample/en_US.news.training.txt", "r")
news <- readLines(conNews, encoding = "UTF-8")
close(conNews)

conTwit <- file("sample/en_US.twitter.training.txt", "r")
twit <- readLines(conTwit, encoding = "UTF-8")
close(conTwit)

###Create list of profanity words
prof <- read.csv("facebook-bad-words-list_comma-separated-text-file_2018_07_29.txt", header = FALSE, skip = 14)
prof <- as.vector(t(prof))
prof <- sub("^ ", "", prof)

###Merge Corpus and split in sentences
rawCorpus <- corpus(c(blog, news, twit))
corp_sent <- corpus_reshape(rawCorpus, to = 'sentences')

###Remove unused objects
rm(conBlog, blog, conNews, news, conTwit, twit, rawCorpus)

###Clean Data and create Unigram with and without Stopwords
list_rm_redex <- c("\\.", "#", ";", ":", "@", "([[:alpha:]])\\1{2,}")
list_rm_fixed <- c("b", "c", "d", "e", "f", "g", "h", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z")
monogram <- corp_sent %>% tolower %>% tokens(remove_url = TRUE, remove_punct = TRUE, remove_symbols = TRUE, split_hyphens = TRUE) %>%
  tokens_remove(pattern = prof, valuetype = "fixed") %>%
  tokens_remove("fuck", valuetype = "regex") %>%
  tokens_remove("\\d", valuetype = "regex") %>%
  tokens_remove(list_rm_redex, valuetype = "regex") %>%
  tokens_remove(list_rm_fixed, valuetype = "fixed")
rm(corp_sent)
monogramSW <- tokens_remove(monogram, stopwords("en"), valuetype = "fixed")

###Create FFreq Vectors
ffreqMono <- monogram %>% dfm %>% featfreq
ffreqBi <- monogram %>% tokens_ngrams(n = 2, concatenator = " ") %>% dfm %>% featfreq
ffreqTri <- monogram %>% tokens_ngrams(n = 3, concatenator = " ") %>% dfm %>% featfreq
ffreqQuad <- monogram %>% tokens_ngrams(n = 4, concatenator = " ") %>% dfm %>% featfreq
rm(monogram)
ffreqBiSW <- monogramSW %>% tokens_ngrams(n = 2, concatenator = " ") %>% dfm %>% featfreq
ffreqTriSW <- monogramSW %>% tokens_ngrams(n = 3, concatenator = " ") %>% dfm %>% featfreq
rm(monogramSW)

###Functions

###This function takes a long string of words and return up to the last 3 words as a character vector
returnLastStrings <- function(rawstring) {
  wordCount <- 2
  rawstring <- as.vector(rawstring[[1]])
  
  if (length(rawstring) <= wordCount){wordCount <- length(rawstring)}
  StringOutput <- rawstring[(length(rawstring)-wordCount):length(rawstring)]
  
  return(StringOutput)
}

###This function reads and edit a string input.
readInput <- function(rawInput) {
  
  ponct <- c(".", "?", "!", ",", ";", ":")
  rawInput <- tolower(rawInput)
  rawInput <- sub("-", " ", rawInput)
  rawInput <- sub("_", " ", rawInput)
  lastChr <- str_match(rawInput, ".$")
  if (is.na(lastChr)) {return(list(id = 1))}
  if (lastChr == " ") {
    rawInput <- trimws(rawInput)
    lastChr <- str_match(rawInput, ".$")
    
    if (lastChr %in% ponct) {return(list(id = 0))}
    else {
      rawInput <- sub(".*(\\.|\\?|\\!|\\,|\\:|\\;) ", "", trimws(rawInput))
      cleanedInput <- rawInput %>%
        str_replace_all("[^[:alpha:][:blank:]]", "") %>%
        str_replace_all("\\s+", " ") %>% 
        tokens(remove_url = TRUE)
      cleanedInput_SW <- tokens_remove(cleanedInput, stopwords("en"), valuetype = "fixed")
      
      return(list(id = 2, returnLastStrings(cleanedInput), returnLastStrings(cleanedInput_SW)))
    }
  }
  else {
    
    return(list(id = 1))
  } 
}

###This function check if a word is part of the corpus. If not, it replaces it by <UNK>.
dict <- function(xx) {
  for (i in 1:length(xx)) {
    if (!is.element(xx[i], names(ffreqMono))) {xx[i] <- "<UNK>"}
  }
  return(xx)
}

###This function check if the first object of a character vector is <UNK>. If it is, it removes it.
unk_rm <- function(input) {
  
  for (i in seq_len(length(input))) {
    if (input[1] == "<UNK>") {
      input <- input[-1]
    }
  }
  return(input)
}

###This function returns all the words following a given string and their probability.
prob_calc <- function(xx, SW = FALSE) {
  
  # Set function parameters (database and attenuation factors) based on if the the string has stopwords or not
  if (SW) {
    dblist <- c("ffreqBiSW", "ffreqTriSW")
    attn_factor_list <- c(0.1,0.26,0.64)/0.6
    if (length(xx) == 3) {xx <- xx[-1]}
  }
  else {
    dblist <- c("ffreqBi", "ffreqTri", "ffreqQuad")
    attn_factor_list <- c(0.1,0.26,0.64)/0.4
  }
  xx <- unk_rm(xx)
  prob_vect <- NULL
  
  # This function input a summed feature frequency vector and a string.
  # It outputs the next words following that string with the highest frequency.
  wordOut <- function(input, db) {
    results <- db[startsWith(names(db), sub("<.*", "", stri_paste(input, collapse = " ")))]
    names(results) <- stri_extract_last_words(names(results))
    return(results/sum(results))
  }
  
  #This function returns TRUE if an object of db starts with the concatenated input
  condition1 <- function(input) {
    input <- sub("<.*", "", stri_paste(input, collapse = " "))
    output <- startsWith(names(db), input)
    return(any(output))
  }
  
  #This function returns TRUE if an object of db ends with the concatenated input
  condition2 <- function(input, db) {
    input <- sub("^.*>", "", stri_paste(input, collapse = " "))
    output <- endsWith(names(db), input)
    return(any(output))
  }
  
  # Find all next words folowing string xx and their probability. 
  while (length(xx) > 0) {
    db <- get(dblist[length(xx)])
    attn_factor <- attn_factor_list[length(xx)]
    
    if (is.element("<UNK>",xx) && condition1(xx)) {
      
      if (length(xx) == 3 && xx[3] != "<UNK>") {
        results <- db[startsWith(names(db), sub("<.*", "", stri_paste(xx, collapse = " ")))]
        short_name <- results
        names(short_name) <- sub("\\s*\\w*$", "",names(results))
        
        if (condition2(xx, short_name)) {
          results <- results[endsWith(names(short_name), stri_paste(" ", xx[3]))]
          names(results) <- stri_extract_last_words(names(results))
          probOut <- results/sum(results)*attn_factor
        }
        else {
          probOut <- NULL
        }
      }
      else {
        probOut <- wordOut(xx, db)*attn_factor
      }
    }
    else if (!is.element("<UNK>",xx) && condition1(xx)) {
      probOut <- wordOut(xx, db)*attn_factor
    }
    else {
      probOut <- NULL
    }
    
    prob_vect <- c(prob_vect, probOut)
    xx <- xx[-1]
    xx <- unk_rm(xx)
  }
  return(prob_vect)
}

###Main function
predWordOut <- function(words) {
  
  empty <- c("","","","")
  probOut <- NULL
  probOutSW <- NULL
  if (words$id == 2) {
    if (length(unlist(words[2]) > 0)) {
      corr <- dict(unlist(words[2]))
      probOut <- prob_calc(corr)
    }
    if (length(unlist(words[3]) > 0)) {
      corrSW <- dict(unlist(words[3]))
      probOutSW <- prob_calc(corrSW, SW = TRUE)
    }
    
    prob_vect <- c(probOut, probOutSW)
    if (is.null(prob_vect)) {return(empty)}
    prob_vect <- rowsum(prob_vect, group = names(prob_vect))
    prob_vect_b <- as.vector(prob_vect[,1])
    names(prob_vect_b) <- rownames(prob_vect)
    prob_vect <- prob_vect_b[order(prob_vect_b, decreasing = TRUE)]
    
    return(names(prob_vect)[1:4])
  }
  else if (words$id == 1) {
    return(empty)
  }
  else {
    return(empty)
  }
}