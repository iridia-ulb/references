options(warn=2)
library(rbibutils)
# Try to read it with `readBib` to sanity check.
bibs <- readBib("articles.bib", direct=TRUE, macros=c("abbrev.bib", "authors.bib", "journals.bib"))

bibs <- readBib("biblio.bib", direct=TRUE, macros=c("abbrev.bib", "authors.bib", "crossref.bib"))

bibs <- sapply(bibs, function(x) {
  x <- unclass(x)[[1L]]
  list(key = attr(x, "key"), bibtype = attr(x, "bibtype"), crossref=x$crossref)
}, simplify=FALSE)

check_type <- function(x, cr_type, cr_typel, target, targetl) {
  if (cr_typel == targetl) return(NULL)
  paste0("Entry '", x$key, "' has type '", x$bibtype, "' but its crossref '", x$crossref, "' has type '", cr_type, "' instead of @", target, "!\n")
}

text <- readLines("biblio.bib")

errors <- c()
for (x in bibs) {
  if (is.null(x$crossref)) next
  type <- x$bibtype
  cr_bib <- bibs[[x$crossref]]
  if (is.null(cr_bib))
    stop("Crossef '", x$crossref, "' of '", x$key, "' cannot be found!")
  cr_type <- bibs[[x$crossref]]$bibtype
  typel <- tolower(type)
  cr_typel <- tolower(cr_type)
  if (typel == "inproceedings") {
    errors <- c(errors, check_type(x, cr_type, cr_typel, "Proceedings", "proceedings"))
    if (cr_typel == "book")
      text <- sub(paste0("@InProceedings{", x$key, ","), paste0("@InCollection{", x$key, ","), text, fixed=TRUE)

  } else if (typel == "incollection" || typel == "inbook") {
    errors <- c(errors, check_type(x, cr_type, cr_typel, "Book", "book"))
    if (cr_typel == "proceedings")
      text <- sub(paste0("@InCollection{", x$key, ","), paste0("@InProceedings{", x$key, ","), text, fixed=TRUE)
  } 
}
cat(paste0(collapse="", errors))
writeLines(text, "biblio.bib")
quit(status = length(errors) > 0)
