# ============================================================
# Plots und Kennwerte
# ============================================================

dgm_orange <- "#F47920"
dgm_dark   <- "#2B2B2B"
dgm_grey   <- "#6B6B6B"

monitor_theme <- function() {
  ggplot2::theme_minimal(base_size = 15) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      axis.title = ggplot2::element_text(colour = dgm_dark),
      axis.text  = ggplot2::element_text(colour = dgm_grey),
      plot.caption = ggplot2::element_text(colour = dgm_grey, hjust = 0)
    )
}

# ---- Formatierung ----
fmt_num <- function(x, digits = 2) formatC(x, format = "f", digits = digits)
fmt_r   <- function(x) sub("^(-?)0\\.", "\\1.", fmt_num(x, 2))
fmt_p   <- function(p) if (is.na(p)) "p = n/a" else if (p < .001) "p < .001" else paste("p =", sub("^0\\.", ".", fmt_num(p, 3)))

ci_mean <- function(x) {
  n <- length(x)
  m <- mean(x)
  half <- if (n > 1) stats::qt(.975, n - 1) * stats::sd(x) / sqrt(n) else NA
  data.frame(n = n, mean = m, sd = if (n > 1) stats::sd(x) else NA,
             lower = m - half, upper = m + half)
}

# ------------------------------------------------------------
# Univariat
# ------------------------------------------------------------

uni_plot <- function(data, var, label, type) {
  d <- data[!is.na(data[[var]]), , drop = FALSE]
  if (type == "numeric") {
    x <- d[[var]]
    bins <- max(5, min(30, ceiling(sqrt(length(x)) * 2)))
    ggplot2::ggplot(d, ggplot2::aes(x = .data[[var]])) +
      ggplot2::geom_histogram(bins = bins, fill = dgm_orange, colour = "white") +
      ggplot2::geom_vline(xintercept = mean(x), colour = dgm_dark, linewidth = 1,
                          linetype = "dashed") +
      ggplot2::labs(x = label, y = "Count",
                    caption = "Dashed line: mean") +
      monitor_theme()
  } else {
    ggplot2::ggplot(d, ggplot2::aes(x = .data[[var]])) +
      ggplot2::geom_bar(fill = dgm_orange, width = 0.7) +
      ggplot2::geom_text(stat = "count", ggplot2::aes(label = ggplot2::after_stat(count)),
                         vjust = -0.5, colour = dgm_dark, size = 5) +
      ggplot2::scale_x_discrete(drop = FALSE) +
      ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, 0.12))) +
      ggplot2::labs(x = label, y = "Count") +
      monitor_theme()
  }
}

uni_stats <- function(data, var, type) {
  x <- data[[var]]
  x <- x[!is.na(x)]
  if (type == "numeric") {
    if (length(x) == 0) return(NULL)
    data.frame(N = length(x), Mean = fmt_num(mean(x)),
               SD = if (length(x) > 1) fmt_num(stats::sd(x)) else "–",
               Median = fmt_num(stats::median(x)), Min = fmt_num(min(x)),
               Max = fmt_num(max(x)), check.names = FALSE)
  } else {
    counts <- table(x)
    data.frame(Category = names(counts), N = as.integer(counts),
               Percent = if (length(x) > 0) paste0(fmt_num(100 * as.numeric(counts) / length(x), 1), " %") else "–",
               check.names = FALSE)
  }
}

# ------------------------------------------------------------
# Bivariat
# ------------------------------------------------------------
# metrisch × metrisch     -> Streudiagramm, Pearson r
# kategorial × metrisch   -> Mittelwerte mit 95 %-KI und Datenpunkten,
#                            t-Test (2 Gruppen) bzw. einfaktorielle ANOVA
# kategorial × kategorial -> Kreuztabelle, Chi-Quadrat-Test, Cramérs V

bi_kind <- function(type_x, type_y) {
  if (type_x == "numeric" && type_y == "numeric") "scatter"
  else if (type_x == "categorical" && type_y == "categorical") "crosstab"
  else "errorbar"
}

bi_data <- function(data, x, y) {
  d <- data[!is.na(data[[x]]) & !is.na(data[[y]]), c(x, y), drop = FALSE]
  for (v in c(x, y)) if (is.factor(d[[v]])) d[[v]] <- droplevels(d[[v]])
  d
}

scatter_plot <- function(d, x, y, xlab, ylab) {
  p <- ggplot2::ggplot(d, ggplot2::aes(x = .data[[x]], y = .data[[y]])) +
    ggplot2::geom_point(colour = dgm_orange, size = 3, alpha = 0.75)
  if (nrow(d) >= 3) {
    p <- p + ggplot2::geom_smooth(method = "lm", formula = y ~ x, colour = dgm_dark,
                                  fill = "grey80", linewidth = 1)
  }
  p + ggplot2::labs(x = xlab, y = ylab, caption = "Line: linear regression with 95% confidence band") +
    monitor_theme()
}

