# make gh3 combined lookup

gh3_20k_pop <- readRDS('/Users/RASV5G/Downloads/schwartz_exposure_assessment-master/us_geohash_20k_pop.rds')

gh3_20k_pop <- tibble(gh3_combined = gh3_20k_pop)

geohash_20k_pop <- gh3_20k_pop %>%
  mutate(gh3 = gh3_combined) %>%
  separate(gh3, into = paste0('gh3_', 1:9), sep = '-') %>%
  pivot_longer(cols = paste0('gh3_', 1:9), names_to = 'gh_n', values_to = 'gh3') %>%
  filter(!is.na(gh3)) %>%
  select(-gh_n)

saveRDS(geohash_20k_pop, 'gh3_combined_lookup.rds')
