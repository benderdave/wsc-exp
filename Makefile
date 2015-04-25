.PHONY: corpuses
corpuses: corpus no-amb-corpus train-corpus

.PHONY: corpus
corpus:
	julia dump_corpus.jl corpus/test-corpus.html > corpus/test-corpus.txt

.PHONY: no-amb-corpus
no-amb-corpus:
	julia dump_corpus.jl corpus/no-amb-corpus.html > corpus/no-amb-corpus.txt

.PHONY: train-corpus
train-corpus:
	julia dump_corpus.jl corpus/train-corpus.html > corpus/train-corpus.txt

.PHONY: all-questions
all-questions: questions train-questions

.PHONY: questions
questions:
	julia make_questions.jl > ./experiment/static/js/questions.js

.PHONY: train-questions
train-questions:
	julia make_questions.jl corpus/train-corpus.html > ./experiment/static/js/train-questions.js
