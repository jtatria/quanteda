# This function generates random texts from English alphabets or any other characters.

# @param n_doc the number of documents generated
# @param n_word the number of words in documents
# @param len_word the size of longest words
# @param n_type the number of tyeps of tokens appear in the documents
# @param fast if true, words are generated from uniform random distribution over characters to speed up
# @param code if true, the function return R code instead of vector
# @param seed a integer passed to set.seed() to generate replicable random texts 
# @param characters a vector of letters for random word generation
#
# texts_random(5, 20, seed=1234)
# texts_random(5, 20, seed=1234, code=TRUE)
# texts_random(5, 20, seed=1234, fast=TRUE)
# 
# texts_random(5, 10, seed=1234, characters = LETTERS)

texts_random <- function(n_doc=10, 
                         n_word=100, 
                         len_word=5, 
                         n_type=1000, 
                         fast=FALSE, 
                         code=FALSE,
                         seed, characters){
    
    if (!missing(seed)) set.seed(seed)
    if (missing(characters)){
        # Empirical distribution in English (https://en.wikipedia.org/wiki/Letter_frequency)
        chars <- letters
        prob_chars <-c(0.08167, 0.01492, 0.02782, 0.04253, 0.12702, 0.02228, 0.02015, 
                       0.06094, 0.06966, 0.00153, 0.00772, 0.04025, 0.02406, 0.06749,
                       0.07507, 0.01929, 0.00095, 0.05987, 0.06327, 0.09056, 0.02758, 
                       0.00978, 0.02360, 0.00150, 0.01974, 0.00074)
    } else {
        # Log-normal distribution
        chars <- characters
        dist_chars <- stats::rlnorm(length(chars))
        prob_chars <- sort(dist_chars / sum(dist_chars), decreasing = TRUE)
    }
    if (n_type > length(chars) ^ len_word) 
        stop('n_type is too large')
    
    # Generate unique types
    type <- c()
    if (fast) {
        pat <- stri_flatten(c('[', chars, ']'))
        while(n_type > length(type)){
            type <- unique(c(type, stri_rand_strings(n_type, 1:len_word, pat)))
        }
    } else {
        while(n_type > length(type)){
            type <- unique(c(type, word_random(chars, sample(len_word, 1), prob_chars)))
        }
    }
    type <- head(type, n_type)
    
    # Generate random text from the types
    texts <- c()
    prob_words <- zipf(n_type)
    texts <- replicate(n_doc, {
        words <- sample(type, size=n_word, replace = TRUE, prob=prob_words)
        stri_c(words, collapse = ' ')
    })
    if (code) {
        return(code(texts))
    } else {
        return(texts)
    }
}

word_random <- function(chars, len_word, prob){
    stri_flatten(sample(chars, len_word, replace = TRUE, prob = prob)) 
}

zipf <- function(n_type){
    (1 / 1:n_type) / n_type
}

code <- function(texts){
    len <- length(texts)
    cat(paste0('txt <- c("', texts[1], '",\n'))
    for (text in texts[2:(len-1)]) {
        cat(paste0('         "', text, '",\n'))
    }
    cat(paste0('         "', texts[len], '")\n'))
}

# rdname catm
# make temporary files and directories in a more reasonable way than tempfile()
# or tempdir(): here, the filename is different each time you call mktemp()
mktemp <- function(prefix='tmp.', base_path = NULL, directory = FALSE) {
    #  Create a randomly-named temporary file or directory, sort of like
    #  https://www.mktemp.org/manual.html
    if (is.null(base_path))
        base_path <- tempdir()
    
    alphanumeric <- c(0:9, LETTERS, letters)
    
    filename <- paste0(sample(alphanumeric, 10, replace=T), collapse='')
    filename <- paste0(prefix, filename)
    filename <- file.path(base_path, filename)
    while (file.exists(filename) || dir.exists(filename)) {
        filename <- paste0(sample(alphanumeric, 10, replace=T), collapse='')
        filename <- paste0(prefix, filename)
        filename <- file.path(base_path, filename)
    }
    
    if (directory) {
        dir.create(filename)
    }
    else {
        file.create(filename)
    }
    
    return(filename)
}

test_that("Test quanteda:::mktemp function for test dirs",{
    filename <- quanteda:::mktemp()
    expect_true(file.exists(filename))
    filename2 <- quanteda:::mktemp()
    expect_true(file.exists(filename2))
    expect_false(filename == filename2)
    
    # test directory parameter
    dirname <- quanteda:::mktemp(directory=T)
    expect_true(dir.exists(dirname))
    
    # test prefix parameter
    filename <- quanteda:::mktemp(prefix='testprefix')
    expect_equal(
        substr(basename(filename), 1, 10),
        'testprefix'
    )
    
    # test that a new filename will be given if the original already exists
    set.seed(0)
    original_filename <- quanteda:::mktemp()
    set.seed(0)
    new_filename <- quanteda:::mktemp()
    expect_false(original_filename == new_filename)
    expect_true(file.exists(original_filename))
    expect_true(file.exists(new_filename))
})


#' utility function to remove all attributes
#' @keywords internal
remove_attributes <- function(x) {
    base::attributes(x) <- NULL
    return(x)
}
