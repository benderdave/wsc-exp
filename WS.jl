module WS
  include("WSCorpus.jl")
  #include("WSResults.jl")
  include("WSSettings.jl")

  export readCorpus, printCorpus, printWS, printWSPair, genExperimentQuestions, checkExperimentQuestions, WSArm, WSPair, WSQuestion, expfilter, isnoambExpIdx, isnoambCorpusIdx, filterNoamb
  #export getExperimentResults, printSubjects, printOverview, TrialInfo, SubjectInfo, ExperimentInfo
  export ENCRYPT_DATA_DIR
end # of module WS
