library(quanteda)
library(readtext)
library(stringi)
library(ggplot2)
library(gridExtra)
set.seed(3245)

#This .R file creates a training and testing sets of data

#The Data can be downloaded from here: https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip
conBlog <- file("final/en_US.blogs.txt", "r")
blog <- readLines(conBlog, encoding = "UTF-8")
close(conBlog)
blog_sample <- as.logical(rbinom(length(blog), size=1, prob = 0.01))
blog_train <- blog[blog_sample]
blog_test <- blog[!blog_sample]
conBlog <- file("sample/en_US.blogs.training.txt", "w")
writeLines(blog_train, conBlog)
close(conBlog)
conBlog <- file("sample/en_US.blogs.testing.txt", "w")
writeLines(blog_test, conBlog)
close(conBlog)

conNews <- file("final/en_US.news.txt", "r")
news <- readLines(conNews, encoding = "UTF-8")
close(conNews)
news_sample <- as.logical(rbinom(length(news), size=1, prob = 0.01))
news_train <- news[news_sample]
news_test <- news[!news_sample]
conNews <- file("sample/en_US.news.training.txt", "w")
writeLines(news_train, conNews)
close(conNews)
conNews <- file("sample/en_US.news.testing.txt", "w")
writeLines(news_test, conNews)
close(conNews)

conTwit <- file("final/en_US.twitter.txt", "r")
twit <- readLines(conTwit, encoding = "UTF-8")
close(conTwit)
twit_sample <- as.logical(rbinom(length(twit), size=1, prob = 0.01))
twit_train <- twit[twit_sample]
twit_test <- twit[!twit_sample]
conTwit <- file("sample/en_US.twitter.training.txt", "w")
writeLines(twit_train, conTwit)
close(conTwit)
conTwit <- file("sample/en_US.twitter.testing.txt", "w")
writeLines(twit_test, conTwit)
close(conTwit)
