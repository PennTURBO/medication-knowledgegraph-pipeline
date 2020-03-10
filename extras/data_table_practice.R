library(data.table)

data_sample <-
  fread("~/Downloads/developer_survey_2019/survey_results_public.csv",
        nrows = 10)

class(data_sample)
