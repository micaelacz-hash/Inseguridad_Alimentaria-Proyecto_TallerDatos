#==============================================================================
#Proyecto: Análisis usando datos de la ENAHO
#Autora: Micaela Cusipuma
#Objetivo de este script: Crear el sistema de carpetas y enlazar con GitHub
#==============================================================================

#Creamos carpetas-----------------------

dir.create("datos")
dir.create("datos/crudos")
dir.create("datos/procesados")
dir.create("outputs")
dir.create("docs")
dir.create("scripts")

#Enlace con Git y GutHub

install.packages("usethis")
usethis::use_git_config(
  user.name = "micaelacz",
  user.email = "micaela.cusipuma@pucp.edu.pe"
)
install.packages(c("stringi", "rlang", "glue", "gert", "usethis"), dependencies = TRUE)
usethis::create_github_token()
gitcreds::gitcreds_set()
usethis::use_git()
usethis::use_github() 
