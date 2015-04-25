using Gumbo
import Base.show

# Represents information about a Winograd Schema collected during parsing 
# Davis's html collection.
type WSParseInfo
  sentences
  questions
  answers
  next
  halt
  WSParseInfo() = new("", "", String[], false, false)
end

# Represents one half (one "arm") of a WS
type WSArm
  sentence
  question
  answers
  correctIndex
end

# Represents one WSArm
type WSPair
  arms
end

cleanup(s) = replace(replace(strip(s), "\n", " "), "  ", " ")

# functions to parse specific html tags
function process(elem::HTMLElement{:text}, pinfo::WSParseInfo)
  pinfo.sentences = cleanup(elem[1].text)
end
function process(elem::HTMLElement{:question}, pinfo::WSParseInfo)
  pinfo.questions = cleanup(elem[1].text)
end
function process(elem::HTMLElement{:answer}, pinfo::WSParseInfo)
  ans = cleanup(elem[2].text)
  push!(pinfo.answers, ans)
  if strip(elem[1][1].text)!="Answer Pair A:" # don't wait for 2nd answer
    pinfo.next = true
  end
end
function process(elem::HTMLElement{:h4}, pinfo::WSParseInfo)
  # hack to stop processing at the end of English examples
  if length(children(elem))>0 && cleanup(elem[1].text)=="French"
    pinfo.halt = true
  end
end
process(elem, pinfo) = Nothing # skip elements we don't care about

# make small repairs to string: ensure capitalization and remove trailing periods
function repair(s)
  if endswith(s, ".")
    s = s[1:end-1]
  end
  if islower(s[1])
    s = string(uppercase(s[1]), s[2:end])
  end
  s
end

# Given information about a WS pair in raw form (i.e. with both options
# smashed together in the sentence, question and answer), split them out
# into two completely distinct versions/arms of the WS and return them in
# a WSPair.
#
# So, for example, the sentence:
#   "The man lifted the boy onto his [bed/bunkbed]." 
# will be split into two:
#   "The man lifted the boy onto his bed." and
#   "The man lifted the boy onto his bunkbed."
function makeWSPair(pinfo)
  specialWordsPattern = r"\[([^/]*)/([^\]]*)\]" # capture x and y in "[x/y]"
  answerPattern = r"([^/]*)/(.*)" # capture x and y in "x/y"

  specialWords = match(specialWordsPattern, pinfo.sentences)
  assert(specialWords!=nothing)
  head = pinfo.sentences[1:specialWords.offset-1]
  tail = pinfo.sentences[specialWords.offset+length(specialWords.match):end]
  sentence1 = string(head, strip(specialWords.captures[1]), tail)
  sentence2 = string(head, strip(specialWords.captures[2]), tail)
  
  questionWords = match(specialWordsPattern, pinfo.questions)
  if questionWords == nothing # might have the same question for both
    question1 = question2 = pinfo.questions
  else
    head = pinfo.questions[1:questionWords.offset-1]
    tail = pinfo.questions[questionWords.offset+length(questionWords.match):end]
    question1 = string(head, strip(questionWords.captures[1]), tail)
    question2 = string(head, strip(questionWords.captures[2]), tail)
  end

  answerWords = match(answerPattern, pinfo.answers[1])
  assert(answerWords!=nothing)
  answer1right = repair(strip(answerWords.captures[1]))
  answer1wrong = repair(strip(answerWords.captures[2]))
  if length(pinfo.answers)>1
    answerWords = match(answerPattern, pinfo.answers[2])
    assert(answerWords!=nothing)
    answer2right = repair(strip(answerWords.captures[1]))
    answer2wrong = repair(strip(answerWords.captures[2]))
  else
    answer2right = answer1wrong
    answer2wrong = answer1right
  end

  alt1 = WSArm(sentence1, question1, [answer1right, answer1wrong], 1)
  alt2 = WSArm(sentence2, question2, [answer2right, answer2wrong], 1)
  WSPair([alt1, alt2])
end

# Parse WS file into internal datastructure
function readCorpus(filename)
  # slurp file into parse tree
  doc = open(filename) do file
    file |> readall |> parsehtml
  end

  # Traverse the tree, looking for special tags: <text>, <question>, and
  #  <answer>. Build up array of questions (WSPair objects) as we go.
  pinfo = WSParseInfo()
  corpus = WSPair[]
  for elem in preorder(doc.root)
    process(elem, pinfo)
    if pinfo.next
      push!(corpus, makeWSPair(pinfo))
      pinfo = WSParseInfo()
    end
    if pinfo.halt
      break
    end
  end
  corpus
