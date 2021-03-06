source("incl/start.R")

strategies <- future:::supportedStrategies()
strategies <- setdiff(strategies, "multiprocess")

message("*** doFuture - nested %dopar% ...")

registerDoFuture()

message("*** doFuture - nested %dopar%  and tricky globals ...")

## This works ...
x <- foreach(j = 1) %dopar% { j }
str(x)
rm(list = "x")

## ... but this would give a "globals-not-found" error in
## doFuture (<= 0.4.0) because 'j' was interpreted as global variable
x <- foreach(i = 1, .packages = "foreach") %dopar% {
  foreach(j = 1) %dopar% { j }
}
str(x)
rm(list = "x")

message("*** doFuture - nested %dopar%  and tricky globals ... DONE")


for (strategy1 in strategies) {
  for (strategy2 in strategies) {
    message(sprintf("- plan(list('%s', '%s')) ...", strategy1, strategy2))
    plan(list(a = strategy1, b = strategy2))
    nested <- plan("list")

    as <- 1:2
    bs <- 3:1

    stopifnot(!exists("a", inherits = FALSE), !exists("b", inherits = FALSE))

    message("foreach() - level 1 ...")
    x <- foreach(a = as, .export = c("bs", "strategy2"),
                 .packages = "foreach") %dopar% {
      plan <- future::plan()
      stopifnot(inherits(plan, strategy2))
      plan_a <- future::plan("list")
      str(plan_a)
      stopifnot(inherits(plan_a[[1]], strategy2))

      message("foreach() - level 2 ...")
      y <- foreach(b = bs, .export = c("a", "plan_a")) %dopar% {
        plan <- future::plan()
        message(capture.output(print(plan)))
        stopifnot(
          inherits(plan, "future"),
          inherits(plan, getOption("future.default", "sequential"))
        )

        plan_b <- future::plan("list")
        str(plan_b)
        stopifnot(
          inherits(plan_b[[1]], "future"),
          inherits(plan_b[[1]], getOption("future.default", "sequential"))
        )

        list(a = a, plan_a = plan_a,
             b = b, plan_b = plan_b)
      }
      message("foreach() - level 2 ... DONE")

      y
    }
    message("foreach() - level 1 ... DONE")

    local({
      stopifnot(length(x) == length(as))
      for (aa in seq_along(as)) {
        x_aa <- x[[aa]]
        stopifnot(length(x_aa) == length(bs))
        a <- as[aa]
        for (bb in seq_along(bs)) {
          x_aa_bb <- x_aa[[bb]]
          b <- bs[bb]
          stopifnot(
            length(x_aa_bb) == 4L,
            all(names(x_aa_bb) == c("a", "plan_a", "b", "plan_b")),
            x_aa_bb$a == a,
            x_aa_bb$b == b,
            inherits(x_aa_bb$plan_a[[1]], strategy2),
            inherits(x_aa_bb$plan_b[[1]], "future"),
            inherits(x_aa_bb$plan_b[[1]],
                     getOption("future.default", "sequential"))
          )
        }
      }
    })

    ## Cleanup in order make sure none of these variables exist as
    ## proxies for missing globals of the name names
    rm(list = c("as", "bs", "x"))
    message(sprintf("- plan(list('%s', '%s')) ... DONE", strategy1, strategy2))
  }
}

message("*** doFuture - nested %dopar% ... DONE")

source("incl/end.R")
