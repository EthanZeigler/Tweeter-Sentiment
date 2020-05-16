from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
import pandas

df = pandas.read_csv("trump_tweets.csv", encoding="utf-8")

analyzer = SentimentIntensityAnalyzer()
df['sentiment'] = df['text'].apply(analyzer.polarity_scores)
df.to_csv("trump_tweets.csv")

# for sentence in sentences:
#     vs = analyzer.polarity_scores(sentence)
#     print("{:-<65} {}".format(sentence, str(vs)))