end

function printWS(ws::WSArm)
  println(ws.sentence)
  println(ws.question)
  println(ws.answers[1])
  println(ws.answers[2])
  println(ws.correctIndex)
end

function printWSPair(wspair::WSPair)
  printWS(wspair.arms[1])
  printWS(wspair.arms[2])
end

# Print out the internal datastructure
function printCorpus(corpus)
  for (i,wspair) in enumerate(corpus)
    println(i)
    printWSPair(wspair)
    println()
  end
end

type WSQuestion
  index   # index of WSPair to use
  which   # which arm of that WSPair to use
end
show(io::IO, a::WSQuestion) = print(io, "WSQ($(a.index),$(a.which))")

# Generates a vector of sessions (vectors of WSQuestions), where each session
# specifies the questions (WSPairs) to ask during that session, including which
# arm of each question to use.
#
# Subject to these criteria:
#  - corpus passed as array of WSPairs (corpus)
#  - desired total # of trials per arm of each question (numtrials)
#  - desired # of questions per session (numquestions),
#
# and these constraints:
#  - no session can include both arms of a particular WSPair
#  - each session includes a (probabilistically) balanced number of each arm
#  - numtrials will be met, even if the final session is short
function genExperimentQuestions(corpus, numtrials, numquestions)
  numq = length(corpus)
  # create full set of WSQuestions
  all = WSQuestion[]
  for n in 1:numq
    for t in 1:numtrials
      push!(all, WSQuestion(n, 1)) # pairs must always be 2n and 2n+1
      push!(all, WSQuestion(n, 2))
    end
  end
  println(STDERR, "total number of questions is $(length(all))")
  # shuffle so we can just do a linear search from here on
  shuffle!(all)
  # create each session by selecting/removing from full set
  numsessions = int(ceil(length(all)/numquestions))
  println(STDERR, "creating $numsessions sessions")
  session = WSQuestion[]
  idxes = Int[]
  nottapped = [1:numq]
  i = 0
  sessions = Vector{WSQuestion}[]
  while i < numsessions
    if length(session)==numquestions || length(all)==0
      i += 1
      l = length(session)
      if l>5
        println(STDERR, "session #$i: [$l] $(session[1:5])..")
      else
        println(STDERR, "session #$i: [$l] $(session[1:min(5,end)])")
      end
      push!(sessions, session)
      if length(all)==0
        break
      else
        session = WSQuestion[]
        idxes = Int[]
        continue
      end
    else
      # find a choice that (1) isn't a question we've already chosen for this
      #  session, and (2) isn't a question that has been picked already without
      #  all other question indexes being picked at lesat once (if we didn't
      #  have this check, we could paint ourselves into a corner where we could
      #  be forced to choose two versions/arms of the same question in a given
      #  session.)
      pickidx = findfirst(q->!(q.index in idxes) && (q.index in nottapped), all)
      # remember this question's index, so we don't choose it again this session
      qindex = all[pickidx].index
      push!(idxes, qindex)
      # remember that this questions's index has been chosen
      splice!(nottapped, findfirst(nottapped, qindex))
      if length(nottapped)==0
        nottapped = [1:numq] # all have been chosen, so everyone's fair game
      end
      # save the actual question in this session array
      push!(session, splice!(all, pickidx))
    end
  end
  sessions
end

# correctness check for set of generated questions
function checkExperimentQuestions(corpus, numtrials, numquestions, sessions)
  uniquequestions = length(corpus)
  totalquestions = uniquequestions*numtrials*2
  numsessions = int(ceil(totalquestions/numquestions))
  n = 0
  counts = zeros(Int, uniquequestions*2)
  for (i,session) in enumerate(sessions)
    n += length(session)
    if i<numsessions && length(session)!=numquestions # correct session length?
      return false
    end
    last_counts = counts[:]
    for q in session
      counts[uniquequestions*(q.which-1) + q.index] += 1
    end
    deltas = counts-last_counts
    if any(deltas .> 1) # no repeat questions? (or two arms of same question)
      return false
    end
  end
  if n!=totalquestions # correct total number of questions?
    return false
  end
  all(counts .== numtrials) # correct total trials for each question?
end

# end of WSCorpus.jl