# group = kategoriale, value = metrische Variable
errorbar_plot <- function(d, group, value, glab, vlab) {
  summary <- do.call(rbind, lapply(split(d[[value]], d[[group]]), ci_mean))
  summary[[group]] <- factor(rownames(summary), levels = levels(d[[group]]))
  set.seed(1)
  ggplot2::ggplot(d, ggplot2::aes(x = .data[[group]], y = .data[[value]])) +
    ggplot2::geom_jitter(width = 0.12, height = 0, colour = dgm_orange, alpha = 0.45, size = 2.4) +
    ggplot2::geom_errorbar(data = summary,
                           ggplot2::aes(x = .data[[group]], ymin = lower, ymax = upper),
                           inherit.aes = FALSE, width = 0.18, linewidth = 1, colour = dgm_dark,
                           na.rm = TRUE) +
    ggplot2::geom_point(data = summary, ggplot2::aes(x = .data[[group]], y = mean),
                        inherit.aes = FALSE, size = 4.5, shape = 21, fill = dgm_orange,
                        colour = dgm_dark, stroke = 1.2) +
    ggplot2::labs(x = glab, y = vlab,
                  caption = "Large points: means with 95% confidence intervals; small points: individual sessions") +
    monitor_theme()
}

# Gruppenkennwerte unter dem Error-Bar-Plot
group_table <- function(d, group, value) {
  s <- do.call(rbind, lapply(split(d[[value]], d[[group]]), ci_mean))
  data.frame(Group = rownames(s), N = s$n, Mean = fmt_num(s$mean),
             SD = ifelse(is.na(s$sd), "–", fmt_num(s$sd)),
             `95% CI` = ifelse(is.na(s$lower), "–",
                               paste0("[", fmt_num(s$lower), ", ", fmt_num(s$upper), "]")),
             check.names = FALSE)
}

# Kreuztabelle: Anzahl und Zeilenprozent, mit Randsummen
crosstab_table <- function(d, x, y, xlab) {
  tab <- table(d[[x]], d[[y]])
  rows <- as.integer(rowSums(tab))
  cells <- matrix(paste0(tab, " (", fmt_num(100 * tab / ifelse(rows == 0, 1, rows), 0), " %)"),
                  nrow = nrow(tab))
  out <- data.frame(rownames(tab), cells, rows, check.names = FALSE, stringsAsFactors = FALSE)
  names(out) <- c(xlab, colnames(tab), "Total")
  rbind(out, setNames(data.frame("Total", t(as.integer(colSums(tab))), sum(tab),
                                 check.names = FALSE), names(out)))
}

# Kennwerte als ein Satz im APA-Stil
bi_test <- function(d, x, y, kind) {
  n <- nrow(d)
  if (kind == "scatter") {
    if (n < 4) return(paste0("Too few complete pairs for a correlation (n = ", n, ")."))
    ct <- stats::cor.test(d[[x]], d[[y]])
    return(sprintf("Pearson r(%d) = %s, 95%% CI [%s, %s], %s, n = %d.",
                   as.integer(ct$parameter), fmt_r(ct$estimate), fmt_r(ct$conf.int[1]),
                   fmt_r(ct$conf.int[2]), fmt_p(ct$p.value), n))
  }
  if (kind == "crosstab") {
    tab <- table(d[[x]], d[[y]])
    if (nrow(tab) < 2 || ncol(tab) < 2) return("At least two categories per variable are needed for a chi-square test.")
    ct <- suppressWarnings(stats::chisq.test(tab, correct = FALSE))
    v <- sqrt(unname(ct$statistic) / (sum(tab) * (min(dim(tab)) - 1)))
    note <- if (any(ct$expected < 5)) " Some expected counts are below 5; interpret with caution." else ""
    return(sprintf("χ²(%d) = %s, %s, Cramér's V = %s, n = %d.%s",
                   as.integer(ct$parameter), fmt_num(ct$statistic), fmt_p(ct$p.value),
                   fmt_r(v), sum(tab), note))
  }
  # errorbar: x ist die kategoriale, y die metrische Variable
  g <- d[[x]]
  sizes <- table(g)
  if (sum(sizes >= 2) < 2) return("At least two groups with two or more sessions are needed for a group comparison.")
  keep <- g %in% names(sizes)[sizes >= 2]
  g <- droplevels(g[keep]); v <- d[[y]][keep]
  if (nlevels(g) == 2) {
    tt <- stats::t.test(v ~ g)
    m <- tapply(v, g, mean); s <- tapply(v, g, stats::sd); k <- tapply(v, g, length)
    sp <- sqrt(((k[1] - 1) * s[1]^2 + (k[2] - 1) * s[2]^2) / (sum(k) - 2))
    return(sprintf("Welch t-test (%s vs. %s): t(%s) = %s, %s, Cohen's d = %s, n = %d.",
                   levels(g)[1], levels(g)[2], fmt_num(tt$parameter, 1), fmt_num(tt$statistic),
                   fmt_p(tt$p.value), fmt_num(unname((m[1] - m[2]) / sp)), length(v)))
  }
  fit <- stats::aov(v ~ g)
  tab <- summary(fit)[[1]]
  eta2 <- tab[1, "Sum Sq"] / sum(tab[, "Sum Sq"])
  sprintf("One-way ANOVA: F(%d, %d) = %s, %s, η² = %s, n = %d.",
          as.integer(tab[1, "Df"]), as.integer(tab[2, "Df"]), fmt_num(tab[1, "F value"]),
          fmt_p(tab[1, "Pr(>F)"]), fmt_r(eta2), length(v))
}
