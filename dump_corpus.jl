using WS

# "A Collection of Winograd Schemas.html" downloaded 2/10/2015
#
# issues with the file:
#
# -- #101,127,140 answers backwards; #93 Pair A reversed; should be "The duck/the shark."
# -- #110 second pair of answers don't really answer the question.
# -- #126 Billy not Bill
# -- #26 answers are specific to form, so need dual answer pairs, like 
#     #93/142
#     <br><answer><b>Answer Pair A:</b>
#     Sid did not convince Mark/Mark did not convince Sid.</answer>
#     <br><answer><b>Answer Pair B:</b>
#     Mark did not understand Sid/Sid did not understand Mark.</answer>
#
# -- #135 - right curly brace instead of right bracket
#    .. Who [was / was not} eager to see the play? ..
# -- #40 missing [] in text; #48 and #63 [] missing in question
# -- #9, #55, and #58 missing periods in text
# -- #87 duplicate '/' i.e. [on//off]
# -- #141 "Answer" should be "Answers"
#
# -- #123 - actual text of question comes outside of <question> tag
#    <question> 
#    </question>Whose turn was [over/next]?<br>
# -- #135 </answer> and </question> end-tags misplaced (they come too late)
# -- #5 period appears on the outside of <text> tag
# -- #51 missing <answer> tag
# 
# -- #135 split into two cases
# -- #113 multiple [] combined into one in the text
#
# -- #35 'subway' is the rail system, not the train
# -- #68 suggest breeze instead of wind
# -- #64 suggest memorized so that it's clear she hasn't had the sheet music
# -- French example should be separate
#

if length(ARGS) > 0
  corpusFile = ARGS[1]
else
  corpusFile = "corpus/corpus.html"
end
corpus = readCorpus(corpusFile)
printCorpus(corpus)
