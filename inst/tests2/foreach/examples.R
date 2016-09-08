findRdTopics <- function(package) {
  path <- find.package(package)
  file <- file.path(path, "help", "aliases.rds")
  topics <- readRDS(file)
  unique(topics)
} ## findRdTopics()


## Package for which examples should be run
pkg <- "foreach"

message(sprintf("*** doFuture() - all %s examples ...", pkg))

library("future")
options(warnPartialMatchArgs=FALSE)
oopts <- options(mc.cores=2L, warn=1L, digits=3L)
strategies <- future:::supportedStrategies()
strategies <- setdiff(strategies, "multiprocess")
if (require("future.BatchJobs")) strategies <- c(strategies, "batchjobs")
strategies <- getOption("doFuture.tests.strategies", strategies)

library("doFuture")
registerDoFuture()
library(pkg, character.only=TRUE)
topics <- getOption("doFuture.tests.topics", findRdTopics(pkg))

## Some examples may give errors when used with futures
excl <- getOption("doFuture.tests.topics.ignore", NULL)
topics <- setdiff(topics, excl)

for (strategy in strategies) {
  message(sprintf("- plan('%s') ...", strategy))
  plan(strategy)
  registerDoFuture()

  for (ii in seq_along(topics)) {
    topic <- topics[ii]
    message(sprintf("- #%d of %d example(%s, package='%s') using plan(%s) ...", ii, length(topics), topic, pkg, strategy))

    ovars <- ls(all.names=TRUE)
    example(topic, package=pkg, character.only=TRUE, ask=FALSE)
    graphics.off()
    rm(list=setdiff(ls(all.names=TRUE), c(ovars, "ovars")))

    message(sprintf("- #%d of %d example(%s, package='%s') using plan(%s) ... DONE", ii, length(topics), topic, pkg, strategy))
  } ## for (ii ...)

  message(sprintf("- plan('%s') ... DONE", strategy))
} ## for (strategy ...)

message(sprintf("*** doFuture() - all %s examples ... DONE", pkg))

options(oopts)