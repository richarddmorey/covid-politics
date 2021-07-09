
# Attempt to replicate and extend:
# https://twitter.com/charles_gaba/status/1413499252177780737

library(dplyr)
library(magrittr)
library(lubridate)
library(ggplot2)
library(gganimate)
library(gifski)

# From https://www.ers.usda.gov/data-products/county-level-data-sets/download-data/
here::here("data/population/PopulationEstimates.xls") %>%
  readxl::read_xls(skip = 2) %>%
  filter(substr(FIPStxt, 4, 5) != "00") %>%
  rename(FIPS = FIPStxt) %>%
  select(FIPS, POP_ESTIMATE_2019) -> population

# From https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/VOQCHQ
here::here("data/elections/countypres_2000-2020.tab") %>%
  readr::read_delim(delim = "\t") %>%
  filter(
    !is.na(county_fips), 
    year == 2020,
    candidate %in% c("DONALD J TRUMP","JOSEPH R BIDEN JR")
    ) %>%
  group_by(county_fips, candidate) %>%
  summarise(
    candidatevotes = sum(candidatevotes)
  ) %>%
  mutate(totalvotes = sum(candidatevotes)) %>%
  filter(candidate == "DONALD J TRUMP") %>%
  mutate(trump_share = candidatevotes / totalvotes,
         FIPS = stringi::stri_pad_left(county_fips, width=5, pad = "0")) %>%
  ungroup() %>%
  select(FIPS, trump_share) -> election_data

# From https://www.ers.usda.gov/data-products/county-level-data-sets/download-data/
here::here("data/covid/COVID-19_Vaccinations_in_the_United_States_County.csv") %>%
  readr::read_csv() %>%
  filter(FIPS != "UNK") %>%
  left_join(election_data, by = "FIPS") %>%
  left_join(population, by = "FIPS") %>%
  mutate(
    Date = mdy(Date)
  ) -> vaccine_data

# Show missing data due to unknown vote share
vaccine_data %>%
  filter(Date == ymd("2021-07-08")) %>%
  mutate(
    trump_share_missing = is.na(trump_share)
  ) %>%
  group_by(trump_share_missing) %>%
  summarise(n = n()) %>%
  mutate(p = n / sum(n))

# Show missing data due to unknown county population
vaccine_data %>%
  filter(Date == ymd("2021-07-08")) %>%
  mutate(
    pop_missing = is.na(POP_ESTIMATE_2019)
  ) %>%
  group_by(pop_missing) %>%
  summarise(n = n()) %>%
  mutate(p = n / sum(n))

# Show unexplained 0 vaccination counts as of latest date
vaccine_data %>%
  filter(
    Date == ymd("2021-07-08"),
    Series_Complete_Yes == 0
  ) %>%
  select(trump_share, POP_ESTIMATE_2019, 
         Recip_County, Recip_State, FIPS,
         Series_Complete_Pop_Pct,
         Series_Complete_Yes)

# Remove those that are ALWAYS 0 for all days; assume 
# these are errors/missing (could be wrong!)
vaccine_data %<>%
  group_by(FIPS) %>%
  mutate(no_vaccinations = all(Series_Complete_Yes == 0)) %>%
  filter(!no_vaccinations)

## Animation 1
## Animated scatterplot
vaccine_data %>%
  ggplot(aes(x = trump_share*100, y = Series_Complete_Pop_Pct, 
             size = POP_ESTIMATE_2019,
             color = trump_share)) +
  scale_size_area(name = "Population (2019)") +
  scale_colour_viridis_c("Trump vote share (2020)") +
  scale_y_continuous(name = "Complete vaccination (%)",
                     limits = c(0,100), expand = c(0,0)) +
  scale_x_continuous(name = "Trump share of two-party vote (%)",
                     limits = c(0,100), expand = c(0,0)) +
  geom_point() +
  hrbrthemes::theme_ipsum_rc() -> static_plot

static_plot +
  transition_states(states = Date) + 
  ease_aes() +
  labs(title = 'Percentage vaccinated by 2020 Trump support, {closest_state}', 
       subtitle = "US Counties",
       caption = "Data Sources: CDC, Harvard Dataverse, USDA") -> anim_plot

ndays = vaccine_data %>% pull(Date) %>% range() %>% diff() %>% as.integer()

final_animation<-animate(anim_plot, 
                         nframes = 2*ndays,
                         fps = 16,
                         width = 950, 
                         height = 750, 
                         renderer = gifski_renderer())

anim_save(here::here("animation.gif"),
          animation=final_animation)


