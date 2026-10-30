# ------------------------------------------------------------------------------
# Capacitor availability vs. AI data-center production (base R version)
# No packages needed: uses only R's built-in graphics.
#
# Run: source("murata_vs_nvidia_base.R")   # saves murata_vs_nvidia_base.png
# ------------------------------------------------------------------------------

# ---- Data (sources and notes as in murata_vs_nvidia.R) -----------------------
dat <- data.frame(
  quarter = c("Apr-Jun 2024", "Jul-Sep 2024", "Oct-Dec 2024", "Jan-Mar 2025",
              "Apr-Jun 2025", "Jul-Sep 2025", "Oct-Dec 2025", "Jan-Mar 2026",
              "Apr-Jun 2026"),
  murata_orders = c(213226, 204681, 207210, 207567, 223995, 241807, 268055,
                    329712, 415505),
  murata_sales  = c(203313, 213999, 213089, 201444, 217330, 237572, 239114,
                    242402, 282508),
  nvidia_dc_bn  = c(26.3, 30.7, 35.6, 39.3, 41.0, 51.1, 62.3, 75.4, 89.0)
)
dat$book_to_bill <- dat$murata_orders / dat$murata_sales
squeeze <- dat$book_to_bill > 1.1

# ---- Statistics --------------------------------------------------------------
pearson  <- cor(dat$nvidia_dc_bn, dat$book_to_bill)
spearman <- cor(dat$nvidia_dc_bn, dat$book_to_bill, method = "spearman")
fit      <- lm(book_to_bill ~ nvidia_dc_bn, data = dat)
cat("Pearson r:   ", round(pearson, 2), "\n")
cat("Spearman rho:", round(spearman, 2), "\n")
print(summary(fit))

# ---- Plot --------------------------------------------------------------------
make_plot <- function() {
  par(mar = c(6.5, 5, 5, 2))
  cols <- ifelse(squeeze, "#D95F0E", "#2C7FB8")

  plot(dat$nvidia_dc_bn, dat$book_to_bill, type = "n",
       xlim = c(22, 93), ylim = c(0.85, 1.55),
       xlab = "Nvidia data-center revenue in the overlapping quarter ($ billions)",
       ylab = "Murata capacitor book-to-bill (orders / shipments)",
       las = 1, bty = "l")
  grid(col = "grey90", lty = 1)

  # Regression line with 95% confidence band
  xs   <- seq(min(dat$nvidia_dc_bn), max(dat$nvidia_dc_bn), length.out = 100)
  pred <- predict(fit, newdata = data.frame(nvidia_dc_bn = xs), interval = "confidence")
  polygon(c(xs, rev(xs)), c(pred[, "lwr"], rev(pred[, "upr"])),
          col = "grey88", border = NA)
  lines(xs, pred[, "fit"], col = "grey35", lwd = 2)

  # Orders = shipments reference line
  abline(h = 1, lty = 2, col = "grey50")
  text(92, 0.985, "Orders = shipments", adj = c(1, 1), cex = 0.8, col = "grey40")

  # Points and labels (pos: 1 = below, 2 = left, 3 = above, 4 = right)
  points(dat$nvidia_dc_bn, dat$book_to_bill, pch = 19, cex = 1.6, col = cols)
  label_pos <- c(3, 1, 4, 2, 4, 1, 3, 3, 2)
  text(dat$nvidia_dc_bn, dat$book_to_bill, dat$quarter,
       pos = label_pos, offset = 0.7, cex = 0.75, col = "grey20")

  legend("topleft", legend = c("Balanced", "Squeeze (orders outrunning shipments)"),
         pch = 19, col = c("#2C7FB8", "#D95F0E"), bty = "n", cex = 0.85)

  title(main = "As AI server production grew, Murata's capacitor orders outran shipments",
        line = 3, cex.main = 1.15)
  mtext(sprintf("Apr 2024 - Jun 2026  |  Pearson r = %.2f, Spearman rho = %.2f, n = %d",
                pearson, spearman, nrow(dat)),
        side = 3, line = 1.6, cex = 0.8, col = "grey30")
  mtext(paste("Sources: Murata quarterly financial results (capacitor segment); NVIDIA quarterly results releases.",
              "Small sample, both series trending up: supporting evidence, not proof of causation.",
              sep = "\n"),
        side = 1, line = 5, adj = 0, cex = 0.65, col = "grey40")
}

make_plot()                                   # show in the Plots pane
png("murata_vs_nvidia_base.png", width = 3000, height = 1950, res = 300)
make_plot()                                   # save a high-resolution copy
dev.off()
