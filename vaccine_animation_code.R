library(magick)
library(magrittr)

path1 <- "/Users/alexis_pro/Documents/GitHub/covid19_vaccination_africa/maps"

setwd(path1)

list.files(path=path1, pattern = '*.png', full.names = TRUE) %>% 
  image_read() %>% # reads each path file
  image_join() %>% # joins image
  image_animate(fps=1) %>% # animates, can opt for number of loops
  image_write("map_vaccination_progress.gif") # write to current dir



path2 <- "/Users/alexis_pro/Dropbox/WorldBank/AFRCE/coronavirus/alexis data and code/vaccines/barchart_vaccine_inequity"

setwd(path2)

list.files(path=path2, pattern = '*.png', full.names = TRUE) %>% 
  image_read() %>% # reads each path file
  image_join() %>% # joins image
  image_animate(fps=1) %>% # animates, can opt for number of loops
  image_write("vaccine_inequity.gif") # write to current dir