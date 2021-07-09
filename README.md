# covid-politics
Data analysis: Covid vaccination in US by Trump vote share

This is an attempt to replicate and extend the graph in this tweet:
https://twitter.com/charles_gaba/status/1413499252177780737

Code is written in R and uses `renv` to manage dependencies.

This is just a test of `gganimate` - I am less familiar with the intricacies of these data sets, so *caveat emptor*. This is just a toy analysis for me. Any hints where I went wrong interpreting the data/computing summaries would be appreciated. Issues include:

* Differences between states in reporting in the election data (how/whether a total is calculated)
* Some counties have 0 vaccination rates throughout
* "Unknown" counties in both data sets

If you don't want to muck about with github, just download the project from the green "Code" button above. Choose "Download ZIP".

To run:

1. Install the `renv` package.
2. Open the project in RStudio.
3. Run `renv::restore()` to install the dependencies.
4. Run the code in `analysis.R`.

You may need to install binaries for `ffmpeg` to generate the video file, if you don't already have it installed.
